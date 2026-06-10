import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/models/pending_operation_model.dart';

/// Manages the local queue of offline write operations.
class SyncQueue {
  final DatabaseHelper _dbHelper;

  SyncQueue({required DatabaseHelper dbHelper}) : _dbHelper = dbHelper;

  /// Add a new operation to the queue.
  Future<void> enqueue({
    required String collectionId,
    required String operationType,
    required String payload,
  }) async {
    final db = await _dbHelper.database;
    final operation = PendingOperation(
      collectionId: collectionId,
      operationType: operationType,
      payload: payload,
    );
    await db.insert(
      'pending_operations',
      operation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all pending operations ordered by oldest first.
  Future<List<PendingOperation>> getPendingOperations() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'pending_operations',
      orderBy: 'created_at ASC',
    );
    return maps.map((e) => PendingOperation.fromMap(e)).toList();
  }

  /// Increment the retry count for a failed operation.
  Future<void> incrementRetryCount(String id) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE pending_operations SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  /// Remove an operation from the queue (e.g., after successful sync).
  Future<void> removeOperation(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'pending_operations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clear all pending operations.
  Future<void> clearAll() async {
    final db = await _dbHelper.database;
    await db.delete('pending_operations');
  }
}

final syncQueueProvider = Provider<SyncQueue>((ref) {
  return SyncQueue(dbHelper: ref.watch(databaseHelperProvider));
});
