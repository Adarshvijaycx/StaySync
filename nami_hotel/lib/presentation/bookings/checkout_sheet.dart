import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/booking_providers.dart';
import '../../core/providers/item_providers.dart';
import '../../core/providers/room_providers.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/booking_status.dart';
import '../../domain/entities/room_status.dart';

class CheckoutSheet extends ConsumerStatefulWidget {
  final Booking booking;

  const CheckoutSheet({super.key, required this.booking});

  @override
  ConsumerState<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<CheckoutSheet> {
  bool _isLoading = false;

  Future<void> _processCheckout(double finalTotal) async {
    setState(() => _isLoading = true);
    try {
      // 1. Update Booking
      final checkoutTime = DateTime.now();
      final updatedBooking = widget.booking.copyWith(
        status: BookingStatus.checkedOut,
        actualCheckOut: checkoutTime,
        totalAmount: finalTotal,
      );
      await ref.read(bookingsProvider(widget.booking.hotelId).notifier).updateBooking(updatedBooking);

      // 2. Update Room Status
      final roomsState = ref.read(roomsProvider(widget.booking.hotelId));
      final room = roomsState.value?.firstWhere((r) => r.id == widget.booking.roomId);
      
      if (room != null) {
        final updatedRoom = room.copyWith(status: RoomStatus.cleaning); // Set to cleaning after checkout
        await ref.read(roomsProvider(widget.booking.hotelId).notifier).updateRoom(updatedRoom);
      }

      if (mounted) {
        context.pop(); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checkout successful. Room marked for cleaning.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during checkout: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roomsState = ref.watch(roomsProvider(widget.booking.hotelId));
    final tabItemsState = ref.watch(bookingItemsProvider(widget.booking.id));

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
              'Process Checkout',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Calculate Bill
            roomsState.when(
              data: (rooms) {
                final room = rooms.firstWhere((r) => r.id == widget.booking.roomId);
                // Calculate nights (minimum 1)
                final checkoutDate = DateTime.now();
                int nights = checkoutDate.difference(widget.booking.checkIn).inDays;
                if (nights <= 0) nights = 1;
                final roomCharges = nights * room.rate;

                return tabItemsState.when(
                  data: (items) {
                    double tabTotal = 0;
                    for (var item in items) {
                      tabTotal += item.totalPrice;
                    }
                    final grandTotal = roomCharges + tabTotal;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Bill Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _BillRow('Room Charges (${nights}x \$${room.rate.toStringAsFixed(2)})', roomCharges),
                        _BillRow('Guest Tab Charges', tabTotal),
                        const Divider(height: 24),
                        _BillRow('Grand Total', grandTotal, isTotal: true),
                        const SizedBox(height: 32),
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else ...[
                          FilledButton(
                            onPressed: () => _processCheckout(grandTotal),
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.error,
                              foregroundColor: theme.colorScheme.onError,
                              minimumSize: const Size.fromHeight(50),
                            ),
                            child: const Text('Confirm Checkout & Print Bill'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => context.pop(),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading tab items: $e'),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading room data: $e'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isTotal;

  const _BillRow(this.label, this.amount, {this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
      color: isTotal ? Theme.of(context).colorScheme.primary : null,
      fontSize: isTotal ? 18 : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('\$${amount.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
