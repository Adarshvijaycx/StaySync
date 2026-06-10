import 'package:flutter/material.dart';

/// Represents the status of a booking.
enum BookingStatus {
  confirmed,
  checkedOut,
  cancelled;

  static BookingStatus fromString(String value) {
    return BookingStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => BookingStatus.confirmed,
    );
  }

  String get displayName {
    switch (this) {
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.checkedOut:
        return 'Checked Out';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.checkedOut:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }
}
