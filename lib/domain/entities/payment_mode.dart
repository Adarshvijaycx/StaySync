/// Represents the mode of payment for a booking.
enum PaymentMode {
  cash,
  card,
  upi;

  static PaymentMode fromString(String value) {
    return PaymentMode.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => PaymentMode.cash,
    );
  }

  String get displayName {
    switch (this) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.card:
        return 'Card';
      case PaymentMode.upi:
        return 'UPI';
    }
  }
}
