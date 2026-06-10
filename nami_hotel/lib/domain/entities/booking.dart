import 'package:equatable/equatable.dart';
import 'booking_status.dart';
import 'payment_mode.dart';

/// Represents a room booking in the system.
class Booking extends Equatable {
  final String id;
  final String hotelId;
  final String roomId;
  final String customerId;
  final String bookedByUserId;
  final DateTime checkIn;
  final DateTime checkOut;
  final DateTime? actualCheckOut;
  final int guestsCount;
  final PaymentMode paymentMode;
  final BookingStatus status;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Booking({
    required this.id,
    required this.hotelId,
    required this.roomId,
    required this.customerId,
    required this.bookedByUserId,
    required this.checkIn,
    required this.checkOut,
    this.actualCheckOut,
    required this.guestsCount,
    required this.paymentMode,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.empty({required String hotelId}) => Booking(
        id: '',
        hotelId: hotelId,
        roomId: '',
        customerId: '',
        bookedByUserId: '',
        checkIn: DateTime.now(),
        checkOut: DateTime.now().add(const Duration(days: 1)),
        guestsCount: 1,
        paymentMode: PaymentMode.cash,
        status: BookingStatus.confirmed,
        totalAmount: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] ?? map['\$id'] ?? '',
      hotelId: map['hotel_id'] ?? '',
      roomId: map['room_id'] ?? '',
      customerId: map['customer_id'] ?? '',
      bookedByUserId: map['booked_by_user_id'] ?? '',
      checkIn: DateTime.parse(map['check_in']),
      checkOut: DateTime.parse(map['check_out']),
      actualCheckOut: map['actual_check_out'] != null
          ? DateTime.parse(map['actual_check_out'])
          : null,
      guestsCount: map['guests_count'] ?? 1,
      paymentMode: PaymentMode.fromString(map['payment_mode'] ?? ''),
      status: BookingStatus.fromString(map['status'] ?? ''),
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
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
      'room_id': roomId,
      'customer_id': customerId,
      'booked_by_user_id': bookedByUserId,
      'check_in': checkIn.toIso8601String(),
      'check_out': checkOut.toIso8601String(),
      'actual_check_out': actualCheckOut?.toIso8601String(),
      'guests_count': guestsCount,
      'payment_mode': paymentMode.name,
      'status': status.name,
      'total_amount': totalAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Booking copyWith({
    String? id,
    String? hotelId,
    String? roomId,
    String? customerId,
    String? bookedByUserId,
    DateTime? checkIn,
    DateTime? checkOut,
    DateTime? actualCheckOut,
    int? guestsCount,
    PaymentMode? paymentMode,
    BookingStatus? status,
    double? totalAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      hotelId: hotelId ?? this.hotelId,
      roomId: roomId ?? this.roomId,
      customerId: customerId ?? this.customerId,
      bookedByUserId: bookedByUserId ?? this.bookedByUserId,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      actualCheckOut: actualCheckOut ?? this.actualCheckOut,
      guestsCount: guestsCount ?? this.guestsCount,
      paymentMode: paymentMode ?? this.paymentMode,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        hotelId,
        roomId,
        customerId,
        bookedByUserId,
        checkIn,
        checkOut,
        actualCheckOut,
        guestsCount,
        paymentMode,
        status,
        totalAmount,
        createdAt,
        updatedAt,
      ];
}
