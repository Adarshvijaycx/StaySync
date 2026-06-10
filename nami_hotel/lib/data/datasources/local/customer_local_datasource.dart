import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../domain/entities/customer.dart';
import 'database_helper.dart';

class CustomerLocalDataSource {
  final DatabaseHelper _dbHelper;

  CustomerLocalDataSource({required this._dbHelper});

  Future<List<Customer>> getCustomers() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('customers');
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  Future<Customer?> getCustomer(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  Future<void> saveCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    await db.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveCustomers(List<Customer> customers) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final customer in customers) {
      batch.insert(
        'customers',
        customer.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteCustomer(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAll() async {
    final db = await _dbHelper.database;
    await db.delete('customers');
  }
}

final customerLocalDataSourceProvider = Provider<CustomerLocalDataSource>((ref) {
  return CustomerLocalDataSource(
    dbHelper: ref.watch(databaseHelperProvider),
  );
});
