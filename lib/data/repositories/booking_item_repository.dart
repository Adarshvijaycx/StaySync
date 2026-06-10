import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/booking_item.dart';
import '../datasources/local/booking_item_local_datasource.dart';
import '../datasources/remote/booking_item_remote_datasource.dart';
import '../../core/network/sync_queue.dart';
import '../../core/network/sync_service.dart';
import '../../core/constants/appwrite_constants.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class BookingItemRepository {
  final BookingItemLocalDataSource localDataSource;
  final BookingItemRemoteDataSource remoteDataSource;
  final SyncQueue syncQueue;
  final SyncNotifier syncNotifier;

  BookingItemRepository({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.syncQueue,
    required this.syncNotifier,
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
    final newId = item.id.isEmpty ? const Uuid().v4() : item.id;
    final localItem = item.copyWith(id: newId);

    // Save locally
    await localDataSource.saveBookingItem(localItem);

    // Queue for sync
    await syncQueue.enqueue(
      collectionId: AppwriteConstants.bookingItemsCollection,
      operationType: 'create',
      payload: json.encode(localItem.toMap()),
    );

    syncNotifier.syncNow();
    return localItem;
  }

  Future<BookingItem> updateBookingItem(BookingItem item) async {
    // Save locally
    await localDataSource.saveBookingItem(item);

    // Queue for sync
    await syncQueue.enqueue(
      collectionId: AppwriteConstants.bookingItemsCollection,
      operationType: 'update',
      payload: json.encode(item.toMap()),
    );

    syncNotifier.syncNow();
    return item;
  }

  Future<void> deleteBookingItem(String id) async {
    // Delete locally
    await localDataSource.deleteBookingItem(id);

    // Queue for sync
    await syncQueue.enqueue(
      collectionId: AppwriteConstants.bookingItemsCollection,
      operationType: 'delete',
      payload: json.encode({'id': id}),
    );

    syncNotifier.syncNow();
  }
}

final bookingItemRepositoryProvider = Provider<BookingItemRepository>((ref) {
  return BookingItemRepository(
    localDataSource: ref.watch(bookingItemLocalDataSourceProvider),
    remoteDataSource: ref.watch(bookingItemRemoteDataSourceProvider),
    syncQueue: ref.watch(syncQueueProvider),
    syncNotifier: ref.watch(syncServiceProvider.notifier),
  );
});
