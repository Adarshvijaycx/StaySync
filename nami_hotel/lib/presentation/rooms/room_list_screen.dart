import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/hotel_providers.dart';
import '../../core/providers/room_providers.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/room.dart';

class RoomListScreen extends ConsumerWidget {
  final String hotelId;

  const RoomListScreen({super.key, required this.hotelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider(hotelId));
    final hotel = ref.watch(hotelProvider(hotelId));
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser?.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: Text(hotel != null ? '${hotel.name} - Rooms' : 'Rooms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(roomsProvider(hotelId).notifier).refresh(),
          ),
        ],
      ),
      body: roomsAsync.when(
        data: (rooms) {
          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.meeting_room_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No rooms found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Tap the + button to add a room',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(roomsProvider(hotelId).notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rooms.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final room = rooms[index];
                return _RoomCard(room: room, hotelId: hotelId, isAdmin: isAdmin);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Error loading rooms: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => context.go('/hotels/$hotelId/rooms/new'),
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}

class _RoomCard extends StatelessWidget {
  final Room room;
  final String hotelId;
  final bool isAdmin;

  const _RoomCard({required this.room, required this.hotelId, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Status Indicator Indicator
            Container(
              width: 12,
              height: 50,
              decoration: BoxDecoration(
                color: room.status.color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 16),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Room ${room.roomNumber}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          room.type.displayName,
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '\$${room.rate.toStringAsFixed(2)} / night',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        room.status.displayName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: room.status.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Admin Actions
            if (isAdmin) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => context.go('/hotels/$hotelId/rooms/${room.id}/edit'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
