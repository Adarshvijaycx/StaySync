import 'package:equatable/equatable.dart';

/// Represents a Hotel property in the system.
class Hotel extends Equatable {
  final String id;
  final String name;
  final String address;
  final String contactNumber;
  final String email;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Hotel({
    required this.id,
    required this.name,
    required this.address,
    required this.contactNumber,
    required this.email,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory to create an empty/new Hotel
  factory Hotel.empty() => Hotel(
        id: '',
        name: '',
        address: '',
        contactNumber: '',
        email: '',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  factory Hotel.fromMap(Map<String, dynamic> map) {
    return Hotel(
      id: map['id'] ?? map['\$id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      contactNumber: map['contact_number'] ?? '',
      email: map['email'] ?? '',
      isActive: map['is_active'] == 1 || map['is_active'] == true,
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
      'name': name,
      'address': address,
      'contact_number': contactNumber,
      'email': email,
      'is_active': isActive ? 1 : 0, // SQLite uses integer for boolean
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Hotel copyWith({
    String? id,
    String? name,
    String? address,
    String? contactNumber,
    String? email,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Hotel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        contactNumber,
        email,
        isActive,
        createdAt,
        updatedAt,
      ];
}
