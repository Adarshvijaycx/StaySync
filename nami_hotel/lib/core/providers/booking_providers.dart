import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/booking_repository.dart';
import '../../domain/entities/booking.dart';

final bookingsProvider = AsyncNotifierProvider.family<BookingsNotifier, List<Booking>, String>(() {
  return BookingsNotifier();
});

class BookingsNotifier extends FamilyAsyncNotifier<List<Booking>, String> {
  late BookingRepository _repository;

  @override
  Future<List<Booking>> build(String arg) async {
    _repository = ref.watch(bookingRepositoryProvider);
    return _repository.getBookingsForHotel(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getBookingsForHotel(arg, forceRefresh: true));
  }

  Future<void> createBooking(Booking booking) async {
    try {
      final newBooking = await _repository.createBooking(booking);
      final currentList = state.value ?? [];
      state = AsyncValue.data([...currentList, newBooking]);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBooking(Booking booking) async {
    try {
      final updated = await _repository.updateBooking(booking);
      final currentList = state.value ?? [];
      state = AsyncValue.data([
        for (final b in currentList)
          if (b.id == updated.id) updated else b
      ]);
    } catch (e) {
      rethrow;
    }
  }
}

final bookingProvider = Provider.family<Booking?, ({String hotelId, String bookingId})>((ref, args) {
  final bookingsState = ref.watch(bookingsProvider(args.hotelId));
  return bookingsState.maybeWhen(
    data: (bookings) => bookings.cast<Booking?>().firstWhere(
      (booking) => booking?.id == args.bookingId,
      orElse: () => null,
    ),
    orElse: () => null,
  );
});
