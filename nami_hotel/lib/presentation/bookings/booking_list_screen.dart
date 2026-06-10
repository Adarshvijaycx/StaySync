import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers/booking_providers.dart';
import '../../core/providers/customer_providers.dart';
import '../../core/providers/hotel_providers.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/booking_status.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/error_state_widget.dart';

class BookingListScreen extends ConsumerStatefulWidget {
  final String hotelId;

  const BookingListScreen({super.key, required this.hotelId});

  @override
  ConsumerState<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends ConsumerState<BookingListScreen> {
  BookingStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider(widget.hotelId));
    final hotel = ref.watch(hotelProvider(widget.hotelId));

    return Scaffold(
      appBar: AppBar(
        title: Text(hotel != null ? '${hotel.name} - Bookings' : 'Bookings'),
        actions: [
          PopupMenuButton<BookingStatus?>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter by Status',
            onSelected: (status) {
              setState(() => _statusFilter = status);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All'),
              ),
              ...BookingStatus.values.map(
                (status) => PopupMenuItem(
                  value: status,
                  child: Text(status.displayName),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(bookingsProvider(widget.hotelId).notifier).refresh();
              ref.read(customersProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          final filteredBookings = _statusFilter == null
              ? bookings
              : bookings.where((b) => b.status == _statusFilter).toList();

          if (filteredBookings.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.book_online_rounded,
              title: 'No bookings found',
              subtitle: 'There are no bookings matching your criteria.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(bookingsProvider(widget.hotelId).notifier).refresh();
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredBookings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final booking = filteredBookings[index];
                return _BookingCard(booking: booking);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorStateWidget(
          errorMessage: error.toString(),
          onRetry: () {
            ref.read(bookingsProvider(widget.hotelId).notifier).refresh();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/hotels/${widget.hotelId}/bookings/new'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  final Booking booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final customer = ref.watch(customerProvider(booking.customerId));
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/hotels/${booking.hotelId}/bookings/${booking.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    customer?.name ?? 'Loading Customer...',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: booking.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: booking.status.color),
                    ),
                    child: Text(
                      booking.status.displayName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: booking.status.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.login_rounded, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(booking.checkIn),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.logout_rounded, size: 16, color: colorScheme.error),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(booking.checkOut),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Room ID: ${booking.roomId.substring(0, 8)}...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '\$${booking.totalAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
