import 'package:equatable/equatable.dart';
import 'id_proof_type.dart';

/// Represents a guest/customer in the system.
class Customer extends Equatable {
  final String id;
  final String hotelId;
  final String name;
  final DateTime dob;
  final String phone;
  final String? email;
  final String? parentName;
  final String address;
  final String pincode;
  final IdProofType idProofType;
  final String idProofNumber;
  final String? idProofUrl;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    required this.id,
    required this.hotelId,
    required this.name,
    required this.dob,
    required this.phone,
    this.email,
    this.parentName,
    required this.address,
    required this.pincode,
    required this.idProofType,
    required this.idProofNumber,
    this.idProofUrl,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.empty() => Customer(
        id: '',
        hotelId: '',
        name: '',
        dob: DateTime.now().subtract(const Duration(days: 365 * 18)), // default 18y old
        phone: '',
        address: '',
        pincode: '',
        idProofType: IdProofType.aadhaar,
        idProofNumber: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] ?? map[r'$id'] ?? '',
      hotelId: map['hotel_id'] ?? '',
      name: map['name'] ?? '',
      dob: map['dob'] != null ? DateTime.parse(map['dob']) : DateTime.now(),
      phone: map['phone'] ?? '',
      email: map['email'],
      parentName: map['parent_name'],
      address: map['address'] ?? '',
      pincode: map['pincode'] ?? '',
      idProofType: IdProofType.fromString(map['id_proof_type'] ?? ''),
      idProofNumber: map['id_proof_number'] ?? '',
      idProofUrl: map['id_proof_url'],
      photoUrl: map['photo_url'],
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
      'dob': dob.toIso8601String(),
      'phone': phone,
      'email': email,
      'parent_name': parentName,
      'address': address,
      'pincode': pincode,
      'id_proof_type': idProofType.name,
      'id_proof_number': idProofNumber,
      'id_proof_url': idProofUrl,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Only includes fields that exist in the Appwrite collection schema.
  /// Fields like dob, parent_name, address, pincode are stored locally only.
  Map<String, dynamic> toAppwriteMap() {
    return {
      'hotel_id': hotelId,
      'name': name,
      'phone': phone,
      'email': email,
      'id_proof_type': idProofType.name,
      'id_proof_number': idProofNumber,
      'id_proof_url': idProofUrl,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Customer copyWith({
    String? id,
    String? hotelId,
    String? name,
    DateTime? dob,
    String? phone,
    String? email,
    String? parentName,
    String? address,
    String? pincode,
    IdProofType? idProofType,
    String? idProofNumber,
    String? idProofUrl,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      hotelId: hotelId ?? this.hotelId,
      name: name ?? this.name,
      dob: dob ?? this.dob,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      parentName: parentName ?? this.parentName,
      address: address ?? this.address,
      pincode: pincode ?? this.pincode,
      idProofType: idProofType ?? this.idProofType,
      idProofNumber: idProofNumber ?? this.idProofNumber,
      idProofUrl: idProofUrl ?? this.idProofUrl,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get age {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  @override
  List<Object?> get props => [
        id,
        hotelId,
        name,
        dob,
        phone,
        email,
        parentName,
        address,
        pincode,
        idProofType,
        idProofNumber,
        idProofUrl,
        photoUrl,
        createdAt,
        updatedAt,
      ];
}
