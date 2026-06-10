import 'package:flutter/material.dart';

/// Represents the physical status of a hotel room.
enum RoomStatus {
  available,
  occupied,
  maintenance,
  cleaning;

  /// Parse a string (e.g. from DB) into a [RoomStatus].
  static RoomStatus fromString(String value) {
    return RoomStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => RoomStatus.maintenance,
    );
  }

  /// Display name for UI.
  String get displayName {
    switch (this) {
      case RoomStatus.available:
        return 'Available';
      case RoomStatus.occupied:
        return 'Occupied';
      case RoomStatus.maintenance:
        return 'Maintenance';
      case RoomStatus.cleaning:
        return 'Cleaning';
    }
  }

  /// Returns a color for the status badge in UI.
  Color get color {
    switch (this) {
      case RoomStatus.available:
        return Colors.green;
      case RoomStatus.occupied:
        return Colors.blue;
      case RoomStatus.maintenance:
        return Colors.red;
      case RoomStatus.cleaning:
        return Colors.orange;
    }
  }
}
