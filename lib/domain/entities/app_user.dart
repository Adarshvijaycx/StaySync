/// User roles within the hotel management system.
enum UserRole {
  admin,
  manager,
  staff;

  /// Parse a role string (case-insensitive) to [UserRole].
  /// Returns `null` if the string doesn't match any role.
  static UserRole? fromString(String? value) {
    if (value == null) return null;
    return UserRole.values.cast<UserRole?>().firstWhere(
      (role) => role!.name == value.toLowerCase(),
      orElse: () => null,
    );
  }

  /// Display name for UI.
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.manager:
        return 'Manager';
      case UserRole.staff:
        return 'Staff';
    }
  }
}

/// Represents an authenticated user in the system.
///
/// Maps to the `users` collection in Appwrite.
class AppUser {
  final String userId;
  final String name;
  final String email;
  final UserRole role;
  final String? hotelId;
  final bool isActive;

  const AppUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.hotelId,
    this.isActive = true,
  });

  /// Create from Appwrite document data map.
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      userId: map['user_id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      role: UserRole.fromString(map['role'] as String?) ?? UserRole.staff,
      hotelId: map['hotel_id'] as String?,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  /// Convert to map for Appwrite document creation.
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'role': role.name,
      'hotel_id': hotelId,
      'is_active': isActive,
    };
  }

  /// Create a copy with modified fields.
  AppUser copyWith({
    String? userId,
    String? name,
    String? email,
    UserRole? role,
    String? hotelId,
    bool? isActive,
  }) {
    return AppUser(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      hotelId: hotelId ?? this.hotelId,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() =>
      'AppUser(userId: $userId, name: $name, role: ${role.displayName})';
}
