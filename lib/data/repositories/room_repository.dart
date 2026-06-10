import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/room.dart';
import '../datasources/local/room_local_datasource.dart';
import '../datasources/remote/room_remote_datasource.dart';
import 'package:appwrite/appwrite.dart';

/// Repository handling Room operations, orchestrating online and offline data.
class RoomRepository {
  final RoomLocalDataSource _localDataSource;
  final RoomRemoteDataSource _remoteDataSource;

  RoomRepository({
    required this._localDataSource,
    required this._remoteDataSource,
  });

  Future<List<Room>> getRooms(String hotelId, {bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        final remoteRooms = await _remoteDataSource.getRooms(hotelId);
        await _localDataSource.clearRoomsForHotel(hotelId);
        await _localDataSource.saveRooms(remoteRooms);
        return remoteRooms;
      }

      final localRooms = await _localDataSource.getRooms(hotelId);
      if (localRooms.isNotEmpty) {
        _syncRoomsInBackground(hotelId);
        return localRooms;
      }

      final remoteRooms = await _remoteDataSource.getRooms(hotelId);
      await _localDataSource.saveRooms(remoteRooms);
      return remoteRooms;
    } on AppwriteException {
      return await _localDataSource.getRooms(hotelId);
    } catch (e) {
      return await _localDataSource.getRooms(hotelId);
    }
  }

  Future<void> _syncRoomsInBackground(String hotelId) async {
    try {
      final remoteRooms = await _remoteDataSource.getRooms(hotelId);
      await _localDataSource.clearRoomsForHotel(hotelId);
      await _localDataSource.saveRooms(remoteRooms);
    } catch (_) {
      // Ignore background sync errors
    }
  }

  Future<Room> createRoom(Room room) async {
    final remoteRoom = await _remoteDataSource.createRoom(room);
    await _localDataSource.saveRoom(remoteRoom);
    return remoteRoom;
  }

  Future<Room> updateRoom(Room room) async {
    final updatedRoom = room.copyWith(updatedAt: DateTime.now());
    final remoteRoom = await _remoteDataSource.updateRoom(updatedRoom);
    await _localDataSource.saveRoom(remoteRoom);
    return remoteRoom;
  }

  Future<void> deleteRoom(String id) async {
    await _remoteDataSource.deleteRoom(id);
    await _localDataSource.deleteRoom(id);
  }
}

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepository(
    localDataSource: ref.watch(roomLocalDataSourceProvider),
    remoteDataSource: ref.watch(roomRemoteDataSourceProvider),
  );
});
