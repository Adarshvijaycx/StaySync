/// Represents the category/type of a hotel room.
enum RoomType {
  standard,
  deluxe,
  suite;

  /// Parse a string (e.g. from DB) into a [RoomType].
  static RoomType fromString(String value) {
    return RoomType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => RoomType.standard,
    );
  }

  /// Display name for UI.
  String get displayName {
    switch (this) {
      case RoomType.standard:
        return 'Standard';
      case RoomType.deluxe:
        return 'Deluxe';
      case RoomType.suite:
        return 'Suite';
    }
  }
}
