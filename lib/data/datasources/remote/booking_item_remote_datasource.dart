import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/appwrite_constants.dart';
import '../../../domain/entities/booking_item.dart';
import '../appwrite_client.dart';

class BookingItemRemoteDataSource {
  final Databases databases;

  BookingItemRemoteDataSource({required this.databases});

  Future<List<BookingItem>> getItemsForBooking(String bookingId) async {
    final response = await databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.bookingItemsCollection,
      queries: [
        Query.equal('booking_id', bookingId),
      ],
    );
    return response.documents.map((doc) => BookingItem.fromMap(doc.data)).toList();
  }

  Future<BookingItem> createBookingItem(BookingItem item) async {
    final response = await databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.bookingItemsCollection,
      documentId: 'unique()',
      data: item.toAppwriteMap(),
    );
    return BookingItem.fromMap(response.data);
  }

  Future<BookingItem> updateBookingItem(BookingItem item) async {
    final response = await databases.updateDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.bookingItemsCollection,
      documentId: item.id,
      data: item.toAppwriteMap(),
    );
    return BookingItem.fromMap(response.data);
  }

  Future<void> deleteBookingItem(String id) async {
    await databases.deleteDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.bookingItemsCollection,
      documentId: id,
    );
  }
}

final bookingItemRemoteDataSourceProvider = Provider<BookingItemRemoteDataSource>((ref) {
  return BookingItemRemoteDataSource(
    databases: ref.watch(appwriteDatabasesProvider),
  );
});
