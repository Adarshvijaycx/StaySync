import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/customer_repository.dart';
import '../../domain/entities/customer.dart';

final customersProvider = AsyncNotifierProvider<CustomersNotifier, List<Customer>>(() {
  return CustomersNotifier();
});

class CustomersNotifier extends AsyncNotifier<List<Customer>> {
  late CustomerRepository _repository;

  @override
  Future<List<Customer>> build() async {
    _repository = ref.watch(customerRepositoryProvider);
    return _repository.getCustomers();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getCustomers(forceRefresh: true));
  }

  Future<void> createCustomer(Customer customer) async {
    try {
      final newCustomer = await _repository.createCustomer(customer);
      final currentList = state.value ?? [];
      state = AsyncValue.data([...currentList, newCustomer]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      final updated = await _repository.updateCustomer(customer);
      final currentList = state.value ?? [];
      state = AsyncValue.data([
        for (final c in currentList)
          if (c.id == updated.id) updated else c
      ]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final customerProvider = Provider.family<Customer?, String>((ref, id) {
  final customersState = ref.watch(customersProvider);
  return customersState.maybeWhen(
    data: (customers) => customers.cast<Customer?>().firstWhere(
      (customer) => customer?.id == id,
      orElse: () => null,
    ),
    orElse: () => null,
  );
});
