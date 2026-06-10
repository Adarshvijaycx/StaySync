import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../domain/entities/room.dart';
import 'database_helper.dart';

/// Local data source for Room CRUD operations using SQLite.
class RoomLocalDataSource {
  final DatabaseHelper _dbHelper;

  RoomLocalDataSource({required this._dbHelper});

  /// Get all rooms for a specific hotel.
  Future<List<Room>> getRooms(String hotelId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rooms',
      where: 'hotel_id = ?',
      whereArgs: [hotelId],
    );
    return maps.map((map) => Room.fromMap(map)).toList();
  }

  Future<Room?> getRoom(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'rooms',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Room.fromMap(maps.first);
  }

  Future<void> saveRoom(Room room) async {
    final db = await _dbHelper.database;
    await db.insert(
      'rooms',
      room.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveRooms(List<Room> rooms) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final room in rooms) {
      batch.insert(
        'rooms',
        room.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteRoom(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'rooms',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clear rooms for a specific hotel (used before sync).
  Future<void> clearRoomsForHotel(String hotelId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'rooms',
      where: 'hotel_id = ?',
      whereArgs: [hotelId],
    );
  }
}

/// Provider for RoomLocalDataSource.
final roomLocalDataSourceProvider = Provider<RoomLocalDataSource>((ref) {
  return RoomLocalDataSource(
    dbHelper: ref.watch(databaseHelperProvider),
  );
});
