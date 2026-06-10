import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/hotel_providers.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/error_state_widget.dart';

class HotelListScreen extends ConsumerWidget {
  const HotelListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotelsAsync = ref.watch(hotelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Hotels'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(hotelsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: hotelsAsync.when(
        data: (hotels) {
          if (hotels.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.apartment_rounded,
              title: 'No hotels found',
              subtitle: 'Tap the + button to add a new property',
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(hotelsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: hotels.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final hotel = hotels[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.apartment_rounded,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      hotel.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          hotel.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone_rounded, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                hotel.contactNumber,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.book_online_rounded),
                          tooltip: 'Manage Bookings',
                          onPressed: () => context.push('/hotels/${hotel.id}/bookings'),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded),
                          tooltip: 'More options',
                          onSelected: (value) {
                            switch (value) {
                              case 'rooms':
                                context.push('/hotels/${hotel.id}/rooms');
                                break;
                              case 'catalogue':
                                context.push('/hotels/${hotel.id}/items');
                                break;
                              case 'dashboard':
                                context.push('/hotels/${hotel.id}/dashboard');
                                break;
                              case 'edit':
                                context.push('/hotels/${hotel.id}/edit');
                                break;
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'rooms', child: Text('Manage Rooms')),
                            PopupMenuItem(value: 'catalogue', child: Text('Item Catalogue')),
                            PopupMenuItem(value: 'dashboard', child: Text('Hotel Dashboard')),
                            PopupMenuItem(value: 'edit', child: Text('Edit Hotel')),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorStateWidget(
          errorMessage: error.toString(),
          onRetry: () => ref.read(hotelsProvider.notifier).refresh(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/hotels/new'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
