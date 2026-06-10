import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/hotel.dart';
import '../datasources/local/hotel_local_datasource.dart';
import '../datasources/remote/hotel_remote_datasource.dart';
import 'package:appwrite/appwrite.dart';

/// Repository handling Hotel operations, orchestrating online and offline data.
class HotelRepository {
  final HotelLocalDataSource _localDataSource;
  final HotelRemoteDataSource _remoteDataSource;

  HotelRepository({
    required this._localDataSource,
    required this._remoteDataSource,
  });

  /// Fetch all hotels. Tries remote first, caches to local.
  /// Falls back to local if remote fails (offline support).
  Future<List<Hotel>> getHotels({bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        // Fetch from Appwrite
        final remoteHotels = await _remoteDataSource.getHotels();
        // Clear local and save new
        await _localDataSource.clearAll();
        await _localDataSource.saveHotels(remoteHotels);
        return remoteHotels;
      }
      
      // If not forced, try getting from local first for fast load
      final localHotels = await _localDataSource.getHotels();
      if (localHotels.isNotEmpty) {
        // Trigger background sync
        _syncHotelsInBackground();
        return localHotels;
      }

      // Local is empty, fetch from remote
      final remoteHotels = await _remoteDataSource.getHotels();
      await _localDataSource.saveHotels(remoteHotels);
      return remoteHotels;
    } on AppwriteException {
      // Return local cache on network error
      return await _localDataSource.getHotels();
    } catch (e) {
      return await _localDataSource.getHotels();
    }
  }

  Future<void> _syncHotelsInBackground() async {
    try {
      final remoteHotels = await _remoteDataSource.getHotels();
      await _localDataSource.clearAll();
      await _localDataSource.saveHotels(remoteHotels);
    } catch (_) {
      // Ignore background sync errors
    }
  }

  Future<Hotel> createHotel(Hotel hotel) async {
    final remoteHotel = await _remoteDataSource.createHotel(hotel);
    await _localDataSource.saveHotel(remoteHotel);
    return remoteHotel;
  }

  Future<Hotel> updateHotel(Hotel hotel) async {
    final updatedHotel = hotel.copyWith(updatedAt: DateTime.now());
    final remoteHotel = await _remoteDataSource.updateHotel(updatedHotel);
    await _localDataSource.saveHotel(remoteHotel);
    return remoteHotel;
  }

  Future<void> deleteHotel(String id) async {
    await _remoteDataSource.deleteHotel(id);
    await _localDataSource.deleteHotel(id);
  }
}

final hotelRepositoryProvider = Provider<HotelRepository>((ref) {
  return HotelRepository(
    localDataSource: ref.watch(hotelLocalDataSourceProvider),
    remoteDataSource: ref.watch(hotelRemoteDataSourceProvider),
  );
});
