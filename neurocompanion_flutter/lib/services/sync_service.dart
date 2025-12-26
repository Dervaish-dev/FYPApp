import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:neurocompanion_flutter/services/connectivity_service.dart';
import 'package:neurocompanion_flutter/services/database_service.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ConnectivityService _connectivityService = ConnectivityService();
  final DatabaseService _databaseService = DatabaseService();

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  String? _syncError;
  String? get syncError => _syncError;

  int _itemsSynced = 0;
  int get itemsSynced => _itemsSynced;

  int _itemsToSync = 0;
  int get itemsToSync => _itemsToSync;

  bool _autoSyncEnabled = true;
  bool get autoSyncEnabled => _autoSyncEnabled;

  Timer? _autoSyncTimer;
  StreamSubscription? _connectivitySubscription;

  Future<void> initialize() async {
    // Listen to connectivity changes
    _connectivityService.addListener(_onConnectivityChanged);

    // Start auto-sync timer if enabled
    if (_autoSyncEnabled) {
      _startAutoSync();
    }
  }

  void _onConnectivityChanged() {
    if (_connectivityService.isOnline && _autoSyncEnabled) {
      // Sync when coming back online
      syncAll();
    }
  }

  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_connectivityService.isOnline) {
        syncAll();
      }
    });
  }

  void setAutoSync(bool enabled) {
    _autoSyncEnabled = enabled;
    if (enabled) {
      _startAutoSync();
    } else {
      _autoSyncTimer?.cancel();
    }
    notifyListeners();
  }

  Future<void> syncAll() async {
    if (!_connectivityService.isOnline) {
      debugPrint('Cannot sync: Device is offline');
      return;
    }

    if (_status == SyncStatus.syncing) {
      debugPrint('Sync already in progress');
      return;
    }

    _updateStatus(SyncStatus.syncing);
    _syncError = null;
    _itemsSynced = 0;

    try {
      // Get all unsynced items
      final unsyncedTasks = await _databaseService.getUnsyncedTasks();
      final unsyncedJournals = await _databaseService.getUnsyncedJournalEntries();
      final syncQueue = await _databaseService.getSyncQueue();

      _itemsToSync = unsyncedTasks.length + unsyncedJournals.length + syncQueue.length;

      if (_itemsToSync == 0) {
        debugPrint('Nothing to sync');
        _updateStatus(SyncStatus.success);
        _lastSyncTime = DateTime.now();
        return;
      }

      debugPrint('Syncing $_itemsToSync items');

      // Process sync queue first (operations that were queued offline)
      await _processSyncQueue(syncQueue);

      // Sync unsynced tasks
      await _syncTasks(unsyncedTasks);

      // Sync unsynced journal entries
      await _syncJournalEntries(unsyncedJournals);

      _updateStatus(SyncStatus.success);
      _lastSyncTime = DateTime.now();
      debugPrint('Sync completed successfully');
    } catch (e) {
      _syncError = e.toString();
      _updateStatus(SyncStatus.error);
      debugPrint('Sync error: $e');
    }
  }

  Future<void> _processSyncQueue(List<Map<String, dynamic>> queue) async {
    for (final item in queue) {
      try {
        final operation = item['operation'] as String;
        final entityType = item['entityType'] as String;
        final entityId = item['entityId'] as String;
        final data = jsonDecode(item['data'] as String) as Map<String, dynamic>;

        bool success = false;

        switch (entityType) {
          case 'task':
            success = await _syncTask(operation, entityId, data);
            break;
          case 'journal':
            success = await _syncJournalEntry(operation, entityId, data);
            break;
        }

        if (success) {
          await _databaseService.removeSyncQueueItem(item['id'] as int);
          _itemsSynced++;
          notifyListeners();
        } else {
          await _databaseService.incrementSyncRetryCount(
            item['id'] as int,
            'Sync failed',
          );
        }
      } catch (e) {
        debugPrint('Error processing sync queue item: $e');
        await _databaseService.incrementSyncRetryCount(
          item['id'] as int,
          e.toString(),
        );
      }
    }
  }

  Future<void> _syncTasks(List<Map<String, dynamic>> tasks) async {
    for (final task in tasks) {
      try {
        final taskId = task['id'] as String;
        // Here you would call your actual API
        // For now, just mark as synced
        await _databaseService.markTaskSynced(taskId);
        _itemsSynced++;
        notifyListeners();
      } catch (e) {
        debugPrint('Error syncing task ${task['id']}: $e');
      }
    }
  }

  Future<void> _syncJournalEntries(List<Map<String, dynamic>> entries) async {
    for (final entry in entries) {
      try {
        final entryId = entry['id'] as String;
        // Here you would call your actual API
        // For now, just mark as synced
        await _databaseService.markJournalEntrySynced(entryId);
        _itemsSynced++;
        notifyListeners();
      } catch (e) {
        debugPrint('Error syncing journal entry ${entry['id']}: $e');
      }
    }
  }

  Future<bool> _syncTask(String operation, String id, Map<String, dynamic> data) async {
    try {
      switch (operation) {
        case 'create':
          // await _apiClient.createTask(data);
          break;
        case 'update':
          // await _apiClient.updateTask(id, data);
          break;
        case 'delete':
          // await _apiClient.deleteTask(id);
          break;
      }
      return true;
    } catch (e) {
      debugPrint('Error syncing task: $e');
      return false;
    }
  }

  Future<bool> _syncJournalEntry(String operation, String id, Map<String, dynamic> data) async {
    try {
      switch (operation) {
        case 'create':
          // await _apiClient.createJournalEntry(data);
          break;
        case 'update':
          // await _apiClient.updateJournalEntry(id, data);
          break;
        case 'delete':
          // await _apiClient.deleteJournalEntry(id);
          break;
      }
      return true;
    } catch (e) {
      debugPrint('Error syncing journal entry: $e');
      return false;
    }
  }

  void _updateStatus(SyncStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  // Queue an operation for later sync
  Future<void> queueOperation({
    required String operation,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
  }) async {
    await _databaseService.addToSyncQueue(
      operation: operation,
      entityType: entityType,
      entityId: entityId,
      data: data,
    );

    // Try to sync immediately if online
    if (_connectivityService.isOnline) {
      syncAll();
    }
  }

  Future<void> clearSyncQueue() async {
    await _databaseService.clearSyncQueue();
    notifyListeners();
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _connectivityService.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}
