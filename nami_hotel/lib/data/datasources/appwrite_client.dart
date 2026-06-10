import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/appwrite_constants.dart';

/// Singleton Appwrite client configured with project credentials.
///
/// All Appwrite service instances (Account, Databases, Storage) should
/// be created from this client to share the same authenticated session.
final appwriteClientProvider = Provider<Client>((ref) {
  final client = Client()
      .setEndpoint(AppwriteConstants.endpoint)
      .setProject(AppwriteConstants.projectId)
      .setSelfSigned(status: true); // Remove in production

  return client;
});

/// Appwrite Account service for authentication operations.
final appwriteAccountProvider = Provider<Account>((ref) {
  return Account(ref.watch(appwriteClientProvider));
});

/// Appwrite Databases service for collection operations.
final appwriteDatabasesProvider = Provider<Databases>((ref) {
  return Databases(ref.watch(appwriteClientProvider));
});

/// Appwrite Storage service for file operations.
final appwriteStorageProvider = Provider<Storage>((ref) {
  return Storage(ref.watch(appwriteClientProvider));
});

/// Appwrite Realtime service for live subscriptions.
final appwriteRealtimeProvider = Provider<Realtime>((ref) {
  return Realtime(ref.watch(appwriteClientProvider));
});
