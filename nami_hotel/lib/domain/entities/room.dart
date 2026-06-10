import 'package:equatable/equatable.dart';
import 'room_status.dart';
import 'room_type.dart';

/// Represents a Room in a specific Hotel.
class Room extends Equatable {
  final String id;
  final String hotelId;
  final String roomNumber;
  final RoomType type;
  final double rate;
  final RoomStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Room({
    required this.id,
    required this.hotelId,
    required this.roomNumber,
    required this.type,
    required this.rate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory to create an empty/new Room
  factory Room.empty({required String hotelId}) => Room(
        id: '',
        hotelId: hotelId,
        roomNumber: '',
        type: RoomType.standard,
        rate: 0.0,
        status: RoomStatus.available,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'] ?? map['\$id'] ?? '',
      hotelId: map['hotel_id'] ?? '',
      roomNumber: map['room_number'] ?? '',
      type: RoomType.fromString(map['type'] ?? ''),
      rate: (map['rate'] as num?)?.toDouble() ?? 0.0,
      status: RoomStatus.fromString(map['status'] ?? ''),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hotel_id': hotelId,
      'room_number': roomNumber,
      'type': type.name,
      'rate': rate,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Room copyWith({
    String? id,
    String? hotelId,
    String? roomNumber,
    RoomType? type,
    double? rate,
    RoomStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Room(
      id: id ?? this.id,
      hotelId: hotelId ?? this.hotelId,
      roomNumber: roomNumber ?? this.roomNumber,
      type: type ?? this.type,
      rate: rate ?? this.rate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        hotelId,
        roomNumber,
        type,
        rate,
        status,
        createdAt,
        updatedAt,
      ];
}
