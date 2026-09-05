import 'package:flutter/material.dart';
import '../../models/client_model.dart';
import '../../repositories/onboarding_repository.dart';

class ClientChatbotScreen extends StatelessWidget {
  final String clientId;
  const ClientChatbotScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ClientModel?>(
      stream: OnboardingRepository().watchClient(clientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        if (snapshot.hasError || snapshot.data == null) return _Error(message: 'Not found.');
        return _Content(client: snapshot.data!, clientId: clientId);
      },
    );
  }
}

class _Content extends StatelessWidget {
  final ClientModel client; final String clientId;
  const _Content({required this.client, required this.clientId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ck = _normCk(client.chatbotChecklist);
    final comp = _comp(ck);
    final st = _derive(ck);

    return Container(
      color: theme.colorScheme.surface,
      child: SingleChildScrollView(padding: const EdgeInsets.all(32), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1100), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Chatbot', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            Text(client.companyName.isEmpty ? 'Workflow' : 'Workflow for ${client.companyName}', style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          ])),
          _Badge(status: st),
        ]),
        const SizedBox(height: 28),
        _SummaryCard(comp: comp, total: items.length, status: st),
        const SizedBox(height: 20),
        _ChecklistCard(clientId: clientId, checklist: ck),
        const SizedBox(height: 20),
        _InfoCard(client: client),
      ])))),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int comp, total; final String status;
  const _SummaryCard({required this.comp, required this.total, required this.status});
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context); final cfg = _cfg(_norm(status));
    return Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 52, height: 52, decoration: BoxDecoration(color: cfg.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(cfg.icon, color: cfg.color, size: 26)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Chatbot Status', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.bold)),
          Text(_disp(status), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        ])),
        _CountBadge(comp: comp, total: total),
      ]),
      const SizedBox(height: 20),
      ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: comp / total, minHeight: 8, backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1), color: theme.colorScheme.primary)),
      const SizedBox(height: 12),
      Text(_msg(status, comp), style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
    ])));
  }
}

class _ChecklistCard extends StatefulWidget {
  final String clientId; final Map<String, bool> checklist;
  const _ChecklistCard({required this.clientId, required this.checklist});
  @override State<_ChecklistCard> createState() => _ChecklistCardState();
}

class _ChecklistCardState extends State<_ChecklistCard> {
  String? _saving;
  @override Widget build(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Chatbot Checklist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 24),
      ...List.generate(items.length, (i) => _Tile(item: items[i], done: widget.checklist[items[i].key] ?? false, saving: _saving == items[i].key, disabled: _saving != null, onTap: () => _toggle(items[i]))),
    ])));
  }
  Future<void> _toggle(_Item it) async {
    if (_saving != null) return; setState(() => _saving = it.key);
    final up = Map<String, bool>.from(widget.checklist); up[it.key] = !(up[it.key] ?? false);
    try { await OnboardingRepository().updateClientFields(widget.clientId, {'chatbotChecklist': up, 'chatbotStatus': _derive(up)}); }
    finally { if (mounted) setState(() => _saving = null); }
  }
}

class _Tile extends StatelessWidget {
  final _Item item; final bool done, saving, disabled; final VoidCallback onTap;
  const _Tile({required this.item, required this.done, required this.saving, required this.disabled, required this.onTap});
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: InkWell(onTap: disabled ? null : onTap, borderRadius: BorderRadius.circular(10), child: AnimatedContainer(duration: const Duration(milliseconds: 180), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: done ? theme.colorScheme.primary.withValues(alpha: 0.05) : theme.colorScheme.surface.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10), border: Border.all(color: done ? theme.colorScheme.primary.withValues(alpha: 0.2) : theme.dividerColor)), child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: done ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.colorScheme.onSurface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(item.icon, size: 21, color: done ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.5))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: done ? theme.colorScheme.primary : theme.colorScheme.onSurface)), Text(item.desc, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)))])),
      if (saving) const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) else Checkbox(value: done, onChanged: disabled ? null : (_) => onTap(), activeColor: theme.colorScheme.primary),
    ]))));
  }
}

class _InfoCard extends StatelessWidget {
  final ClientModel client; const _InfoCard({required this.client});
  @override Widget build(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Chatbot Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      _Row(l: 'ACC', v: client.accNumber), _Row(l: 'BM ID', v: client.bmId), _Row(l: 'WABA ID', v: client.wabaId), _Row(l: 'Phone ID', v: client.phoneNumberId),
    ])));
  }
}

class _Row extends StatelessWidget {
  final String l, v; const _Row({required this.l, required this.v});
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [SizedBox(width: 150, child: Text(l, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.bold))), Expanded(child: Text(v.isEmpty ? '—' : v, style: const TextStyle(fontSize: 14)))]));
  }
}

class _Badge extends StatelessWidget {
  final String status; const _Badge({required this.status});
  @override Widget build(BuildContext context) {
    final c = _cfg(_norm(status)).color;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: Row(children: [Icon(Icons.circle, size: 8, color: c), const SizedBox(width: 7), Text(_disp(status), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: c))]));
  }
}

class _CountBadge extends StatelessWidget {
  final int comp, total; const _CountBadge({required this.comp, required this.total});
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(18)), child: Text('$comp / $total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)));
  }
}

class _Error extends StatelessWidget {
  final String message; const _Error({required this.message});
  @override Widget build(BuildContext context) { return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error, size: 52, color: Colors.red), Text(message)])); }
}

String _norm(String? s) { final n = s?.trim().toLowerCase() ?? ''; return (n == 'not_started' || n == 'notstarted') ? 'not started' : (n == 'in_progress' || n == 'inprogress' ? 'in progress' : (n == 'active' ? 'activated' : n)); }
String _disp(String? s) { final n = _norm(s); return n[0].toUpperCase() + n.substring(1); }
int _comp(Map<String, bool> ck) => ck.values.where((v) => v).length;
String _derive(Map<String, bool> ck) { if (ck['productionActivation'] == true) return 'activated'; if (ck['testingCompleted'] == true && ck['clientApproval'] == true) return 'ready'; return _comp(ck) > 0 ? 'in progress' : 'not started'; }
Map<String, bool> _normCk(Map<String, bool>? src) { return {for (var i in items) i.key: src?[i.key] ?? false}; }
String _msg(String s, int c) { final n = _norm(s); if (n == 'activated') return 'Active in production.'; if (n == 'ready') return 'Ready for activation.'; return c == 0 ? 'Confirmation needed.' : 'In progress.'; }
class _Item { final String key, title, desc; final IconData icon; const _Item(this.key, this.title, this.desc, this.icon); }
const items = [
  _Item('chatbotRequirementsReceived', 'Requirements Received', 'Collected from client.', Icons.assignment_turned_in),
  _Item('flowCreated', 'Flow Created', 'Chatbot logic built.', Icons.account_tree),
  _Item('flowReviewed', 'Flow Reviewed', 'Internal review complete.', Icons.rate_review),
  _Item('apiConnected', 'API Connected', 'Service integration done.', Icons.link),
  _Item('testingCompleted', 'Testing Completed', 'Full testing passed.', Icons.fact_check),
  _Item('clientApproval', 'Client Approval', 'Approved for production.', Icons.thumb_up),
  _Item('productionActivation', 'Production Activation', 'Live for users.', Icons.rocket_launch),
];
class _Cfg { final Color color; final IconData icon; const _Cfg(this.color, this.icon); }
_Cfg _cfg(String s) { switch (s) { case 'activated': return const _Cfg(Colors.green, Icons.check_circle); case 'ready': return const _Cfg(Colors.teal, Icons.verified); case 'in progress': return const _Cfg(Colors.blue, Icons.sync); default: return const _Cfg(Colors.grey, Icons.smart_toy); } }
