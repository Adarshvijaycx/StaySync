import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../domain/entities/booking_item.dart';
import 'database_helper.dart';

class BookingItemLocalDataSource {
  final DatabaseHelper dbHelper;

  BookingItemLocalDataSource({required this.dbHelper});

  Future<List<BookingItem>> getItemsForBooking(String bookingId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'booking_items',
      where: 'booking_id = ?',
      whereArgs: [bookingId],
      orderBy: 'added_at DESC',
    );
    return maps.map((map) => BookingItem.fromMap(map)).toList();
  }

  Future<void> saveBookingItem(BookingItem item) async {
    final db = await dbHelper.database;
    await db.insert(
      'booking_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveBookingItems(List<BookingItem> items) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        'booking_items',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteBookingItem(String id) async {
    final db = await dbHelper.database;
    await db.delete(
      'booking_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearItemsForBooking(String bookingId) async {
    final db = await dbHelper.database;
    await db.delete(
      'booking_items',
      where: 'booking_id = ?',
      whereArgs: [bookingId],
    );
  }
}

final bookingItemLocalDataSourceProvider = Provider<BookingItemLocalDataSource>((ref) {
  return BookingItemLocalDataSource(
    dbHelper: ref.watch(databaseHelperProvider),
  );
});
