import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/appwrite_constants.dart';
import '../../domain/entities/app_user.dart';
import 'appwrite_client.dart';

/// Remote data source for authentication operations via Appwrite.
///
/// Handles session creation/destruction and user profile fetching
/// from the `users` collection.
class AuthRemoteDataSource {
  final Account _account;
  final Databases _databases;

  AuthRemoteDataSource({
    required this._account,
    required this._databases,
  });

  /// Sign in with email and password.
  /// Returns the Appwrite session.
  Future<models.Session> login({
    required String email,
    required String password,
  }) async {
    return await _account.createEmailPasswordSession(
      email: email,
      password: password,
    );
  }

  /// Get the current authenticated session, or null if none.
  Future<models.Session?> getCurrentSession() async {
    try {
      return await _account.getSession(sessionId: 'current');
    } on AppwriteException {
      return null;
    }
  }

  /// Get the currently logged-in Appwrite account.
  Future<models.User> getAccount() async {
    return await _account.get();
  }

  /// Fetch the user's profile from the `users` collection.
  /// This contains the role, assigned hotel, and active status.
  Future<AppUser?> getUserProfile(String userId) async {
    try {
      final docs = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.limit(1),
        ],
      );

      if (docs.documents.isEmpty) return null;
      return AppUser.fromMap(docs.documents.first.data);
    } on AppwriteException {
      return null;
    }
  }

  /// Destroy the current session (logout).
  Future<void> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } on AppwriteException {
      // Session may already be expired — ignore
    }
  }

  /// Create a new user account (Admin only).
  Future<models.User> createUser({
    required String email,
    required String password,
    required String name,
  }) async {
    return await _account.create(
      userId: 'unique()',
      email: email,
      password: password,
      name: name,
    );
  }

  /// Create a user profile document in the `users` collection.
  Future<void> createUserProfile(AppUser user) async {
    await _databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.usersCollection,
      documentId: user.userId,
      data: user.toMap(),
    );
  }
}

/// Provider for the auth remote data source.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(
    account: ref.watch(appwriteAccountProvider),
    databases: ref.watch(appwriteDatabasesProvider),
  );
});
