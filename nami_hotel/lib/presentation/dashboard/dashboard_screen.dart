import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/booking_providers.dart';
import '../../core/providers/room_providers.dart';
import '../../domain/entities/booking_status.dart';
import '../../domain/entities/room_status.dart';
import 'widgets/earnings_chart.dart';
import 'widgets/kpi_card.dart';
import 'widgets/room_grid.dart';

class DashboardScreen extends ConsumerWidget {
  final String hotelId;

  const DashboardScreen({super.key, required this.hotelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final roomsAsync = ref.watch(roomsProvider(hotelId));
    final bookingsAsync = ref.watch(bookingsProvider(hotelId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(roomsProvider(hotelId).notifier).refresh();
              ref.read(bookingsProvider(hotelId).notifier).refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(roomsProvider(hotelId).notifier).refresh(),
            ref.read(bookingsProvider(hotelId).notifier).refresh(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Key Performance Indicators',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // KPIs
              roomsAsync.when(
                data: (rooms) => bookingsAsync.when(
                  data: (bookings) {
                    final today = DateTime.now();
                    final thisMonth = DateTime(today.year, today.month);
                    
                    // Occupancy
                    final totalRooms = rooms.length;
                    final occupiedRooms = rooms.where((r) => r.status == RoomStatus.occupied).length;
                    final occupancyRate = totalRooms == 0 ? 0.0 : (occupiedRooms / totalRooms) * 100;
                    
                    // Available Rooms
                    final availableRooms = rooms.where((r) => r.status == RoomStatus.available).length;
                    
                    // Pending Checkouts Today
                    final pendingCheckouts = bookings.where((b) {
                      final isCheckingOutToday = b.checkOut.year == today.year && 
                                                 b.checkOut.month == today.month && 
                                                 b.checkOut.day == today.day;
                      return isCheckingOutToday && (b.status == BookingStatus.confirmed);
                    }).length;
                    
                    // Monthly Revenue
                    final monthlyRevenue = bookings.where((b) {
                      if (b.status != BookingStatus.checkedOut || b.actualCheckOut == null) return false;
                      return b.actualCheckOut!.year == thisMonth.year && b.actualCheckOut!.month == thisMonth.month;
                    }).fold(0.0, (sum, b) => sum + b.totalAmount);

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        KPICard(
                          title: "Today's Occupancy",
                          value: '${occupancyRate.toStringAsFixed(1)}%',
                          icon: Icons.pie_chart_rounded,
                          color: colorScheme.primary,
                        ),
                        KPICard(
                          title: 'Available Rooms',
                          value: availableRooms.toString(),
                          icon: Icons.meeting_room_rounded,
                          color: colorScheme.secondary,
                        ),
                        KPICard(
                          title: 'Pending Checkouts',
                          value: pendingCheckouts.toString(),
                          subtitle: 'Due today',
                          icon: Icons.logout_rounded,
                          color: colorScheme.tertiary,
                        ),
                        KPICard(
                          title: 'Monthly Revenue',
                          value: '₹${monthlyRevenue.toStringAsFixed(0)}',
                          subtitle: 'This month',
                          icon: Icons.attach_money_rounded,
                          color: Colors.green,
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading bookings: $e'),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading rooms: $e'),
              ),
              
              const SizedBox(height: 32),
              Text(
                'Revenue Trends (6 Months)',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: bookingsAsync.when(
                    data: (bookings) => EarningsChart(bookings: bookings),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading chart: $e'),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              Text(
                'Room Occupancy Grid',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              roomsAsync.when(
                data: (rooms) => RoomGrid(rooms: rooms),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading grid: $e'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
