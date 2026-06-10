import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/item_providers.dart';
import '../../domain/entities/booking_item.dart';
import '../../domain/entities/item_catalogue.dart';

class AddItemSheet extends ConsumerStatefulWidget {
  final String hotelId;
  final String bookingId;

  const AddItemSheet({super.key, required this.hotelId, required this.bookingId});

  @override
  ConsumerState<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<AddItemSheet> {
  ItemCatalogue? _selectedCatalogueItem;
  late final FormGroup _form;

  @override
  void initState() {
    super.initState();
    _form = FormGroup({
      'quantity': FormControl<int>(value: 1, validators: [Validators.required, Validators.min(1)]),
      'unitPrice': FormControl<double>(value: 0.0, validators: [Validators.required, Validators.min(0)]),
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalogueAsync = ref.watch(itemCatalogueProvider(widget.hotelId));

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add Item to Tab',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            catalogueAsync.when(
              data: (items) {
                final activeItems = items.where((i) => i.isActive).toList();
                if (activeItems.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('No active items available.')),
                  );
                }

                // Group by category for a nice dropdown or we can just use a simple dropdown
                return ReactiveForm(
                  formGroup: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<ItemCatalogue>(
                        decoration: const InputDecoration(labelText: 'Select Item'),
                        initialValue: _selectedCatalogueItem,
                        items: activeItems.map((item) {
                          return DropdownMenuItem(
                            value: item,
                            child: Text('${item.name} (₹${item.defaultPrice.toStringAsFixed(2)})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCatalogueItem = val;
                            if (val != null) {
                              _form.control('unitPrice').value = val.defaultPrice;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ReactiveTextField<int>(
                              formControlName: 'quantity',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Quantity'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ReactiveTextField<double>(
                              formControlName: 'unitPrice',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Unit Price (₹)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: _selectedCatalogueItem == null
                            ? null
                            : () async {
                                if (_form.invalid) return;
                                
                                final currentUser = ref.read(currentUserProvider);
                                if (currentUser == null) return;

                                final value = _form.value;
                                
                                final bookingItem = BookingItem(
                                  id: '', // Will be generated or handled by Appwrite
                                  bookingId: widget.bookingId,
                                  hotelId: widget.hotelId,
                                  itemId: _selectedCatalogueItem!.id,
                                  itemName: _selectedCatalogueItem!.name,
                                  unitPrice: value['unitPrice'] as double,
                                  quantity: value['quantity'] as int,
                                  addedByUserId: currentUser.userId,
                                  addedAt: DateTime.now(),
                                );

                                await ref.read(bookingItemsProvider(widget.bookingId).notifier).createBookingItem(bookingItem);
                                if (!context.mounted) return;
                                Navigator.pop(context);
                              },
                        child: const Text('Add to Tab'),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }
}
