import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/appwrite_constants.dart';
import '../../../domain/entities/hotel.dart';
import '../appwrite_client.dart';

/// Remote data source for Hotel CRUD operations via Appwrite.
class HotelRemoteDataSource {
  final Databases _databases;

  HotelRemoteDataSource({required this._databases});

  Future<List<Hotel>> getHotels() async {
    final response = await _databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.hotelsCollection,
    );
    return response.documents.map((doc) => Hotel.fromMap(doc.data)).toList();
  }

  Future<Hotel> createHotel(Hotel hotel) async {
    final response = await _databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.hotelsCollection,
      documentId: 'unique()',
      data: hotel.toMap()..remove('id'), // Let Appwrite generate the ID
    );
    return Hotel.fromMap(response.data);
  }

  Future<Hotel> updateHotel(Hotel hotel) async {
    final response = await _databases.updateDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.hotelsCollection,
      documentId: hotel.id,
      data: hotel.toMap()..remove('id'),
    );
    return Hotel.fromMap(response.data);
  }

  Future<void> deleteHotel(String id) async {
    await _databases.deleteDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.hotelsCollection,
      documentId: id,
    );
  }
}

/// Provider for HotelRemoteDataSource.
final hotelRemoteDataSourceProvider = Provider<HotelRemoteDataSource>((ref) {
  return HotelRemoteDataSource(
    databases: ref.watch(appwriteDatabasesProvider),
  );
});
