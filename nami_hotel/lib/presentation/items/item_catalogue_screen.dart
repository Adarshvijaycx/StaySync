import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../../core/providers/item_providers.dart';
import '../../domain/entities/item_catalogue.dart';

class ItemCatalogueScreen extends ConsumerWidget {
  final String hotelId;

  const ItemCatalogueScreen({super.key, required this.hotelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogueAsync = ref.watch(itemCatalogueProvider(hotelId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Catalogue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(itemCatalogueProvider(hotelId).notifier).refresh(),
          ),
        ],
      ),
      body: catalogueAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No items in catalogue.'));
          }

          // Group by category
          final Map<String, List<ItemCatalogue>> grouped = {};
          for (final item in items) {
            grouped.putIfAbsent(item.category, () => []).add(item);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final category = grouped.keys.elementAt(index);
              final categoryItems = grouped[category]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      category,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                  ...categoryItems.map((item) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(item.name, style: TextStyle(
                            decoration: item.isActive ? null : TextDecoration.lineThrough,
                            color: item.isActive ? null : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          )),
                          subtitle: Text('\$${item.defaultPrice.toStringAsFixed(2)}'),
                          trailing: Switch(
                            value: item.isActive,
                            onChanged: (val) {
                              ref.read(itemCatalogueProvider(hotelId).notifier).updateItem(item.copyWith(isActive: val));
                            },
                          ),
                          onTap: () => _showItemForm(context, ref, item),
                        ),
                      )),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemForm(context, ref, null),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showItemForm(BuildContext context, WidgetRef ref, ItemCatalogue? existingItem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: _ItemForm(hotelId: hotelId, existingItem: existingItem),
        );
      },
    );
  }
}

class _ItemForm extends ConsumerStatefulWidget {
  final String hotelId;
  final ItemCatalogue? existingItem;

  const _ItemForm({required this.hotelId, this.existingItem});

  @override
  ConsumerState<_ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends ConsumerState<_ItemForm> {
  late final FormGroup _form;

  @override
  void initState() {
    super.initState();
    _form = FormGroup({
      'name': FormControl<String>(
        value: widget.existingItem?.name,
        validators: [Validators.required],
      ),
      'category': FormControl<String>(
        value: widget.existingItem?.category ?? 'Food & Beverage',
        validators: [Validators.required],
      ),
      'defaultPrice': FormControl<double>(
        value: widget.existingItem?.defaultPrice ?? 0.0,
        validators: [Validators.required, Validators.min(0)],
      ),
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existingItem == null ? 'Add Item' : 'Edit Item',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ReactiveForm(
            formGroup: _form,
            child: Column(
              children: [
                ReactiveTextField<String>(
                  formControlName: 'name',
                  decoration: const InputDecoration(labelText: 'Item Name'),
                ),
                const SizedBox(height: 16),
                ReactiveTextField<String>(
                  formControlName: 'category',
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    helperText: 'e.g., Food & Beverage, Laundry, Service',
                  ),
                ),
                const SizedBox(height: 16),
                ReactiveTextField<double>(
                  formControlName: 'defaultPrice',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Default Price (\$)'),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () async {
                    if (_form.invalid) {
                      _form.markAllAsTouched();
                      return;
                    }
                    final value = _form.value;
                    if (widget.existingItem == null) {
                      final item = ItemCatalogue.empty(hotelId: widget.hotelId).copyWith(
                        name: value['name'] as String,
                        category: value['category'] as String,
                        defaultPrice: value['defaultPrice'] as double,
                      );
                      await ref.read(itemCatalogueProvider(widget.hotelId).notifier).createItem(item);
                    } else {
                      final item = widget.existingItem!.copyWith(
                        name: value['name'] as String,
                        category: value['category'] as String,
                        defaultPrice: value['defaultPrice'] as double,
                      );
                      await ref.read(itemCatalogueProvider(widget.hotelId).notifier).updateItem(item);
                    }
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: Text(widget.existingItem == null ? 'Add' : 'Save'),
                ),
                if (widget.existingItem != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      await ref.read(itemCatalogueProvider(widget.hotelId).notifier).deleteItem(widget.existingItem!.id);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                    child: const Text('Delete'),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
