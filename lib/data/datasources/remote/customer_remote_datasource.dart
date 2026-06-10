import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/appwrite_constants.dart';
import '../../../domain/entities/customer.dart';
import '../appwrite_client.dart';

class CustomerRemoteDataSource {
  final Databases _databases;
  final Storage _storage;

  CustomerRemoteDataSource({
    required this._databases,
    required this._storage,
  });

  Future<List<Customer>> getCustomers() async {
    final response = await _databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.customersCollection,
    );
    return response.documents.map((doc) => Customer.fromMap(doc.data)).toList();
  }

  Future<Customer> createCustomer(Customer customer) async {
    final response = await _databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.customersCollection,
      documentId: 'unique()',
      data: customer.toMap()..remove('id'),
    );
    return Customer.fromMap(response.data);
  }

  Future<Customer> updateCustomer(Customer customer) async {
    final response = await _databases.updateDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.customersCollection,
      documentId: customer.id,
      data: customer.toMap()..remove('id'),
    );
    return Customer.fromMap(response.data);
  }

  /// Uploads a file to a specific Appwrite storage bucket.
  Future<String> uploadFile(String bucketId, String filePath) async {
    final file = await _storage.createFile(
      bucketId: bucketId,
      fileId: 'unique()',
      file: InputFile.fromPath(path: filePath),
    );
    return file.$id;
  }
}

final customerRemoteDataSourceProvider = Provider<CustomerRemoteDataSource>((ref) {
  return CustomerRemoteDataSource(
    databases: ref.watch(appwriteDatabasesProvider),
    storage: ref.watch(appwriteStorageProvider),
  );
});
