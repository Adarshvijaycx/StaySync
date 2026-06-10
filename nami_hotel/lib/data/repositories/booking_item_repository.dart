import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/booking_item.dart';
import '../datasources/local/booking_item_local_datasource.dart';
import '../datasources/remote/booking_item_remote_datasource.dart';

class BookingItemRepository {
  final BookingItemLocalDataSource localDataSource;
  final BookingItemRemoteDataSource remoteDataSource;

  BookingItemRepository({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  Future<List<BookingItem>> getItemsForBooking(String bookingId, {bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        final remoteData = await remoteDataSource.getItemsForBooking(bookingId);
        await localDataSource.clearItemsForBooking(bookingId);
        await localDataSource.saveBookingItems(remoteData);
        return remoteData;
      }

      final localData = await localDataSource.getItemsForBooking(bookingId);
      if (localData.isNotEmpty) {
        _syncInBackground(bookingId);
        return localData;
      }

      final remoteData = await remoteDataSource.getItemsForBooking(bookingId);
      await localDataSource.saveBookingItems(remoteData);
      return remoteData;
    } on AppwriteException {
      return await localDataSource.getItemsForBooking(bookingId);
    } catch (e) {
      return await localDataSource.getItemsForBooking(bookingId);
    }
  }

  Future<void> _syncInBackground(String bookingId) async {
    try {
      final remoteData = await remoteDataSource.getItemsForBooking(bookingId);
      await localDataSource.clearItemsForBooking(bookingId);
      await localDataSource.saveBookingItems(remoteData);
    } catch (_) {}
  }

  Future<BookingItem> createBookingItem(BookingItem item) async {
    final remoteItem = await remoteDataSource.createBookingItem(item);
    await localDataSource.saveBookingItem(remoteItem);
    return remoteItem;
  }

  Future<BookingItem> updateBookingItem(BookingItem item) async {
    final remoteItem = await remoteDataSource.updateBookingItem(item);
    await localDataSource.saveBookingItem(remoteItem);
    return remoteItem;
  }

  Future<void> deleteBookingItem(String id) async {
    await remoteDataSource.deleteBookingItem(id);
    await localDataSource.deleteBookingItem(id);
  }
}

final bookingItemRepositoryProvider = Provider<BookingItemRepository>((ref) {
  return BookingItemRepository(
    localDataSource: ref.watch(bookingItemLocalDataSourceProvider),
    remoteDataSource: ref.watch(bookingItemRemoteDataSourceProvider),
  );
});
