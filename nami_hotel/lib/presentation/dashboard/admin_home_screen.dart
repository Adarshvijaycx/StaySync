import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../domain/entities/app_user.dart';

/// Admin home screen — full access to all management features.
///
/// This is a shell screen for Phase 2; feature content will be
/// added in Phases 3–6 (Hotels, Rooms, Bookings, Dashboard, etc.).
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nami Hotel'),
        actions: [
          _buildUserChip(context, user),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () => _confirmLogout(context, ref),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome banner
            _buildWelcomeBanner(context, user, colorScheme),
            const SizedBox(height: 24),

            // Quick actions grid
            Text(
              'Management',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildActionsGrid(context, colorScheme),

            const SizedBox(height: 24),

            // Info card
            _buildInfoCard(context, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(
    BuildContext context,
    AppUser? user,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.name ?? 'Admin',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '🛡️ Administrator',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsGrid(BuildContext context, ColorScheme colorScheme) {
    final actions = [
      _ActionItem(
        icon: Icons.apartment_rounded,
        label: 'Hotels',
        subtitle: 'Manage properties',
        color: colorScheme.primary,
      ),
      _ActionItem(
        icon: Icons.meeting_room_rounded,
        label: 'Rooms',
        subtitle: 'View availability',
        color: colorScheme.primary,
      ),
      _ActionItem(
        icon: Icons.book_online_rounded,
        label: 'Bookings',
        subtitle: 'Manage guests',
        color: colorScheme.secondary,
      ),
      _ActionItem(
        icon: Icons.fastfood_rounded,
        label: 'Catalogue',
        subtitle: 'Manage items',
        color: colorScheme.tertiary,
      ),
      _ActionItem(
        icon: Icons.people_rounded,
        label: 'Users',
        subtitle: 'Staff management',
        color: colorScheme.error,
      ),
      _ActionItem(
        icon: Icons.dashboard_rounded,
        label: 'Dashboard',
        subtitle: 'Analytics & KPIs',
        color: colorScheme.primary,
      ),
      _ActionItem(
        icon: Icons.menu_book_rounded,
        label: 'Catalogue',
        subtitle: 'Item catalogue',
        color: colorScheme.tertiary,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return Card(
          child: InkWell(
            onTap: () {
              if (action.label == 'Hotels') {
                context.go('/hotels');
              } else if (action.label == 'Bookings') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a Hotel from the Hotels list to view its bookings.')),
                );
              } else if (action.label == 'Catalogue') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a Hotel from the Hotels list to manage its catalogue.')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${action.label} — Coming in next phase'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: action.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(action.icon, color: action.color, size: 22),
                  ),
                  const Spacer(),
                  Text(
                    action.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    action.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(BuildContext context, ColorScheme colorScheme) {
    return Card(
      color: colorScheme.tertiaryContainer.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: colorScheme.tertiary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Phase 2 complete — Authentication & role-based routing active. Feature screens coming in Phase 3+.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserChip(BuildContext context, AppUser? user) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_rounded,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            user?.name ?? 'Admin',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authNotifierProvider.notifier).logout();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });
}
