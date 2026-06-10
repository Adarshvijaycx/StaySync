import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../domain/entities/booking.dart';
import 'database_helper.dart';

class BookingLocalDataSource {
  final DatabaseHelper _dbHelper;

  BookingLocalDataSource({required this._dbHelper});

  Future<List<Booking>> getBookingsForHotel(String hotelId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bookings',
      where: 'hotel_id = ?',
      whereArgs: [hotelId],
      orderBy: 'check_in DESC',
    );
    return maps.map((map) => Booking.fromMap(map)).toList();
  }

  Future<Booking?> getBooking(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'bookings',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Booking.fromMap(maps.first);
  }

  Future<void> saveBooking(Booking booking) async {
    final db = await _dbHelper.database;
    await db.insert(
      'bookings',
      booking.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveBookings(List<Booking> bookings) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final booking in bookings) {
      batch.insert(
        'bookings',
        booking.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteBooking(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'bookings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearBookingsForHotel(String hotelId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'bookings',
      where: 'hotel_id = ?',
      whereArgs: [hotelId],
    );
  }
}

final bookingLocalDataSourceProvider = Provider<BookingLocalDataSource>((ref) {
  return BookingLocalDataSource(
    dbHelper: ref.watch(databaseHelperProvider),
  );
});
