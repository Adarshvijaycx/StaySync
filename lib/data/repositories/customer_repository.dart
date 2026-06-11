import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/customer.dart';
import '../datasources/local/customer_local_datasource.dart';
import '../datasources/remote/customer_remote_datasource.dart';

class CustomerRepository {
  final CustomerLocalDataSource _localDataSource;
  final CustomerRemoteDataSource _remoteDataSource;

  CustomerRepository({
    required this._localDataSource,
    required this._remoteDataSource,
  });

  Future<List<Customer>> getCustomers({bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        final remoteData = await _remoteDataSource.getCustomers();
        await _localDataSource.clearAll();
        await _localDataSource.saveCustomers(remoteData);
        return remoteData;
      }

      final localData = await _localDataSource.getCustomers();
      if (localData.isNotEmpty) {
        _syncInBackground();
        return localData;
      }

      final remoteData = await _remoteDataSource.getCustomers();
      await _localDataSource.saveCustomers(remoteData);
      return remoteData;
    } on AppwriteException {
      return await _localDataSource.getCustomers();
    } catch (e) {
      return await _localDataSource.getCustomers();
    }
  }

  Future<void> _syncInBackground() async {
    try {
      final remoteData = await _remoteDataSource.getCustomers();
      await _localDataSource.clearAll();
      await _localDataSource.saveCustomers(remoteData);
    } catch (_) {}
  }

  Future<Customer> createCustomer(Customer customer) async {
    final remoteCustomer = await _remoteDataSource.createCustomer(customer);
    // Appwrite doesn't store all fields (like dob, address, etc.), so we merge the ID 
    // and timestamps from the Appwrite response back into the complete original object.
    final completeCustomer = customer.copyWith(
      id: remoteCustomer.id,
      createdAt: remoteCustomer.createdAt,
      updatedAt: remoteCustomer.updatedAt,
    );
    await _localDataSource.saveCustomer(completeCustomer);
    return completeCustomer;
  }

  Future<Customer> updateCustomer(Customer customer) async {
    final updated = customer.copyWith(updatedAt: DateTime.now());
    final remoteCustomer = await _remoteDataSource.updateCustomer(updated);
    final completeCustomer = updated.copyWith(
      id: remoteCustomer.id,
      createdAt: remoteCustomer.createdAt,
      updatedAt: remoteCustomer.updatedAt,
    );
    await _localDataSource.saveCustomer(completeCustomer);
    return completeCustomer;
  }

  Future<String> uploadFile(String bucketId, String filePath) async {
    // In a production app, add flutter_image_compress logic here 
    // before uploading to save bandwidth.
    return await _remoteDataSource.uploadFile(bucketId, filePath);
  }
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(
    localDataSource: ref.watch(customerLocalDataSourceProvider),
    remoteDataSource: ref.watch(customerRemoteDataSourceProvider),
  );
});
