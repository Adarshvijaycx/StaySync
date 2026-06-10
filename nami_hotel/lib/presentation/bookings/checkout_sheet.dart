import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/booking_providers.dart';
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

  Future<void> _processCheckout() async {
    setState(() => _isLoading = true);
    try {
      // 1. Update Booking
      final checkoutTime = DateTime.now();
      final updatedBooking = widget.booking.copyWith(
        status: BookingStatus.checkedOut,
        actualCheckOut: checkoutTime,
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
            const Text('Confirm checkout for this booking? The room will be marked for cleaning.'),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              FilledButton(
                onPressed: _processCheckout,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Confirm Checkout'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
