import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers/booking_providers.dart';
import '../../core/providers/customer_providers.dart';
import '../../core/providers/item_providers.dart';
import '../../domain/entities/booking_status.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/error_state_widget.dart';
import '../items/add_item_sheet.dart';
import 'checkout_sheet.dart';

class BookingDetailScreen extends ConsumerWidget {
  final String hotelId;
  final String bookingId;

  const BookingDetailScreen({
    super.key,
    required this.hotelId,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(bookingProvider((hotelId: hotelId, bookingId: bookingId)));
    
    if (booking == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final customer = ref.watch(customerProvider(booking.customerId));
    final tabItemsAsync = ref.watch(bookingItemsProvider(bookingId));
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        actions: [
          if (booking.status != BookingStatus.checkedOut && booking.status != BookingStatus.cancelled)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Edit Booking',
              onPressed: () => context.go('/hotels/$hotelId/bookings/$bookingId/edit'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: booking.status.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: booking.status.color),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: booking.status.color),
                  const SizedBox(width: 12),
                  Text(
                    'Status: ${booking.status.displayName}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: booking.status.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Guest Info Card
            Text('Guest Information', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: customer == null
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DetailRow('Name', customer.name),
                          _DetailRow('Age', '${customer.age} years'),
                          _DetailRow('Phone', customer.phone),
                          if (customer.email != null) _DetailRow('Email', customer.email!),
                          _DetailRow('Address', customer.address),
                          _DetailRow('ID Proof', customer.idProofType.displayName),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Stay Info Card
            Text('Stay Details', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow('Check-in', dateFormat.format(booking.checkIn)),
                    _DetailRow('Expected Check-out', dateFormat.format(booking.checkOut)),
                    if (booking.actualCheckOut != null)
                      _DetailRow('Actual Check-out', dateFormat.format(booking.actualCheckOut!)),
                    _DetailRow('Guests', '${booking.guestsCount} Person(s)'),
                    _DetailRow('Room ID', booking.roomId),
                    const Divider(height: 24),
                    _DetailRow('Payment Mode', booking.paymentMode.displayName),
                    _DetailRow(
                      'Total Amount',
                      '\$${booking.totalAmount.toStringAsFixed(2)}',
                      valueStyle: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Guest Tab Card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Guest Tab', style: theme.textTheme.titleLarge),
                if (booking.status == BookingStatus.confirmed)
                  TextButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => AddItemSheet(hotelId: hotelId, bookingId: bookingId),
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Item'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: tabItemsAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const EmptyStateWidget(
                        icon: Icons.receipt_long_rounded,
                        title: 'Tab is empty',
                        subtitle: 'No items added to tab yet.',
                      );
                    }

                    double tabTotal = 0;
                    for (var item in items) {
                      tabTotal += item.totalPrice;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.itemName, style: theme.textTheme.titleMedium),
                                    Text('${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)}', style: theme.textTheme.bodySmall),
                                  ],
                                ),
                              ),
                              Text('\$${item.totalPrice.toStringAsFixed(2)}', style: theme.textTheme.titleMedium),
                              // Manager could delete, but let's keep it simple: anyone can delete if status is confirmed
                              if (booking.status == BookingStatus.confirmed)
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error, size: 20),
                                  onPressed: () {
                                    ref.read(bookingItemsProvider(bookingId).notifier).deleteBookingItem(item.id);
                                  },
                                ),
                            ],
                          ),
                        )),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tab Total', style: theme.textTheme.titleMedium),
                            Text('\$${tabTotal.toStringAsFixed(2)}', style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            )),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => ErrorStateWidget(
                    errorMessage: error.toString(),
                    onRetry: () => ref.read(bookingItemsProvider(bookingId).notifier).refresh(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Actions
            if (booking.status == BookingStatus.confirmed)
              FilledButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => CheckoutSheet(booking: booking),
                  );
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Process Checkout'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _DetailRow(this.label, this.value, {this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ?? Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
