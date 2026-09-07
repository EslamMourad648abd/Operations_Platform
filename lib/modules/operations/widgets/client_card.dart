import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/client_model.dart';
import '../../../../services/localization_service.dart';

class ClientCard extends StatelessWidget {
  final ClientModel client;
  final Future<String> Function(String uid)? resolveUserName;
  final Color? brandColor;
  final VoidCallback? onDelete;

  const ClientCard({super.key, required this.client, this.resolveUserName, this.brandColor, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final primary = brandColor ?? theme.colorScheme.primary;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: theme.dividerColor)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go('/operations/onboarding/client/${Uri.encodeComponent(client.id)}'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Container(width: 52, height: 52, decoration: BoxDecoration(color: primary.withValues(alpha: .1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.business_outlined, color: primary)),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(client.companyName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              Text('${l10n?.translate('acc') ?? 'ACC'}: ${client.accNumber}', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
              Text('${l10n?.translate('system') ?? 'System'}: ${client.systemType}', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
            ])),
            const SizedBox(width: 20),
            Expanded(flex: 4, child: Wrap(spacing: 8, runSpacing: 8, children: [
              StatusChip(label: l10n?.translate('activation') ?? 'Activation', status: client.activationStatus),
              StatusChip(label: l10n?.translate('verification') ?? 'Verification', status: client.verificationStatus),
              StatusChip(label: l10n?.translate('chatbot') ?? 'Chatbot', status: client.chatbotStatus),
              StatusChip(label: l10n?.translate('group') ?? 'Group', status: client.groupStatus),
            ])),
            const SizedBox(width: 20),
            SizedBox(width: 150, child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Icon(Icons.hub_outlined, size: 15, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 5),
                Text('${l10n?.translate('channels') ?? 'Channels'}: ${client.totalChannels}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ]),
              if (resolveUserName != null) FutureBuilder<String>(future: resolveUserName!(client.assignedTo), builder: (context, snapshot) => Text('${l10n?.translate('assigned') ?? 'Assigned'}: ${snapshot.data ?? '...'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)))),
            ])),
            if (onDelete != null) ...[
              const SizedBox(width: 12),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                tooltip: l10n?.translate('delete') ?? 'Delete',
              ),
            ],
            const SizedBox(width: 12),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          ]),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label, status;
  const StatusChip({super.key, required this.label, required this.status});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final norm = status.trim().toLowerCase();
    Color c = Colors.grey;
    if (norm == 'activated' || norm == 'active' || norm == 'approved' || norm == 'closed' || norm == 'ready') c = Colors.green;
    else if (norm == 'in progress' || norm == 'in_progress' || norm == 'opened') c = Colors.blue;
    else if (norm == 'submitted' || norm == 'pending') c = Colors.orange;
    else if (norm == 'rejected' || norm == 'failed') c = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: c.withValues(alpha: .1), borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withValues(alpha: .2))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 8, color: c),
        const SizedBox(width: 5),
        Text('$label: ${_displayStatus(norm, l10n)}', style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
    );
  }
  String _displayStatus(String n, AppLocalizations? l) {
    if (n.isEmpty || n == 'not started') return l?.translate('not_started_status') ?? 'Not Started';
    final translated = l?.translate('${n.replaceAll(' ', '_')}_status');
    return translated != null && translated.contains('_status') ? n.toUpperCase() : translated ?? n.toUpperCase();
  }
}
