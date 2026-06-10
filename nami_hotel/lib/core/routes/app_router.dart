import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/app_user.dart';
import '../providers/auth_provider.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/dashboard/admin_home_screen.dart';
import '../../presentation/dashboard/manager_home_screen.dart';
import '../../presentation/dashboard/staff_home_screen.dart';
import '../../presentation/hotels/hotel_list_screen.dart';
import '../../presentation/hotels/hotel_form_screen.dart';
import '../../presentation/rooms/room_list_screen.dart';
import '../../presentation/rooms/room_form_screen.dart';
import '../../presentation/bookings/booking_list_screen.dart';
import '../../presentation/bookings/booking_form_screen.dart';
import '../../presentation/bookings/booking_detail_screen.dart';
import '../../presentation/items/item_catalogue_screen.dart';

/// Route path constants.
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String admin = '/admin';
  static const String manager = '/manager';
  static const String staff = '/staff';
}

/// GoRouter configuration with role-based guards.
///
/// Redirect logic:
/// - If auth is loading → show splash
/// - If unauthenticated → redirect to /login
/// - If authenticated → redirect to role-specific home
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (BuildContext context, GoRouterState state) {
      final currentPath = state.matchedLocation;

      // While auth is loading, stay on splash
      if (authState is AuthInitial || authState is AuthLoading) {
        return currentPath == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final isAuthenticated = authState is AuthAuthenticated;
      final isOnLogin = currentPath == AppRoutes.login;
      final isOnSplash = currentPath == AppRoutes.splash;

      // Not authenticated → go to login
      if (!isAuthenticated) {
        return isOnLogin ? null : AppRoutes.login;
      }

      // Authenticated → determine the correct home route
      final AuthAuthenticated authState_ = authState;
      final user = authState_.user;
      final homeRoute = _homeRouteForRole(user.role);

      // If on login or splash, redirect to role home
      if (isOnLogin || isOnSplash) {
        return homeRoute;
      }

      // Prevent role from accessing another role's routes
      if (!_isAllowedRoute(currentPath, user.role)) {
        return homeRoute;
      }

      // No redirect needed
      return null;
    },
    routes: [
      // Splash screen (shown while checking session)
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashScreen(),
      ),

      // Login
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // Admin home
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AdminHomeScreen(),
      ),

      // Manager home
      GoRoute(
        path: AppRoutes.manager,
        builder: (context, state) => const ManagerHomeScreen(),
      ),

      // Staff home
      GoRoute(
        path: AppRoutes.staff,
        builder: (context, state) => const StaffHomeScreen(),
      ),

      // Hotels List
      GoRoute(
        path: '/hotels',
        builder: (context, state) => const HotelListScreen(),
      ),
      
      // New Hotel Form
      GoRoute(
        path: '/hotels/new',
        builder: (context, state) => const HotelFormScreen(),
      ),
      
      // Edit Hotel Form
      GoRoute(
        path: '/hotels/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return HotelFormScreen(hotelId: id);
        },
      ),

      // Rooms List for a Hotel
      GoRoute(
        path: '/hotels/:hotelId/rooms',
        builder: (context, state) {
          final hotelId = state.pathParameters['hotelId']!;
          return RoomListScreen(hotelId: hotelId);
        },
      ),

      // New Room Form
      GoRoute(
        path: '/hotels/:hotelId/rooms/new',
        builder: (context, state) {
          final hotelId = state.pathParameters['hotelId']!;
          return RoomFormScreen(hotelId: hotelId);
        },
      ),

      // Edit Room Form
      GoRoute(
        path: '/hotels/:hotelId/rooms/:roomId/edit',
        builder: (context, state) {
          final hotelId = state.pathParameters['hotelId']!;
          final roomId = state.pathParameters['roomId']!;
          return RoomFormScreen(hotelId: hotelId, roomId: roomId);
        },
      ),

      // Bookings List
      GoRoute(
        path: '/hotels/:hotelId/bookings',
        builder: (context, state) {
          final hotelId = state.pathParameters['hotelId']!;
          return BookingListScreen(hotelId: hotelId);
        },
      ),

      // Item Catalogue
      GoRoute(
        path: '/hotels/:hotelId/items',
        builder: (context, state) {
          final hotelId = state.pathParameters['hotelId']!;
          return ItemCatalogueScreen(hotelId: hotelId);
        },
      ),

      // New Booking Form
      GoRoute(
        path: '/hotels/:hotelId/bookings/new',
        builder: (context, state) {
          final hotelId = state.pathParameters['hotelId']!;
          return BookingFormScreen(hotelId: hotelId);
        },
      ),

      // Booking Detail
      GoRoute(
        path: '/hotels/:hotelId/bookings/:bookingId',
        builder: (context, state) {
          final hotelId = state.pathParameters['hotelId']!;
          final bookingId = state.pathParameters['bookingId']!;
          return BookingDetailScreen(hotelId: hotelId, bookingId: bookingId);
        },
      ),

      // Edit Booking Form
      GoRoute(
        path: '/hotels/:hotelId/bookings/:bookingId/edit',
        builder: (context, state) {
          final hotelId = state.pathParameters['hotelId']!;
          final bookingId = state.pathParameters['bookingId']!;
          return BookingFormScreen(hotelId: hotelId, bookingId: bookingId);
        },
      ),
    ],

    // Error page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.matchedLocation),
          ],
        ),
      ),
    ),
  );
});

/// Map [UserRole] to its home route.
String _homeRouteForRole(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return AppRoutes.admin;
    case UserRole.manager:
      return AppRoutes.manager;
    case UserRole.staff:
      return AppRoutes.staff;
  }
}

/// Check if a role is allowed to access a given route.
///
/// Admin can access all routes.
/// Manager and Staff are restricted to their own routes.
bool _isAllowedRoute(String path, UserRole role) {
  switch (role) {
    case UserRole.admin:
      // Admin can go anywhere
      return true;
    case UserRole.manager:
      return path.startsWith(AppRoutes.manager) || path.startsWith('/hotels');
    case UserRole.staff:
      return path.startsWith(AppRoutes.staff) || path.startsWith('/hotels');
  }
}

/// Splash screen shown while checking for existing session.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(alpha: 0.08),
              colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  Icons.hotel_rounded,
                  size: 44,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Nami Hotel',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
