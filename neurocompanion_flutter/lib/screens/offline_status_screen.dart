import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/services/connectivity_service.dart';
import 'package:neurocompanion_flutter/services/sync_service.dart';
import 'package:neurocompanion_flutter/services/database_service.dart';

class OfflineStatusScreen extends StatefulWidget {
  const OfflineStatusScreen({super.key});

  @override
  State<OfflineStatusScreen> createState() => _OfflineStatusScreenState();
}

class _OfflineStatusScreenState extends State<OfflineStatusScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final ConnectivityService _connectivityService = ConnectivityService();
  final SyncService _syncService = SyncService();
  final DatabaseService _databaseService = DatabaseService();

  Map<String, int> _dbStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    _loadStats();
    _connectivityService.addListener(_onConnectivityChanged);
    _syncService.addListener(_onSyncStatusChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _connectivityService.removeListener(_onConnectivityChanged);
    _syncService.removeListener(_onSyncStatusChanged);
    super.dispose();
  }

  void _onConnectivityChanged() {
    setState(() {});
  }

  void _onSyncStatusChanged() {
    setState(() {});
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await _databaseService.getDatabaseStats();
    setState(() {
      _dbStats = stats;
      _isLoading = false;
    });
  }

  Future<void> _manualSync() async {
    await _syncService.syncAll();
    await _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.card,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Offline & Sync',
          style: TextStyle(color: theme.text),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primary))
          : FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: _loadStats,
                color: theme.primary,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildConnectionStatus(theme),
                    const SizedBox(height: 16),
                    _buildSyncStatus(theme),
                    const SizedBox(height: 16),
                    _buildOfflineData(theme),
                    const SizedBox(height: 16),
                    _buildSyncSettings(theme),
                    const SizedBox(height: 16),
                    _buildDatabaseStats(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildConnectionStatus(AppTheme theme) {
    final isOnline = _connectivityService.isOnline;
    final statusText = isOnline ? 'Online' : 'Offline';
    final statusIcon = isOnline ? Icons.cloud_done : Icons.cloud_off;
    final statusColor = isOnline ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connection Status',
                  style: TextStyle(
                    color: theme.text.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isOnline) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Changes will sync when online',
                    style: TextStyle(
                      color: theme.text.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatus(AppTheme theme) {
    final syncStatus = _syncService.status;
    final isSyncing = syncStatus == SyncStatus.syncing;
    final lastSync = _syncService.lastSyncTime;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sync Status',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isSyncing)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.primary,
                  ),
                )
              else
                Icon(
                  _getSyncStatusIcon(syncStatus),
                  color: _getSyncStatusColor(syncStatus),
                  size: 24,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isSyncing) ...[
            LinearProgressIndicator(
              value: _syncService.itemsToSync > 0
                  ? _syncService.itemsSynced / _syncService.itemsToSync
                  : 0,
              backgroundColor: theme.primary.withOpacity(0.1),
              color: theme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'Syncing ${_syncService.itemsSynced}/${_syncService.itemsToSync} items',
              style: TextStyle(
                color: theme.text.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ] else ...[
            Text(
              lastSync != null
                  ? 'Last synced: ${_formatDateTime(lastSync)}'
                  : 'Never synced',
              style: TextStyle(
                color: theme.text.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            if (_syncService.syncError != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: ${_syncService.syncError}',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _connectivityService.isOnline && !isSyncing
                  ? _manualSync
                  : null,
              icon: Icon(
                Icons.sync,
                color: _connectivityService.isOnline && !isSyncing
                    ? Colors.white
                    : theme.text.withOpacity(0.3),
              ),
              label: Text(
                'Sync Now',
                style: TextStyle(
                  color: _connectivityService.isOnline && !isSyncing
                      ? Colors.white
                      : theme.text.withOpacity(0.3),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                disabledBackgroundColor: theme.text.withOpacity(0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineData(AppTheme theme) {
    final unsyncedCount = _dbStats['syncQueue'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Offline Data',
            style: TextStyle(
              color: theme.text,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDataRow(theme, Icons.task_alt, 'Tasks', _dbStats['tasks'] ?? 0),
          const SizedBox(height: 12),
          _buildDataRow(theme, Icons.book, 'Journal Entries', _dbStats['journals'] ?? 0),
          const SizedBox(height: 12),
          _buildDataRow(theme, Icons.pending, 'Unsynced Items', unsyncedCount,
              highlight: unsyncedCount > 0),
        ],
      ),
    );
  }

  Widget _buildDataRow(AppTheme theme, IconData icon, String label, int count,
      {bool highlight = false}) {
    return Row(
      children: [
        Icon(
          icon,
          color: highlight ? Colors.orange : theme.primary.withOpacity(0.7),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: theme.text.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: highlight
                ? Colors.orange.withOpacity(0.1)
                : theme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: highlight ? Colors.orange : theme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncSettings(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sync Settings',
            style: TextStyle(
              color: theme.text,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _syncService.autoSyncEnabled,
            onChanged: (value) {
              _syncService.setAutoSync(value);
            },
            title: Text(
              'Auto-Sync',
              style: TextStyle(color: theme.text),
            ),
            subtitle: Text(
              'Automatically sync when online',
              style: TextStyle(color: theme.text.withOpacity(0.6), fontSize: 12),
            ),
            activeColor: theme.primary,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseStats(AppTheme theme) {
    final totalItems = (_dbStats['tasks'] ?? 0) +
        (_dbStats['journals'] ?? 0) +
        (_dbStats['cache'] ?? 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Database Stats',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$totalItems items',
                style: TextStyle(
                  color: theme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Cached data enables offline access to your information',
            style: TextStyle(
              color: theme.text.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSyncStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.success:
        return Icons.check_circle;
      case SyncStatus.error:
        return Icons.error;
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.idle:
        return Icons.sync_disabled;
    }
  }

  Color _getSyncStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.success:
        return Colors.green;
      case SyncStatus.error:
        return Colors.red;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.idle:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
