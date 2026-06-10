import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/item_catalogue.dart';
import '../datasources/local/item_catalogue_local_datasource.dart';
import '../datasources/remote/item_catalogue_remote_datasource.dart';

class ItemCatalogueRepository {
  final ItemCatalogueLocalDataSource localDataSource;
  final ItemCatalogueRemoteDataSource remoteDataSource;

  ItemCatalogueRepository({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  Future<List<ItemCatalogue>> getCatalogueForHotel(String hotelId, {bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        final remoteData = await remoteDataSource.getCatalogueForHotel(hotelId);
        await localDataSource.clearCatalogueForHotel(hotelId);
        await localDataSource.saveItems(remoteData);
        return remoteData;
      }

      final localData = await localDataSource.getCatalogueForHotel(hotelId);
      if (localData.isNotEmpty) {
        _syncInBackground(hotelId);
        return localData;
      }

      final remoteData = await remoteDataSource.getCatalogueForHotel(hotelId);
      await localDataSource.saveItems(remoteData);
      return remoteData;
    } on AppwriteException {
      return await localDataSource.getCatalogueForHotel(hotelId);
    } catch (e) {
      return await localDataSource.getCatalogueForHotel(hotelId);
    }
  }

  Future<void> _syncInBackground(String hotelId) async {
    try {
      final remoteData = await remoteDataSource.getCatalogueForHotel(hotelId);
      await localDataSource.clearCatalogueForHotel(hotelId);
      await localDataSource.saveItems(remoteData);
    } catch (_) {}
  }

  Future<ItemCatalogue> createItem(ItemCatalogue item) async {
    final remoteItem = await remoteDataSource.createItem(item);
    await localDataSource.saveItem(remoteItem);
    return remoteItem;
  }

  Future<ItemCatalogue> updateItem(ItemCatalogue item) async {
    final updated = item.copyWith(updatedAt: DateTime.now());
    final remoteItem = await remoteDataSource.updateItem(updated);
    await localDataSource.saveItem(remoteItem);
    return remoteItem;
  }

  Future<void> deleteItem(String id) async {
    await remoteDataSource.deleteItem(id);
    await localDataSource.deleteItem(id);
  }
}

final itemCatalogueRepositoryProvider = Provider<ItemCatalogueRepository>((ref) {
  return ItemCatalogueRepository(
    localDataSource: ref.watch(itemCatalogueLocalDataSourceProvider),
    remoteDataSource: ref.watch(itemCatalogueRemoteDataSourceProvider),
  );
});
