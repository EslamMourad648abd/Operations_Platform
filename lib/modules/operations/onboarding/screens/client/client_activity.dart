import 'package:flutter/material.dart';
import '../../models/activity_model.dart';
import '../../models/client_model.dart';
import '../../repositories/onboarding_repository.dart';

class ClientActivityScreen extends StatelessWidget {
  final String clientId;
  const ClientActivityScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<ClientModel?>(
      stream: OnboardingRepository().watchClient(clientId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        if (snap.hasError || snap.data == null) return Center(child: Text('Not found.'));
        final cl = snap.data!;
        return StreamBuilder<List<ActivityModel>>(
          stream: OnboardingRepository().watchClientActivity(clientId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
            final activities = snapshot.data ?? [];
            return Container(color: theme.colorScheme.surface, child: SingleChildScrollView(padding: const EdgeInsets.all(32), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1100), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Activity', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)), Text('Audit history for ${cl.companyName}', style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)))])), _CountBadge(count: activities.length)]),
              const SizedBox(height: 28),
              _SummaryCard(cl: cl),
              const SizedBox(height: 20),
              _Timeline(activities: activities),
            ])))));
          },
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ClientModel cl; const _SummaryCard({required this.cl});
  @override Widget build(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(22), child: Wrap(spacing: 32, runSpacing: 18, children: [
      _SItem(l: 'Company', v: cl.companyName, i: Icons.business),
      _SItem(l: 'ACC', v: cl.accNumber, i: Icons.badge),
      _SItem(l: 'Activation', v: cl.activationStatus, i: Icons.power_settings_new),
      _SItem(l: 'Verification', v: cl.verificationStatus, i: Icons.verified),
      _SItem(l: 'Chatbot', v: cl.chatbotStatus, i: Icons.smart_toy),
      _SItem(l: 'Group', v: cl.groupStatus, i: Icons.groups),
    ])));
  }
}

class _SItem extends StatelessWidget {
  final String l, v; final IconData i; const _SItem({required this.l, required this.v, required this.i});
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(width: 200, child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)), child: Icon(i, size: 18, color: theme.colorScheme.primary)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))), Text(v.isEmpty ? '—' : v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)]))
    ]));
  }
}

class _Timeline extends StatelessWidget {
  final List<ActivityModel> activities; const _Timeline({required this.activities});
  @override Widget build(BuildContext context) {
    if (activities.isEmpty) return Card(child: Padding(padding: const EdgeInsets.all(40), child: Center(child: Text('No activity yet.'))));
    return Card(child: Padding(padding: const EdgeInsets.all(26), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Activity Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      ...List.generate(activities.length, (i) => _Item(act: activities[i], last: i == activities.length - 1)),
    ])));
  }
}

class _Item extends StatelessWidget {
  final ActivityModel act; final bool last; const _Item({required this.act, required this.last});
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context); final c = _color(act.type);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 42, child: Column(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: c.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(_icon(act.type), size: 17, color: c)),
        if (!last) Container(width: 1, height: 50, color: theme.dividerColor, margin: const EdgeInsets.symmetric(vertical: 4)),
      ])),
      const SizedBox(width: 14),
      Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(act.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))), Text(_fDt(act.createdAt), style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))]),
        if (act.action.isNotEmpty) Container(margin: const EdgeInsets.only(top: 4, bottom: 4), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: theme.colorScheme.onSurface.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4)), child: Text(act.action.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)))),
        Text(act.description, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
        const SizedBox(height: 4),
        Row(children: [Icon(Icons.person, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)), const SizedBox(width: 4), Text(act.actorName.isEmpty ? 'System' : act.actorName, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))]),
      ]))),
    ]);
  }
}

class _CountBadge extends StatelessWidget {
  final int count; const _CountBadge({required this.count});
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.dividerColor)), child: Row(children: [Icon(Icons.history, size: 16, color: theme.colorScheme.primary), const SizedBox(width: 8), Text('$count events', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]));
  }
}

String _fDt(DateTime? d) => d == null ? '—' : '${d.day}/${d.month} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
IconData _icon(String t) { switch(t.toLowerCase()) { case 'client_created': return Icons.person_add; case 'assignment_changed': return Icons.assignment_ind; case 'status_changed': return Icons.sync; case 'verification_updated': return Icons.verified; case 'chatbot_updated': return Icons.smart_toy; case 'group_updated': return Icons.groups; case 'crm_updated': return Icons.comment; default: return Icons.history; } }
Color _color(String t) { switch(t.toLowerCase()) { case 'client_created': return Colors.green; case 'verification_updated': return Colors.blue; case 'chatbot_updated': return Colors.teal; case 'group_updated': return Colors.orange; case 'crm_updated': return Colors.brown; default: return Colors.blueGrey; } }
