import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/booking.dart';
import '../../../domain/entities/booking_status.dart';

class EarningsChart extends StatelessWidget {
  final List<Booking> bookings;

  const EarningsChart({super.key, required this.bookings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Filter to only checkedOut bookings and calculate revenue per month
    // We'll show the last 6 months.
    final now = DateTime.now();
    final Map<int, double> monthlyRevenue = {};
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final key = m.year * 100 + m.month;
      monthlyRevenue[key] = 0;
    }

    for (final b in bookings) {
      if (b.status == BookingStatus.checkedOut && b.actualCheckOut != null) {
        final key = b.actualCheckOut!.year * 100 + b.actualCheckOut!.month;
        if (monthlyRevenue.containsKey(key)) {
          monthlyRevenue[key] = monthlyRevenue[key]! + b.totalAmount;
        }
      }
    }

    final sortedKeys = monthlyRevenue.keys.toList()..sort();
    
    double maxY = 1000;
    final spots = <BarChartGroupData>[];
    for (int i = 0; i < sortedKeys.length; i++) {
      final val = monthlyRevenue[sortedKeys[i]]!;
      if (val > maxY) maxY = val;
      
      spots.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: val,
              color: colorScheme.primary,
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    // Add some padding to maxY
    maxY = (maxY * 1.2).ceilToDouble();

    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => theme.colorScheme.inverseSurface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '₹${rod.toY.toStringAsFixed(0)}',
                  TextStyle(color: theme.colorScheme.onInverseSurface, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < 0 || value.toInt() >= sortedKeys.length) return const SizedBox.shrink();
                  final key = sortedKeys[value.toInt()];
                  final year = key ~/ 100;
                  final month = key % 100;
                  final date = DateTime(year, month, 1);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MMM').format(date),
                      style: theme.textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == maxY || value == 0) return const SizedBox.shrink();
                  return Text(
                    '₹${value.toInt()}',
                    style: theme.textTheme.labelSmall,
                    textAlign: TextAlign.end,
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4 > 0 ? maxY / 4 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: spots,
        ),
      ),
    );
  }
}
