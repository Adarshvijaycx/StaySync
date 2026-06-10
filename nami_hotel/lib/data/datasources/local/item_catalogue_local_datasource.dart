import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../domain/entities/item_catalogue.dart';
import 'database_helper.dart';

class ItemCatalogueLocalDataSource {
  final DatabaseHelper dbHelper;

  ItemCatalogueLocalDataSource({required this.dbHelper});

  Future<List<ItemCatalogue>> getCatalogueForHotel(String hotelId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'item_catalogue',
      where: 'hotel_id = ?',
      whereArgs: [hotelId],
      orderBy: 'name ASC',
    );
    return maps.map((map) => ItemCatalogue.fromMap(map)).toList();
  }

  Future<void> saveItem(ItemCatalogue item) async {
    final db = await dbHelper.database;
    await db.insert(
      'item_catalogue',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveItems(List<ItemCatalogue> items) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        'item_catalogue',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteItem(String id) async {
    final db = await dbHelper.database;
    await db.delete(
      'item_catalogue',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearCatalogueForHotel(String hotelId) async {
    final db = await dbHelper.database;
    await db.delete(
      'item_catalogue',
      where: 'hotel_id = ?',
      whereArgs: [hotelId],
    );
  }
}

final itemCatalogueLocalDataSourceProvider = Provider<ItemCatalogueLocalDataSource>((ref) {
  return ItemCatalogueLocalDataSource(
    dbHelper: ref.watch(databaseHelperProvider),
  );
});
