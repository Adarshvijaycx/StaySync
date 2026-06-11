import 'package:equatable/equatable.dart';

/// Represents an item in the hotel's catalogue (e.g., Water Bottle, Breakfast).
class ItemCatalogue extends Equatable {
  final String id;
  final String hotelId;
  final String name;
  final String category;
  final double defaultPrice;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ItemCatalogue({
    required this.id,
    required this.hotelId,
    required this.name,
    required this.category,
    required this.defaultPrice,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ItemCatalogue.empty({required String hotelId}) {
    return ItemCatalogue(
      id: '',
      hotelId: hotelId,
      name: '',
      category: '',
      defaultPrice: 0.0,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory ItemCatalogue.fromMap(Map<String, dynamic> map) {
    return ItemCatalogue(
      id: map['id'] ?? map[r'$id'] ?? '',
      hotelId: map['hotel_id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      defaultPrice: (map['default_price'] as num?)?.toDouble() 
          ?? (map['price'] as num?)?.toDouble() 
          ?? 0.0,
      isActive: map['is_active'] == 1 || map['is_active'] == true 
          || map['is_available'] == 1 || map['is_available'] == true,
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
      'name': name,
      'category': category,
      'default_price': defaultPrice,
      'is_active': isActive ? 1 : 0, // SQLite boolean compatibility
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Only includes fields that exist in the Appwrite collection schema.
  Map<String, dynamic> toAppwriteMap() {
    return {
      'hotel_id': hotelId,
      'name': name,
      'category': category,
      'price': defaultPrice,
      'is_available': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ItemCatalogue copyWith({
    String? id,
    String? hotelId,
    String? name,
    String? category,
    double? defaultPrice,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ItemCatalogue(
      id: id ?? this.id,
      hotelId: hotelId ?? this.hotelId,
      name: name ?? this.name,
      category: category ?? this.category,
      defaultPrice: defaultPrice ?? this.defaultPrice,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        hotelId,
        name,
        category,
        defaultPrice,
        isActive,
        createdAt,
        updatedAt,
      ];
}
