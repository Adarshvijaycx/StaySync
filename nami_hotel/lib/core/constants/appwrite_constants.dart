/// Appwrite backend configuration constants.
///
/// Replace placeholder values with your actual Appwrite project credentials.
class AppwriteConstants {
  static const String projectId   = '6a294212001bb4d81b03';   // Extracted from screenshot
  static const String endpoint    = 'https://sgp.cloud.appwrite.io/v1';
  static const String databaseId  = 'nami_hotel_db';

  // Collection IDs (fill as you create them in Appwrite Console)
  static const String hotelsCollection       = 'hotels';
  static const String roomsCollection        = 'rooms';
  static const String bookingsCollection     = 'bookings';
  static const String customersCollection    = 'customers';
  static const String bookingItemsCollection = 'booking_items';
  static const String usersCollection        = 'users';
  static const String itemCatalogueCollection = 'item_catalogue';

  // Storage bucket IDs
  static const String guestPhotosBucket = 'guest_photos';
  static const String idProofsBucket    = 'id_proofs';
}
