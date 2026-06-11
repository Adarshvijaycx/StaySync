import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/hotel_providers.dart';
import '../../core/providers/room_providers.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/room.dart';
import '../../domain/entities/room_status.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/error_state_widget.dart';

class RoomListScreen extends ConsumerWidget {
  final String hotelId;

  const RoomListScreen({super.key, required this.hotelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider(hotelId));
    final hotel = ref.watch(hotelProvider(hotelId));
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser?.role == UserRole.admin;
    final isManager = currentUser?.role == UserRole.manager;
    final canChangeStatus = isAdmin || isManager;

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
            return EmptyStateWidget(
              icon: Icons.meeting_room_rounded,
              title: 'No rooms found',
              subtitle: isAdmin ? 'Tap the + button to add a room' : 'There are no rooms available.',
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
                return _RoomCard(
                  room: room, 
                  hotelId: hotelId, 
                  isAdmin: isAdmin,
                  canChangeStatus: canChangeStatus,
                  onStatusChanged: (newStatus) {
                    ref.read(roomsProvider(hotelId).notifier).updateRoom(room.copyWith(status: newStatus));
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorStateWidget(
          errorMessage: error.toString(),
          onRetry: () => ref.read(roomsProvider(hotelId).notifier).refresh(),
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => context.push('/hotels/$hotelId/rooms/new'),
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
  final bool canChangeStatus;
  final ValueChanged<RoomStatus> onStatusChanged;

  const _RoomCard({
    required this.room, 
    required this.hotelId, 
    required this.isAdmin,
    required this.canChangeStatus,
    required this.onStatusChanged,
  });

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
                        '₹${room.rate.toStringAsFixed(2)} / night',
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
            
            // Status Actions
            if (canChangeStatus) ...[
              const SizedBox(width: 8),
              PopupMenuButton<RoomStatus>(
                tooltip: 'Change Status',
                icon: Icon(Icons.sync_alt_rounded, color: room.status.color),
                onSelected: onStatusChanged,
                itemBuilder: (context) => RoomStatus.values
                    .map((s) => PopupMenuItem(
                          value: s,
                          child: Text(s.displayName),
                        ))
                    .toList(),
              ),
            ],
            
            // Admin Actions
            if (isAdmin) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => context.push('/hotels/$hotelId/rooms/${room.id}/edit'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
