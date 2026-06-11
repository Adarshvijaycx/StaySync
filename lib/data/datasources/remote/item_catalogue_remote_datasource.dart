import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/appwrite_constants.dart';
import '../../../domain/entities/item_catalogue.dart';
import '../appwrite_client.dart';

class ItemCatalogueRemoteDataSource {
  final Databases databases;

  ItemCatalogueRemoteDataSource({required this.databases});

  Future<List<ItemCatalogue>> getCatalogueForHotel(String hotelId) async {
    final response = await databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.itemCatalogueCollection,
      queries: [
        Query.equal('hotel_id', hotelId),
      ],
    );
    return response.documents.map((doc) => ItemCatalogue.fromMap(doc.data)).toList();
  }

  Future<ItemCatalogue> createItem(ItemCatalogue item) async {
    final response = await databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.itemCatalogueCollection,
      documentId: 'unique()',
      data: item.toAppwriteMap()..remove('id'),
    );
    return ItemCatalogue.fromMap(response.data);
  }

  Future<ItemCatalogue> updateItem(ItemCatalogue item) async {
    final response = await databases.updateDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.itemCatalogueCollection,
      documentId: item.id,
      data: item.toAppwriteMap()..remove('id'),
    );
    return ItemCatalogue.fromMap(response.data);
  }

  Future<void> deleteItem(String id) async {
    await databases.deleteDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.itemCatalogueCollection,
      documentId: id,
    );
  }
}

final itemCatalogueRemoteDataSourceProvider = Provider<ItemCatalogueRemoteDataSource>((ref) {
  return ItemCatalogueRemoteDataSource(
    databases: ref.watch(appwriteDatabasesProvider),
  );
});
