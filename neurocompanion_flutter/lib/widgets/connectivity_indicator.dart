import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/services/connectivity_service.dart';
import 'package:neurocompanion_flutter/services/sync_service.dart';

class ConnectivityIndicator extends StatefulWidget {
  const ConnectivityIndicator({super.key});

  @override
  State<ConnectivityIndicator> createState() => _ConnectivityIndicatorState();
}

class _ConnectivityIndicatorState extends State<ConnectivityIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  final ConnectivityService _connectivityService = ConnectivityService();
  final SyncService _syncService = SyncService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _connectivityService.addListener(_onStatusChanged);
    _syncService.addListener(_onStatusChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _connectivityService.removeListener(_onStatusChanged);
    _syncService.removeListener(_onStatusChanged);
    super.dispose();
  }

  void _onStatusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = _connectivityService.isOnline;
    final isSyncing = _syncService.status == SyncStatus.syncing;

    if (isOnline && !isSyncing) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _getBackgroundColor(isOnline, isSyncing).withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _getBackgroundColor(isOnline, isSyncing).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSyncing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                    value: _syncService.itemsToSync > 0
                        ? _syncService.itemsSynced / _syncService.itemsToSync
                        : null,
                  ),
                )
              else
                Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Icon(
                    isOnline ? Icons.cloud_done : Icons.cloud_off,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                _getStatusText(isOnline, isSyncing),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(bool isOnline, bool isSyncing) {
    if (isSyncing) return Colors.blue;
    if (!isOnline) return Colors.orange;
    return Colors.green;
  }

  String _getStatusText(bool isOnline, bool isSyncing) {
    if (isSyncing) {
      return 'Syncing ${_syncService.itemsSynced}/${_syncService.itemsToSync}';
    }
    if (!isOnline) {
      return 'Offline Mode';
    }
    return 'Online';
  }
}

class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, child) {
        if (connectivity.isOnline) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.orange,
          child: Row(
            children: [
              const Icon(Icons.cloud_off, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'You\'re offline. Changes will sync when reconnected.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
              Consumer<SyncService>(
                builder: (context, sync, child) {
                  final unsyncedCount = sync.itemsToSync;
                  if (unsyncedCount > 0) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$unsyncedCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
