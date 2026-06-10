import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/hotel_repository.dart';
import '../../domain/entities/hotel.dart';

/// Provider for the list of hotels.
final hotelsProvider = AsyncNotifierProvider<HotelsNotifier, List<Hotel>>(() {
  return HotelsNotifier();
});

class HotelsNotifier extends AsyncNotifier<List<Hotel>> {
  late HotelRepository _repository;

  @override
  Future<List<Hotel>> build() async {
    _repository = ref.watch(hotelRepositoryProvider);
    return _repository.getHotels();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getHotels(forceRefresh: true));
  }

  Future<void> createHotel(Hotel hotel) async {
    try {
      final newHotel = await _repository.createHotel(hotel);
      final currentList = state.value ?? [];
      state = AsyncValue.data([...currentList, newHotel]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateHotel(Hotel hotel) async {
    try {
      final updatedHotel = await _repository.updateHotel(hotel);
      final currentList = state.value ?? [];
      state = AsyncValue.data([
        for (final h in currentList)
          if (h.id == updatedHotel.id) updatedHotel else h
      ]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteHotel(String id) async {
    try {
      await _repository.deleteHotel(id);
      final currentList = state.value ?? [];
      state = AsyncValue.data(currentList.where((h) => h.id != id).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for a specific hotel by ID.
final hotelProvider = Provider.family<Hotel?, String>((ref, id) {
  final hotelsState = ref.watch(hotelsProvider);
  return hotelsState.maybeWhen(
    data: (hotels) => hotels.cast<Hotel?>().firstWhere(
      (hotel) => hotel?.id == id,
      orElse: () => null,
    ),
    orElse: () => null,
  );
});
