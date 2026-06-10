import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/booking_item_repository.dart';
import '../../data/repositories/item_catalogue_repository.dart';
import '../../domain/entities/booking_item.dart';
import '../../domain/entities/item_catalogue.dart';

// --- Item Catalogue ---

final itemCatalogueProvider = AsyncNotifierProvider.family<ItemCatalogueNotifier, List<ItemCatalogue>, String>(() {
  return ItemCatalogueNotifier();
});

class ItemCatalogueNotifier extends FamilyAsyncNotifier<List<ItemCatalogue>, String> {
  late ItemCatalogueRepository _repository;

  @override
  Future<List<ItemCatalogue>> build(String arg) async {
    _repository = ref.watch(itemCatalogueRepositoryProvider);
    return _repository.getCatalogueForHotel(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getCatalogueForHotel(arg, forceRefresh: true));
  }

  Future<void> createItem(ItemCatalogue item) async {
    final newItem = await _repository.createItem(item);
    final currentList = state.value ?? [];
    state = AsyncValue.data([...currentList, newItem]);
  }

  Future<void> updateItem(ItemCatalogue item) async {
    final updated = await _repository.updateItem(item);
    final currentList = state.value ?? [];
    state = AsyncValue.data([
      for (final i in currentList)
        if (i.id == updated.id) updated else i
    ]);
  }

  Future<void> deleteItem(String id) async {
    await _repository.deleteItem(id);
    final currentList = state.value ?? [];
    state = AsyncValue.data(currentList.where((i) => i.id != id).toList());
  }
}

// --- Booking Items (Guest Tab) ---

final bookingItemsProvider = AsyncNotifierProvider.family<BookingItemsNotifier, List<BookingItem>, String>(() {
  return BookingItemsNotifier();
});

class BookingItemsNotifier extends FamilyAsyncNotifier<List<BookingItem>, String> {
  late BookingItemRepository _repository;

  @override
  Future<List<BookingItem>> build(String arg) async {
    _repository = ref.watch(bookingItemRepositoryProvider);
    return _repository.getItemsForBooking(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getItemsForBooking(arg, forceRefresh: true));
  }

  Future<void> createBookingItem(BookingItem item) async {
    final newItem = await _repository.createBookingItem(item);
    final currentList = state.value ?? [];
    state = AsyncValue.data([...currentList, newItem]);
  }

  Future<void> updateBookingItem(BookingItem item) async {
    final updated = await _repository.updateBookingItem(item);
    final currentList = state.value ?? [];
    state = AsyncValue.data([
      for (final i in currentList)
        if (i.id == updated.id) updated else i
    ]);
  }

  Future<void> deleteBookingItem(String id) async {
    await _repository.deleteBookingItem(id);
    final currentList = state.value ?? [];
    state = AsyncValue.data(currentList.where((i) => i.id != id).toList());
  }
}
