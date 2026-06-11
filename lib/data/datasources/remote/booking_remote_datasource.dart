import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/appwrite_constants.dart';
import '../../../domain/entities/booking.dart';
import '../appwrite_client.dart';

class BookingRemoteDataSource {
  final Databases _databases;

  BookingRemoteDataSource({required this._databases});

  Future<List<Booking>> getBookingsForHotel(String hotelId) async {
    final response = await _databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.bookingsCollection,
      queries: [
        Query.equal('hotel_id', hotelId),
      ],
    );
    return response.documents.map((doc) => Booking.fromMap(doc.data)).toList();
  }

  Future<Booking> createBooking(Booking booking) async {
    final response = await _databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.bookingsCollection,
      documentId: 'unique()',
      data: booking.toAppwriteMap()..remove('id'),
    );
    return Booking.fromMap(response.data);
  }

  Future<Booking> updateBooking(Booking booking) async {
    final response = await _databases.updateDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.bookingsCollection,
      documentId: booking.id,
      data: booking.toAppwriteMap()..remove('id'),
    );
    return Booking.fromMap(response.data);
  }
}

final bookingRemoteDataSourceProvider = Provider<BookingRemoteDataSource>((ref) {
  return BookingRemoteDataSource(
    databases: ref.watch(appwriteDatabasesProvider),
  );
});
