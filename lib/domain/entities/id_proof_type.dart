/// Represents the type of ID proof provided by a guest.
enum IdProofType {
  aadhaar,
  passport,
  drivingLicense,
  voterId,
  other;

  static IdProofType fromString(String value) {
    return IdProofType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => IdProofType.other,
    );
  }

  String get displayName {
    switch (this) {
      case IdProofType.aadhaar:
        return 'Aadhaar Card';
      case IdProofType.passport:
        return 'Passport';
      case IdProofType.drivingLicense:
        return 'Driving License';
      case IdProofType.voterId:
        return 'Voter ID';
      case IdProofType.other:
        return 'Other';
    }
  }
}
