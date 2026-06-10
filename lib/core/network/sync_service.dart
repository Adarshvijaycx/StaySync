import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/appwrite_constants.dart';
import '../../data/datasources/appwrite_client.dart';
import 'connectivity_service.dart';
import 'sync_queue.dart';

enum SyncStatus { synced, syncing, pending, failed }

class SyncNotifier extends StateNotifier<SyncStatus> {
  final SyncQueue _syncQueue;
  final ConnectivityService _connectivityService;
  final Databases _databases;

  SyncNotifier(this._syncQueue, this._connectivityService, this._databases) 
    : super(SyncStatus.synced) {
    _init();
  }

  void _init() {
    _connectivityService.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        syncNow();
      }
    });
    _checkPending();
  }

  Future<void> _checkPending() async {
    final pending = await _syncQueue.getPendingOperations();
    if (pending.isNotEmpty && state != SyncStatus.syncing) {
      state = SyncStatus.pending;
      syncNow();
    }
  }

  Future<void> syncNow() async {
    if (state == SyncStatus.syncing) return;
    
    final isConnected = await _connectivityService.isConnected;
    if (!isConnected) {
      state = SyncStatus.pending;
      return;
    }

    final pending = await _syncQueue.getPendingOperations();
    if (pending.isEmpty) {
      state = SyncStatus.synced;
      return;
    }

    state = SyncStatus.syncing;

    for (final op in pending) {
      try {
        final data = json.decode(op.payload) as Map<String, dynamic>;
        final docId = data['id'];
        if (docId != null) {
          data.remove('id');
        }

        if (op.operationType == 'create') {
          await _databases.createDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: op.collectionId,
            documentId: docId ?? 'unique()',
            data: data,
          );
        } else if (op.operationType == 'update') {
          try {
            await _databases.updateDocument(
              databaseId: AppwriteConstants.databaseId,
              collectionId: op.collectionId,
              documentId: docId!,
              data: data,
            );
          } on AppwriteException catch (e) {
            if (e.code == 404) {
              // Document doesn't exist on server, we should probably recreate it
              await _databases.createDocument(
                databaseId: AppwriteConstants.databaseId,
                collectionId: op.collectionId,
                documentId: docId,
                data: data,
              );
            } else {
              rethrow;
            }
          }
        } else if (op.operationType == 'delete') {
          await _databases.deleteDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: op.collectionId,
            documentId: docId!,
          );
        }
        
        await _syncQueue.removeOperation(op.id);
      } catch (e) {
        debugPrint('Sync error on op \${op.id}: \$e');
        if (op.retryCount >= 3) {
          state = SyncStatus.failed;
        } else {
          await _syncQueue.incrementRetryCount(op.id);
        }
      }
    }

    final remaining = await _syncQueue.getPendingOperations();
    if (remaining.isEmpty) {
      state = SyncStatus.synced;
    } else {
      state = SyncStatus.failed;
    }
  }
}

final syncServiceProvider = StateNotifierProvider<SyncNotifier, SyncStatus>((ref) {
  return SyncNotifier(
    ref.watch(syncQueueProvider),
    ref.watch(connectivityServiceProvider),
    ref.watch(appwriteDatabasesProvider),
  );
});
