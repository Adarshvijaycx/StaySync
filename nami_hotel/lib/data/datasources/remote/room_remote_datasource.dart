import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/appwrite_constants.dart';
import '../../../domain/entities/room.dart';
import '../appwrite_client.dart';

/// Remote data source for Room CRUD operations via Appwrite.
class RoomRemoteDataSource {
  final Databases _databases;

  RoomRemoteDataSource({required this._databases});

  Future<List<Room>> getRooms(String hotelId) async {
    final response = await _databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.roomsCollection,
      queries: [
        Query.equal('hotel_id', hotelId),
      ],
    );
    return response.documents.map((doc) => Room.fromMap(doc.data)).toList();
  }

  Future<Room> createRoom(Room room) async {
    final response = await _databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.roomsCollection,
      documentId: 'unique()',
      data: room.toMap()..remove('id'),
    );
    return Room.fromMap(response.data);
  }

  Future<Room> updateRoom(Room room) async {
    final response = await _databases.updateDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.roomsCollection,
      documentId: room.id,
      data: room.toMap()..remove('id'),
    );
    return Room.fromMap(response.data);
  }

  Future<void> deleteRoom(String id) async {
    await _databases.deleteDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.roomsCollection,
      documentId: id,
    );
  }
}

/// Provider for RoomRemoteDataSource.
final roomRemoteDataSourceProvider = Provider<RoomRemoteDataSource>((ref) {
  return RoomRemoteDataSource(
    databases: ref.watch(appwriteDatabasesProvider),
  );
});
