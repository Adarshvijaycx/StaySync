/// Application-wide constants for business rules and defaults.
class AppConstants {
  static const String appName = 'Nami Hotel';

  // Default check-in / check-out times
  static const int defaultCheckInHour  = 12; // 12:00 PM
  static const int defaultCheckOutHour = 11; // 11:00 AM
  static const int defaultStayDays     = 1;

  // Image compression settings
  static const int maxImageSizeKB = 500;
  static const int imageQuality   = 75; // percent

  // ID Proof types
  static const List<String> idProofTypes = [
    'Aadhaar Card',
    'PAN Card',
    'Government ID',
  ];

  // Payment modes
  static const List<String> paymentModes = [
    'Cash',
    'Card',
    'UPI',
    'Advance',
  ];

  // Room types
  static const List<String> roomTypes = [
    'Single',
    'Double',
    'Suite',
  ];

  // Room status values
  static const List<String> roomStatuses = [
    'Available',
    'Occupied',
    'Maintenance',
  ];

  // Booking status values
  static const List<String> bookingStatuses = [
    'Confirmed',
    'Checked Out',
    'Cancelled',
  ];

  // User roles
  static const List<String> userRoles = [
    'Admin',
    'Manager',
    'Staff',
  ];
}
