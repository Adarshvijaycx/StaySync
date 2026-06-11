import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/booking_status.dart';
import '../datasources/local/booking_local_datasource.dart';
import '../datasources/remote/booking_remote_datasource.dart';
import '../../core/network/sync_queue.dart';
import '../../core/network/sync_service.dart';
import '../../core/constants/appwrite_constants.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class BookingRepository {
  final BookingLocalDataSource _localDataSource;
  final BookingRemoteDataSource _remoteDataSource;
  final SyncQueue _syncQueue;
  final SyncNotifier _syncNotifier;

  BookingRepository({
    required BookingLocalDataSource localDataSource,
    required BookingRemoteDataSource remoteDataSource,
    required SyncQueue syncQueue,
    required SyncNotifier syncNotifier,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _syncQueue = syncQueue,
        _syncNotifier = syncNotifier;

  Future<List<Booking>> getBookingsForHotel(String hotelId, {bool forceRefresh = false}) async {
    try {
      // Check if there are pending booking sync operations
      final pendingOps = await _syncQueue.getPendingOperations();
      final hasPendingBookingOps = pendingOps.any(
        (op) => op.collectionId == AppwriteConstants.bookingsCollection,
      );

      if (forceRefresh && !hasPendingBookingOps) {
        final remoteData = await _remoteDataSource.getBookingsForHotel(hotelId);
        await _localDataSource.clearBookingsForHotel(hotelId);
        await _localDataSource.saveBookings(remoteData);
        return remoteData;
      }

      final localData = await _localDataSource.getBookingsForHotel(hotelId);
      if (localData.isNotEmpty) {
        if (!hasPendingBookingOps) {
          _syncInBackground(hotelId);
        }
        return localData;
      }

      final remoteData = await _remoteDataSource.getBookingsForHotel(hotelId);
      await _localDataSource.saveBookings(remoteData);
      return remoteData;
    } on AppwriteException {
      return await _localDataSource.getBookingsForHotel(hotelId);
    } catch (e) {
      return await _localDataSource.getBookingsForHotel(hotelId);
    }
  }

  Future<void> _syncInBackground(String hotelId) async {
    try {
      // CRITICAL: Do NOT overwrite local data if there are pending sync operations.
      // Otherwise we'd replace locally-updated records (e.g. checkedOut bookings)
      // with stale data from the server that hasn't received our updates yet.
      final pendingOps = await _syncQueue.getPendingOperations();
      final hasPendingBookingOps = pendingOps.any(
        (op) => op.collectionId == AppwriteConstants.bookingsCollection,
      );
      if (hasPendingBookingOps) {
        return; // Skip background sync — local data is ahead of server
      }

      final remoteData = await _remoteDataSource.getBookingsForHotel(hotelId);
      await _localDataSource.clearBookingsForHotel(hotelId);
      await _localDataSource.saveBookings(remoteData);
    } catch (_) {}
  }

  Future<bool> _isRoomAvailable(String hotelId, String roomId, DateTime checkIn, DateTime checkOut, {String? excludeBookingId}) async {
    // Client-side overlap validation logic
    final allBookings = await getBookingsForHotel(hotelId);
    
    for (final booking in allBookings) {
      if (booking.roomId != roomId) continue;
      if (booking.status == BookingStatus.cancelled) continue;
      if (excludeBookingId != null && booking.id == excludeBookingId) continue;
      
      // If check-out is before booking check-in, OR check-in is after booking check-out, no overlap
      final hasOverlap = checkIn.isBefore(booking.checkOut) && checkOut.isAfter(booking.checkIn);
      if (hasOverlap) return false;
    }
    
    return true;
  }

  Future<Booking> createBooking(Booking booking) async {
    final isAvailable = await _isRoomAvailable(booking.hotelId, booking.roomId, booking.checkIn, booking.checkOut);
    if (!isAvailable) {
      throw Exception('Room is already booked for the selected dates.');
    }

    final newId = booking.id.isEmpty ? const Uuid().v4() : booking.id;
    final localBooking = booking.copyWith(id: newId);

    // Save locally
    await _localDataSource.saveBooking(localBooking);

    // Queue for sync
    await _syncQueue.enqueue(
      collectionId: AppwriteConstants.bookingsCollection,
      operationType: 'create',
      payload: json.encode(localBooking.toAppwriteMap()),
    );

    // Trigger sync
    _syncNotifier.syncNow();

    return localBooking;
  }

  Future<Booking> updateBooking(Booking booking) async {
    final isAvailable = await _isRoomAvailable(booking.hotelId, booking.roomId, booking.checkIn, booking.checkOut, excludeBookingId: booking.id);
    if (!isAvailable) {
      throw Exception('Room is already booked for the selected dates.');
    }

    final updated = booking.copyWith(updatedAt: DateTime.now());

    // Save locally
    await _localDataSource.saveBooking(updated);

    // Queue for sync
    await _syncQueue.enqueue(
      collectionId: AppwriteConstants.bookingsCollection,
      operationType: 'update',
      payload: json.encode(updated.toAppwriteMap()),
    );

    // Trigger sync
    _syncNotifier.syncNow();

    return updated;
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(
    localDataSource: ref.watch(bookingLocalDataSourceProvider),
    remoteDataSource: ref.watch(bookingRemoteDataSourceProvider),
    syncQueue: ref.read(syncQueueProvider),
    syncNotifier: ref.read(syncServiceProvider.notifier),
  );
});
