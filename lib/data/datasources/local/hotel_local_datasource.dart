import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../domain/entities/hotel.dart';
import 'database_helper.dart';

/// Local data source for Hotel CRUD operations using SQLite.
class HotelLocalDataSource {
  final DatabaseHelper _dbHelper;

  HotelLocalDataSource({required this._dbHelper});

  Future<List<Hotel>> getHotels() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('hotels');
    return maps.map((map) => Hotel.fromMap(map)).toList();
  }

  Future<Hotel?> getHotel(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'hotels',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Hotel.fromMap(maps.first);
  }

  Future<void> saveHotel(Hotel hotel) async {
    final db = await _dbHelper.database;
    await db.insert(
      'hotels',
      hotel.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveHotels(List<Hotel> hotels) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final hotel in hotels) {
      batch.insert(
        'hotels',
        hotel.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteHotel(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'hotels',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clears all hotels, usually called before a full sync.
  Future<void> clearAll() async {
    final db = await _dbHelper.database;
    await db.delete('hotels');
  }
}

/// Provider for HotelLocalDataSource.
final hotelLocalDataSourceProvider = Provider<HotelLocalDataSource>((ref) {
  return HotelLocalDataSource(
    dbHelper: ref.watch(databaseHelperProvider),
  );
});
