import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/sync_service.dart';

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncServiceProvider);
    
    IconData icon;
    Color color;
    String tooltip;

    switch (status) {
      case SyncStatus.synced:
        icon = Icons.cloud_done_outlined;
        color = Colors.green;
        tooltip = 'Synced';
        break;
      case SyncStatus.syncing:
        icon = Icons.cloud_sync_outlined;
        color = Colors.blue;
        tooltip = 'Syncing...';
        break;
      case SyncStatus.pending:
        icon = Icons.cloud_upload_outlined;
        color = Colors.orange;
        tooltip = 'Offline (Pending changes)';
        break;
      case SyncStatus.failed:
        icon = Icons.cloud_off_outlined;
        color = Colors.red;
        tooltip = 'Sync failed';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Icon(icon, color: color),
      ),
    );
  }
}
