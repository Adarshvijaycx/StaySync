import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/app_user.dart';
import '../datasources/auth_remote_datasource.dart';

/// Keys for SharedPreferences session cache.
class _CacheKeys {
  static const String cachedUser = 'cached_user';
  static const String isLoggedIn = 'is_logged_in';
}

/// Repository handling authentication, session persistence, and
/// offline session caching via SharedPreferences.
class AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepository({required this._remoteDataSource});

  /// Attempt login with email/password.
  ///
  /// On success, fetches the user profile from the `users` collection,
  /// caches it locally, and returns the [AppUser].
  /// Throws [AppwriteException] on invalid credentials.
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    // 1. Create Appwrite session
    await _remoteDataSource.login(email: email, password: password);

    // 2. Get the Appwrite account to extract the user ID
    final account = await _remoteDataSource.getAccount();

    // 3. Fetch role/profile from the `users` collection
    final user = await _remoteDataSource.getUserProfile(account.$id);

    if (user == null) {
      // User exists in Auth but has no profile document — shouldn't happen
      // in a properly configured system, but handle gracefully.
      throw AppwriteException(
        'User profile not found. Contact your administrator.',
        404,
      );
    }

    if (!user.isActive) {
      await _remoteDataSource.logout();
      throw AppwriteException(
        'Your account has been deactivated. Contact your administrator.',
        403,
      );
    }

    // 4. Cache the user locally for offline access
    await _cacheUser(user);

    return user;
  }

  /// Check for an existing valid session on app launch.
  ///
  /// Tries online session first, falls back to cached user if offline.
  Future<AppUser?> getCurrentUser() async {
    try {
      // Try to get the current online session
      final session = await _remoteDataSource.getCurrentSession();
      if (session == null) {
        await _clearCache();
        return null;
      }

      // Session exists — fetch fresh user profile
      final account = await _remoteDataSource.getAccount();
      final user = await _remoteDataSource.getUserProfile(account.$id);

      if (user != null && user.isActive) {
        await _cacheUser(user);
        return user;
      }

      // User is deactivated or profile missing
      await logout();
      return null;
    } on AppwriteException {
      // Offline or network error — try cached user
      return _getCachedUser();
    }
  }

  /// Logout: destroy session and clear local cache.
  Future<void> logout() async {
    await _remoteDataSource.logout();
    await _clearCache();
  }

  // --- Local cache helpers (SharedPreferences) ---

  Future<void> _cacheUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _CacheKeys.cachedUser,
      jsonEncode(user.toMap()),
    );
    await prefs.setBool(_CacheKeys.isLoggedIn, true);
  }

  Future<AppUser?> _getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_CacheKeys.isLoggedIn) ?? false;
    if (!isLoggedIn) return null;

    final userJson = prefs.getString(_CacheKeys.cachedUser);
    if (userJson == null) return null;

    try {
      final map = jsonDecode(userJson) as Map<String, dynamic>;
      return AppUser.fromMap(map);
    } catch (_) {
      await _clearCache();
      return null;
    }
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_CacheKeys.cachedUser);
    await prefs.setBool(_CacheKeys.isLoggedIn, false);
  }
}

/// Provider for the auth repository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
  );
});
