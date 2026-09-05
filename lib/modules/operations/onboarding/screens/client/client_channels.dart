import 'package:flutter/material.dart';
import '../../models/channel_model.dart';
import '../../models/client_model.dart';
import '../../repositories/onboarding_repository.dart';

class ClientChannelsScreen extends StatelessWidget {
  const ClientChannelsScreen({super.key, required this.clientId});
  final String clientId;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ClientModel?>(
      stream: OnboardingRepository().watchClient(clientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        if (snapshot.hasError || snapshot.data == null) return _Msg(icon: Icons.error_outline, title: 'Error', message: 'Not found.');
        return _Content(client: snapshot.data!, clientId: clientId);
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.client, required this.clientId});
  final ClientModel client; final String clientId;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      child: SingleChildScrollView(padding: const EdgeInsets.all(32), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1200), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Channels', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            Text('Manage channels for ${client.companyName}.', style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          ])),
          _CountBadge(count: client.channels.length),
          const SizedBox(width: 12),
          ElevatedButton.icon(onPressed: () => _showAdd(context, clientId), icon: const Icon(Icons.add), label: const Text('Add'), style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary)),
        ]),
        const SizedBox(height: 28),
        _MainCard(client: client, clientId: clientId),
      ])))),
    );
  }
}

class _MainCard extends StatelessWidget {
  final ClientModel client; final String clientId;
  const _MainCard({required this.client, required this.clientId});
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.hub, color: theme.colorScheme.primary, size: 20)),
        const SizedBox(width: 12),
        const Text('Integrated Channels', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 24),
      if (client.channels.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('No channels yet.', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))))
      else ...List.generate(client.channels.length, (i) => _ChannelTile(channel: client.channels[i], clientId: clientId)),
    ])));
  }
}

class _ChannelTile extends StatelessWidget {
  final ChannelModel channel; final String clientId;
  const _ChannelTile({required this.channel, required this.clientId});
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: theme.colorScheme.onSurface.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor)), child: Column(children: [
      Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.hub, color: theme.colorScheme.primary, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(channel.name.isEmpty ? channel.channelType : channel.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(channel.channelType, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        ])),
        _StatusChip(status: channel.status),
        IconButton(onPressed: () => _showDel(context, clientId, channel), icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20)),
      ]),
    ]));
  }
}

class _StatusChip extends StatelessWidget {
  final String status; const _StatusChip({required this.status});
  @override Widget build(BuildContext context) {
    final ok = ['active', 'enabled'].contains(status.toLowerCase());
    final c = ok ? Colors.green : Colors.red;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: Text(status, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.bold)));
  }
}

class _CountBadge extends StatelessWidget {
  final int count; const _CountBadge({required this.count});
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: Text('$count Channels', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)));
  }
}

class _Msg extends StatelessWidget {
  final IconData icon; final String title, message;
  const _Msg({required this.icon, required this.title, required this.message});
  @override Widget build(BuildContext context) { return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 52, color: Colors.grey), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text(message)])); }
}

void _showAdd(BuildContext c, String id) {} // Implement actual dialogs as needed
void _showDel(BuildContext c, String id, ChannelModel ch) {}
