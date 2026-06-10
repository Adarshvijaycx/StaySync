import 'package:equatable/equatable.dart';

/// Represents an item added to a guest's booking tab.
class BookingItem extends Equatable {
  final String id;
  final String bookingId;
  final String hotelId;
  final String itemId;
  final String itemName;
  final double unitPrice;
  final int quantity;
  final String addedByUserId;
  final DateTime addedAt;

  const BookingItem({
    required this.id,
    required this.bookingId,
    required this.hotelId,
    required this.itemId,
    required this.itemName,
    required this.unitPrice,
    required this.quantity,
    required this.addedByUserId,
    required this.addedAt,
  });

  factory BookingItem.fromMap(Map<String, dynamic> map) {
    return BookingItem(
      id: map['id'] ?? map['\$id'] ?? '',
      bookingId: map['booking_id'] ?? '',
      hotelId: map['hotel_id'] ?? '',
      itemId: map['item_id'] ?? '',
      itemName: map['item_name'] ?? '',
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] ?? 1,
      addedByUserId: map['added_by_user_id'] ?? '',
      addedAt: map['added_at'] != null
          ? DateTime.parse(map['added_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'booking_id': bookingId,
      'hotel_id': hotelId,
      'item_id': itemId,
      'item_name': itemName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'added_by_user_id': addedByUserId,
      'added_at': addedAt.toIso8601String(),
    };
  }

  double get totalPrice => unitPrice * quantity;

  BookingItem copyWith({
    String? id,
    String? bookingId,
    String? hotelId,
    String? itemId,
    String? itemName,
    double? unitPrice,
    int? quantity,
    String? addedByUserId,
    DateTime? addedAt,
  }) {
    return BookingItem(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      hotelId: hotelId ?? this.hotelId,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      addedByUserId: addedByUserId ?? this.addedByUserId,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookingId,
        hotelId,
        itemId,
        itemName,
        unitPrice,
        quantity,
        addedByUserId,
        addedAt,
      ];
}
