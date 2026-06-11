import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/app_user.dart';
import 'hotel_providers.dart';

/// Possible states for the authentication flow.
sealed class AuthState {
  const AuthState();
}

/// Initial state — auth status not yet determined.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Currently checking for existing session.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is authenticated.
class AuthAuthenticated extends AuthState {
  final AppUser user;
  const AuthAuthenticated(this.user);
}

/// User is not authenticated (no session or logged out).
class AuthUnauthenticated extends AuthState {
  final String? errorMessage;
  const AuthUnauthenticated({this.errorMessage});
}

/// Notifier managing auth state transitions.
///
/// On initialization, checks for existing session (online or cached).
/// Exposes [login] and [logout] methods for UI.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final Ref _ref;

  AuthNotifier({required AuthRepository authRepository, required Ref ref})
      : _authRepository = authRepository,
        _ref = ref,
        super(const AuthInitial()) {
    _checkExistingSession();
  }

  /// Check if user has an existing valid session.
  Future<void> _checkExistingSession() async {
    state = const AuthLoading();

    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      debugPrint('Session check error: $e');
      state = const AuthUnauthenticated();
    }
  }

  /// Login with email/password.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();

    // --- TEMPORARY MOCK LOGIN BYPASS ---
    // Since Appwrite is not fully configured yet, use these credentials to test:
    
    // Get the first available hotel dynamically for mock testing
    String mockHotelId = 'hotel_xyz';
    try {
      final hotels = await _ref.read(hotelsProvider.future);
      if (hotels.isNotEmpty) {
        mockHotelId = hotels.first.id;
      }
    } catch (_) {}

    if (email == 'admin@nami.com') {
      state = AuthAuthenticated(AppUser(
        userId: 'admin_123',
        email: email,
        name: 'Super Admin',
        role: UserRole.admin,
        isActive: true,
      ));
      return;
    } else if (email == 'manager@nami.com') {
      state = AuthAuthenticated(AppUser(
        userId: 'manager_123',
        email: email,
        name: 'Hotel Manager',
        role: UserRole.manager,
        hotelId: mockHotelId,
        isActive: true,
      ));
      return;
    } else if (email == 'staff@nami.com') {
      state = AuthAuthenticated(AppUser(
        userId: 'staff_123',
        email: email,
        name: 'Front Desk Staff',
        role: UserRole.staff,
        hotelId: mockHotelId,
        isActive: true,
      ));
      return;
    }
    // --- END TEMPORARY BYPASS ---

    try {
      final user = await _authRepository.login(
        email: email,
        password: password,
      );
      state = AuthAuthenticated(user);
    } on AppwriteException catch (e) {
      state = AuthUnauthenticated(
        errorMessage: e.message ?? 'Login failed. Please try again.',
      );
    } catch (e) {
      state = AuthUnauthenticated(
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Logout and clear session.
  Future<void> logout() async {
    state = const AuthLoading();
    await _authRepository.logout();
    state = const AuthUnauthenticated();
  }
}

/// Global auth state provider — used by GoRouter redirect and all screens.
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    authRepository: ref.watch(authRepositoryProvider),
    ref: ref,
  );
});

/// Convenience provider that extracts the current user if authenticated.
final currentUserProvider = Provider<AppUser?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState is AuthAuthenticated) {
    return authState.user;
  }
  return null;
});
