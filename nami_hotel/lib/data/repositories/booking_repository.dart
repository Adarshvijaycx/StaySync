import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/booking_status.dart';
import '../datasources/local/booking_local_datasource.dart';
import '../datasources/remote/booking_remote_datasource.dart';

class BookingRepository {
  final BookingLocalDataSource _localDataSource;
  final BookingRemoteDataSource _remoteDataSource;

  BookingRepository({
    required this._localDataSource,
    required this._remoteDataSource,
  });

  Future<List<Booking>> getBookingsForHotel(String hotelId, {bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        final remoteData = await _remoteDataSource.getBookingsForHotel(hotelId);
        await _localDataSource.clearBookingsForHotel(hotelId);
        await _localDataSource.saveBookings(remoteData);
        return remoteData;
      }

      final localData = await _localDataSource.getBookingsForHotel(hotelId);
      if (localData.isNotEmpty) {
        _syncInBackground(hotelId);
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

    final remoteBooking = await _remoteDataSource.createBooking(booking);
    await _localDataSource.saveBooking(remoteBooking);
    return remoteBooking;
  }

  Future<Booking> updateBooking(Booking booking) async {
    final isAvailable = await _isRoomAvailable(booking.hotelId, booking.roomId, booking.checkIn, booking.checkOut, excludeBookingId: booking.id);
    if (!isAvailable) {
      throw Exception('Room is already booked for the selected dates.');
    }

    final updated = booking.copyWith(updatedAt: DateTime.now());
    final remoteBooking = await _remoteDataSource.updateBooking(updated);
    await _localDataSource.saveBooking(remoteBooking);
    return remoteBooking;
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(
    localDataSource: ref.watch(bookingLocalDataSourceProvider),
    remoteDataSource: ref.watch(bookingRemoteDataSourceProvider),
  );
});
