import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/room_repository.dart';
import '../../domain/entities/room.dart';

/// Provider for the list of rooms for a specific hotel.
final roomsProvider = AsyncNotifierProvider.family<RoomsNotifier, List<Room>, String>(() {
  return RoomsNotifier();
});

class RoomsNotifier extends FamilyAsyncNotifier<List<Room>, String> {
  late RoomRepository _repository;

  @override
  Future<List<Room>> build(String arg) async {
    _repository = ref.watch(roomRepositoryProvider);
    return _repository.getRooms(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getRooms(arg, forceRefresh: true));
  }

  Future<void> createRoom(Room room) async {
    try {
      final newRoom = await _repository.createRoom(room);
      final currentList = state.value ?? [];
      state = AsyncValue.data([...currentList, newRoom]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateRoom(Room room) async {
    try {
      final updatedRoom = await _repository.updateRoom(room);
      final currentList = state.value ?? [];
      state = AsyncValue.data([
        for (final r in currentList)
          if (r.id == updatedRoom.id) updatedRoom else r
      ]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteRoom(String id) async {
    try {
      await _repository.deleteRoom(id);
      final currentList = state.value ?? [];
      state = AsyncValue.data(currentList.where((r) => r.id != id).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for a specific room by ID within a hotel.
final roomProvider = Provider.family<Room?, ({String hotelId, String roomId})>((ref, args) {
  final roomsState = ref.watch(roomsProvider(args.hotelId));
  return roomsState.maybeWhen(
    data: (rooms) => rooms.cast<Room?>().firstWhere(
      (room) => room?.id == args.roomId,
      orElse: () => null,
    ),
    orElse: () => null,
  );
});
