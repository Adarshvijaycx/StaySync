import 'package:flutter/material.dart';
import '../../../domain/entities/room.dart';
import '../../../domain/entities/room_status.dart';

class RoomGrid extends StatelessWidget {
  final List<Room> rooms;

  const RoomGrid({super.key, required this.rooms});

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No rooms available.'),
        ),
      );
    }

    // Sort by room number roughly
    final sortedRooms = List<Room>.from(rooms)
      ..sort((a, b) => a.roomNumber.compareTo(b.roomNumber));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: sortedRooms.length,
      itemBuilder: (context, index) {
        final room = sortedRooms[index];
        final color = _getStatusColor(context, room.status);

        return Tooltip(
          message: 'Room ${room.roomNumber}\n${room.type.name}\n${room.status.name}',
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
            ),
            alignment: Alignment.center,
            child: Text(
              room.roomNumber,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(BuildContext context, RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return Colors.green;
      case RoomStatus.occupied:
        return Theme.of(context).colorScheme.error;
      case RoomStatus.cleaning:
        return Colors.orange;
      case RoomStatus.maintenance:
        return Colors.grey;
    }
  }
}
