import 'dart:async';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/client_model.dart';
import '../../repositories/onboarding_repository.dart';
import '../../widgets/client_card.dart';
import '../../../../../services/localization_service.dart';
import '../../../../../services/user_display_name_resolver.dart';
import '../../../../../services/auth_service.dart';

class OnboardingClientsScreen extends StatefulWidget {
  const OnboardingClientsScreen({super.key});

  @override
  State<OnboardingClientsScreen> createState() =>
      _OnboardingClientsScreenState();
}

class _OnboardingClientsScreenState
    extends State<OnboardingClientsScreen> {
  final OnboardingRepository _repository = OnboardingRepository();

  late final Stream<List<ClientModel>> _clientsStream;
  final UserDisplayNameResolver _resolver = UserDisplayNameResolver();

  final Map<String, String> _agentNames = {};
  StreamSubscription? _agentsSub;

  final Map<String, String> _onboardingAgentNames = {};
  StreamSubscription? _onboardingAgentsSub;

  String _search = "";
  final ValueNotifier<int> _filteredCount = ValueNotifier(0);

  bool _isSupport = false;

  // Operation Panel State
  bool _operationRunning = false;
  bool _cancelOperationRequested = false;

  final ValueNotifier<_OperationPanelData> _operationPanel =
  ValueNotifier(const _OperationPanelData.hidden());

  @override
  void initState() {
    super.initState();
    _clientsStream = _repository.watchClients();

    _agentsSub = _repository.watchAgents().listen((agents) {
      if (mounted) {
        setState(() {
          _agentNames.clear();
          _agentNames.addAll(agents);
        });
      }
    });

    _onboardingAgentsSub = _repository.watchAgents(role: 'onboarding_agent').listen((agents) {
      if (mounted) {
        setState(() {
          _onboardingAgentNames.clear();
          _onboardingAgentNames.addAll(agents);
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isSupport = GoRouterState.of(context).uri.path.contains('/support');
  }

  @override
  void dispose() {
    _agentsSub?.cancel();
    _onboardingAgentsSub?.cancel();
    _operationPanel.dispose();
    _filteredCount.dispose();
    super.dispose();
  }

  Future<String> _resolveUserName(String uid) {
    return _resolver.resolve(uid);
  }

  String _normalize(String? value) {
    final n = value?.trim().toLowerCase() ?? '';
    if (n.isEmpty) return 'not started';
    if (n == 'not_started' || n == 'notstarted') return 'not started';
    if (n == 'in_progress' || n == 'inprogress') return 'in progress';
    if (n == 'active' || n == 'activated' || n == 'finished') return 'activated';
    if (n == 'verified' || n == 'approved') return 'verified';
    return n;
  }

  bool get _isSuperAdmin => AuthService.isSuperAdmin;

  bool _canEdit(ClientModel client) {
    if (_isSuperAdmin) return true;
    final isClosed = _normalize(client.groupStatus) == 'closed';
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    if (AuthService.isSupportAgent) {
      return isClosed;
    }

    return !isClosed && client.assignedTo.trim() == user.uid;
  }

  // ===========================================================================
  // OPERATION PANEL HELPERS
  // ===========================================================================

  void _startOperationPanel({
    required String title,
    required String subtitle,
    required IconData icon,
    required int total,
  }) {
    if (!mounted) return;
    _operationRunning = true;
    _cancelOperationRequested = false;
    _operationPanel.value = _OperationPanelData(
      title: title,
      processed: 0,
      total: total,
      progress: 0,
      cancelling: false,
      status: 'Starting...',
      resultMessage: null,
      error: false,
    );
    setState(() {});
  }

  void _updateOperationProgress({required int processed, required int total, String? status}) {
    if (!mounted) return;
    _operationPanel.value = _operationPanel.value.copyWith(
      processed: processed,
      progress: total == 0 ? 1 : processed / total,
      status: status,
    );
  }

  void _requestOperationCancel() {
    if (!mounted) return;
    _cancelOperationRequested = true;
    _operationPanel.value = _operationPanel.value.copyWith(
      cancelling: true,
      status: 'Cancelling...',
    );
    setState(() {});
  }

  void _finishOperationPanel({required String title, required String message, bool error = false, List<List<String>>? skippedRows}) {
    if (!mounted) return;
    _operationRunning = false;
    _operationPanel.value = _OperationPanelData(
      title: _operationPanel.value.title,
      processed: _operationPanel.value.processed,
      total: _operationPanel.value.total,
      progress: 1,
      cancelling: false,
      status: '',
      resultMessage: message,
      error: error,
      skippedRows: skippedRows,
    );
    setState(() {});
  }

  void _clearOperationPanel() {
    if (!mounted) return;
    _operationRunning = false;
    _cancelOperationRequested = false;
    _operationPanel.value = const _OperationPanelData.hidden();
    setState(() {});
  }

  void _downloadSkippedCsv(List<List<String>> rows) {
    String csvContent = rows.map((row) => row.map((field) => '"${field.replaceAll('"', '""')}"').join(',')).join('\n');
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8;');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "skipped_rows_${DateTime.now().millisecondsSinceEpoch}.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Widget _buildOperationPanel() {
    return ValueListenableBuilder<_OperationPanelData>(
      valueListenable: _operationPanel,
      builder: (context, data, _) {
        if (data.resultMessage != null) {
          final accent = data.error ? Colors.red : Colors.green;
          return SizedBox(width: double.infinity, child: Align(alignment: Alignment.bottomCenter, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800), child: Material(elevation: 8, shadowColor: Colors.black26, color: Theme.of(context).colorScheme.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: accent.withValues(alpha: 0.2))), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), child: Row(children: [Icon(data.error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: accent, size: 24), const SizedBox(width: 16), Expanded(child: Text(data.resultMessage!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))), if (data.skippedRows != null && data.skippedRows!.isNotEmpty) ...[Tooltip(message: 'Download skipped rows', child: InkWell(onTap: () => _downloadSkippedCsv(data.skippedRows!), borderRadius: BorderRadius.circular(8), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.download_rounded, color: Colors.orange, size: 18)))), const SizedBox(width: 12)], InkWell(onTap: _clearOperationPanel, borderRadius: BorderRadius.circular(8), child: Container(padding: const EdgeInsets.all(8), child: const Icon(Icons.close_rounded, size: 20)))]))))));
        }
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        final accent = colors.primary;
        final percentage = (data.progress * 100).toInt();
        final headerIcon = data.title.toLowerCase().contains('delete') ? Icons.delete_sweep_rounded : Icons.upload_file_rounded;
        return SizedBox(width: double.infinity, child: Align(alignment: Alignment.bottomCenter, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800), child: Material(elevation: 12, shadowColor: Colors.black38, color: colors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.dividerColor)), child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [Row(children: [Expanded(child: Text(data.cancelling ? 'Cancelling operation...' : '${data.title}: ${data.processed} / ${data.total}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))), if (!data.cancelling) InkWell(onTap: _requestOperationCancel, borderRadius: BorderRadius.circular(8), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: colors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text('Cancel', style: TextStyle(color: colors.error, fontWeight: FontWeight.bold, fontSize: 12)))) else const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey)), const SizedBox(width: 16), InkWell(onTap: _clearOperationPanel, borderRadius: BorderRadius.circular(8), child: Container(padding: const EdgeInsets.all(4), child: const Icon(Icons.close_rounded, size: 20, color: Colors.grey)))]), const SizedBox(height: 16), Row(children: [Icon(headerIcon, color: accent, size: 20), const SizedBox(width: 12), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: data.progress, minHeight: 5, backgroundColor: colors.surfaceContainerHighest, color: accent))), const SizedBox(width: 12), SizedBox(width: 34, child: Text('$percentage%', textAlign: TextAlign.right, style: theme.textTheme.labelMedium?.copyWith(color: accent, fontWeight: FontWeight.w700)))])]))))));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final label = _isSupport ? 'Support' : (AuthService.isSuperAdmin ? 'Operations' : 'Onboarding');

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Text(
              '$label Clients',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            ValueListenableBuilder<int>(
              valueListenable: _filteredCount,
              builder: (context, val, _) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$val accounts', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                );
              },
            ),
          ],
        ),
        actions: [
          if (_isSuperAdmin)
            StreamBuilder<List<ClientModel>>(
              stream: _clientsStream,
              builder: (context, snapshot) {
                final clients = snapshot.data ?? [];
                if (clients.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: TextButton.icon(
                    onPressed: _operationRunning ? null : () => _bulkDeleteAll(clients),
                    icon: const Icon(Icons.delete_sweep, size: 19),
                    label: const Text('Bulk Delete'),
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  ),
                );
              },
            ),
          if (_isSuperAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: OutlinedButton.icon(
                onPressed: _operationRunning ? null : _showImportDialog,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Import'),
              ),
            ),
          if (_isSuperAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: ElevatedButton.icon(
                onPressed: _showCreateClientDialog,
                icon: const Icon(Icons.add),
                label: Text(l10n?.translate('new_client') ?? 'New Client'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildSearch(l10n, theme),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<List<ClientModel>>(
                    stream: _clientsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('Error loading clients.'));
                      }

                      var streamedClients = snapshot.data ?? [];

                      // APPLY SUPPORT FILTER: Only show closed groups
                      if (_isSupport) {
                        streamedClients = streamedClients.where((c) => _normalize(c.groupStatus) == 'closed').toList();
                      }

                      final q = _normalize(_search);

                      final filtered = streamedClients.where((client) {
                        if (q.isEmpty) return true;
                        final assigneeName = _normalize(_agentNames[client.assignedTo] ?? '');
                        return _normalize(client.companyName).contains(q) ||
                               _normalize(client.accNumber).contains(q) ||
                               _normalize(client.assignedTo).contains(q) ||
                               assigneeName.contains(q);
                      }).toList();

                      // Sync counter
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _filteredCount.value != filtered.length) {
                          _filteredCount.value = filtered.length;
                        }
                      });

                      if (filtered.isEmpty) {
                        return _EmptyClients(hasSearch: _search.trim().isNotEmpty, onCreate: _showCreateClientDialog);
                      }

                      return ListView.separated(
                        padding: EdgeInsets.only(bottom: _operationRunning ? 90 : 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final client = filtered[index];
                          return Row(
                            key: ValueKey(client.id),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClientCard(
                                  client: client,
                                  resolveUserName: _resolveUserName,
                                  onDelete: (_isSuperAdmin && !_isSupport) ? () => _deleteClient(client) : null,
                                ),
                              ),
                              if (_canEdit(client) && !AuthService.isSupportAgent) ...[
                                const SizedBox(width: 8),
                                Tooltip(
                                  message: 'Edit Client Info',
                                  child: Material(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () => _showEditClientInfoDialog(client),
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: theme.dividerColor),
                                        ),
                                        child: Icon(Icons.edit_note_rounded, size: 22, color: theme.colorScheme.primary),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (_isSuperAdmin && !_isSupport) ...[
                                const SizedBox(width: 8),
                                Tooltip(
                                  message: 'Reassign Client',
                                  child: Material(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () => _showReassignClientDialog(client),
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: theme.dividerColor),
                                        ),
                                        child: Icon(Icons.assignment_ind_outlined, size: 20, color: theme.colorScheme.primary),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<_OperationPanelData>(
            valueListenable: _operationPanel,
            builder: (context, data, _) {
              if (!_operationRunning && data.resultMessage == null) return const SizedBox.shrink();
              return Positioned(left: 24, right: 24, bottom: 16, child: _buildOperationPanel());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(AppLocalizations? l10n, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.dividerColor)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          onChanged: (value) => setState(() => _search = value),
          decoration: InputDecoration(hintText: l10n?.translate('search_clients') ?? 'Search clients...', border: InputBorder.none, icon: const Icon(Icons.search)),
        ),
      ),
    );
  }

  Future<void> _showEditClientInfoDialog(ClientModel client) async {
    final cc = TextEditingController(text: client.companyName);
    final ac = TextEditingController(text: client.accNumber);
    final bm = TextEditingController(text: client.bmId);
    final wa = TextEditingController(text: client.wabaId);
    final pid = TextEditingController(text: client.phoneNumberId);
    final pnum = TextEditingController(text: client.phoneNumber);

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Client Information'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: cc, decoration: const InputDecoration(labelText: 'Company Name')),
                const SizedBox(height: 16),
                TextField(controller: ac, decoration: const InputDecoration(labelText: 'ACC Number')),
                const SizedBox(height: 16),
                TextField(controller: bm, decoration: const InputDecoration(labelText: 'BM ID')),
                const SizedBox(height: 16),
                TextField(controller: wa, decoration: const InputDecoration(labelText: 'WABA ID')),
                const SizedBox(height: 16),
                TextField(controller: pid, decoration: const InputDecoration(labelText: 'Phone ID')),
                const SizedBox(height: 16),
                TextField(controller: pnum, decoration: const InputDecoration(labelText: 'Phone Number')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, {'companyName': cc.text.trim(), 'accNumber': ac.text.trim(), 'bmId': bm.text.trim(), 'wabaId': wa.text.trim(), 'phoneNumberId': pid.text.trim(), 'phoneNumber': pnum.text.trim()}),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );

    if (result == null) return;
    try {
      await _repository.updateClientFields(client.id, result);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Client information updated.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteClient(ClientModel client) async {
    if (!_isSuperAdmin) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text('Are you sure you want to delete ${client.companyName}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _repository.deleteClient(client.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Client deleted.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _bulkDeleteAll(List<ClientModel> clients) async {
    if (!_isSuperAdmin || clients.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete all clients?'),
        content: Text('This will permanently delete ${clients.length} client records. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Theme.of(dialogContext).colorScheme.error, foregroundColor: Theme.of(dialogContext).colorScheme.onError), onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Delete all')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ids = clients.map((c) => c.id).toList();
    _startOperationPanel(title: 'Deleting Clients', subtitle: 'Processing removal...', icon: Icons.delete_sweep, total: ids.length);
    try {
      final deleted = await _repository.bulkDeleteClients(ids, isCancelled: () => _cancelOperationRequested, onProgress: (d, t) => _updateOperationProgress(processed: d, total: t, status: 'Deleted $d of $t'));
      if (!mounted) return;
      if (_cancelOperationRequested) { _finishOperationPanel(title: 'Delete Cancelled', message: 'Operation was stopped. $deleted clients were deleted.'); }
      else { _finishOperationPanel(title: 'Delete Complete', message: 'Successfully deleted $deleted client records.'); }
    } catch (e) {
      if (mounted) _finishOperationPanel(title: 'Delete Failed', message: 'An error occurred: $e', error: true);
    }
  }

  Future<void> _showReassignClientDialog(ClientModel client) async {
    if (!_isSuperAdmin) return;
    final agents = Map<String, String>.from(_onboardingAgentNames);
    if (agents.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No onboarding agents are available for reassignment.'))); return; }

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String? selected = client.assignedTo;
        return StatefulBuilder(builder: (context, setS) => AlertDialog(
          title: const Text('Reassign Client'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(client.companyName.isEmpty ? 'Unnamed Client' : client.companyName, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('ACC: ${client.accNumber}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: agents.containsKey(selected) ? selected : null,
              decoration: const InputDecoration(labelText: 'Onboarding Agent'),
              items: [const DropdownMenuItem(value: '', child: Text('Unassigned')), ...agents.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))],
              onChanged: (v) => setS(() => selected = v),
            ),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(dialogContext, selected), child: const Text('Save'))],
        ));
      }
    );
    if (result == null) return;
    try {
      await _repository.updateAssignedTo(client.id, result);
      if (mounted) {
        final name = result.isEmpty ? 'Unassigned' : (_agentNames[result] ?? result);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${client.companyName} reassigned to $name.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reassignment failed: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _showCreateClientDialog() async {
    final l10n = AppLocalizations.of(context);
    final nameC = TextEditingController();
    final accC = TextEditingController();
    String sysType = 'New';

    final result = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(builder: (context, setS) => AlertDialog(
        title: Text(l10n?.translate('new_client') ?? 'New Client'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameC, decoration: InputDecoration(labelText: l10n?.translate('company_name') ?? 'Company Name')),
          const SizedBox(height: 16),
          TextField(controller: accC, decoration: InputDecoration(labelText: l10n?.translate('acc') ?? 'ACC Number')),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: sysType,
            decoration: InputDecoration(labelText: l10n?.translate('system') ?? 'System'),
            items: const [DropdownMenuItem(value: 'New', child: Text('New')), DropdownMenuItem(value: 'Old', child: Text('Old'))],
            onChanged: (v) => setS(() => sysType = v ?? 'New'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l10n?.translate('cancel') ?? 'Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: Text(l10n?.translate('create') ?? 'Create')),
        ],
      )),
    );
    if (result == true) {
      try {
        await _repository.createClient(companyName: nameC.text.trim(), accNumber: accC.text.trim(), systemType: sysType);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Client created.')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _showImportDialog() async {
    final input = html.FileUploadInputElement()..accept = '.csv';
    input.click();
    await input.onChange.first;
    if (input.files == null || input.files!.isEmpty) return;
    final file = input.files!.first;
    final reader = html.FileReader();
    reader.readAsText(file);
    await reader.onLoad.first;
    final content = reader.result as String;
    
    final rows = _parseCsv(content);
    if (rows.length < 2) return;

    _startOperationPanel(title: 'Importing CSV', subtitle: 'Processing records...', icon: Icons.upload_file, total: rows.length - 1);
    
    int imported = 0;
    try {
      final List<Map<String, dynamic>> clientsToCreate = [];
      final headers = rows.first.map((e) => e.trim().toLowerCase()).toList();
      
      int nameIdx = headers.indexOf('company name');
      int accIdx = headers.indexOf('acc number');
      if (accIdx == -1) accIdx = headers.indexOf('acc');
      int sysIdx = headers.indexOf('system type');
      if (sysIdx == -1) sysIdx = headers.indexOf('system');
      
      if (accIdx == -1) throw Exception('ACC column not found.');

      for (int i = 1; i < rows.length; i++) {
        if (_cancelOperationRequested) break;
        final row = rows[i];
        final acc = row[accIdx].trim();
        if (acc.isEmpty) continue;
        
        final name = nameIdx != -1 && row.length > nameIdx ? row[nameIdx].trim() : 'Client $acc';
        final sys = sysIdx != -1 && row.length > sysIdx ? row[sysIdx].trim() : 'New';
        
        clientsToCreate.add({
          'companyName': name,
          'accNumber': acc,
          'systemType': sys,
          'activationStatus': 'Not Started',
          'verificationStatus': 'Not Started',
          'chatbotStatus': 'Not Started',
          'groupStatus': 'Not Started',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      const int batchSize = 100;
      for (int i = 0; i < clientsToCreate.length; i += batchSize) {
        if (_cancelOperationRequested) break;
        final chunk = clientsToCreate.sublist(i, i + batchSize > clientsToCreate.length ? clientsToCreate.length : i + batchSize);
        final batch = FirebaseFirestore.instance.batch();
        for (final data in chunk) {
          batch.set(FirebaseFirestore.instance.collection('clients').doc(), data);
        }
        await batch.commit();
        imported += chunk.length;
        _updateOperationProgress(processed: imported, total: clientsToCreate.length, status: 'Imported $imported of ${clientsToCreate.length}');
      }
      
      if (_cancelOperationRequested) {
        _finishOperationPanel(title: 'Import Cancelled', message: 'Operation stopped. $imported clients imported.');
      } else {
        _finishOperationPanel(title: 'Import Complete', message: 'Successfully imported $imported clients.');
      }
    } catch (e) {
      _finishOperationPanel(title: 'Import Failed', message: '$e', error: true);
    }
  }

  List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    final lines = input.split(RegExp(r'\r?\n'));
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      rows.add(line.split(',').map((e) => e.replaceAll('"', '')).toList());
    }
    return rows;
  }
}

class _OperationPanelData {
  final String title, status;
  final int processed, total;
  final double progress;
  final bool cancelling, error;
  final String? resultMessage;
  final List<List<String>>? skippedRows;
  const _OperationPanelData({required this.title, required this.processed, required this.total, required this.progress, required this.cancelling, required this.status, required this.resultMessage, required this.error, this.skippedRows});
  const _OperationPanelData.hidden() : title = '', processed = 0, total = 0, progress = 0, cancelling = false, status = '', resultMessage = null, error = false, skippedRows = null;
  _OperationPanelData copyWith({String? title, int? processed, int? total, double? progress, bool? cancelling, String? status, String? resultMessage, bool? error, List<List<String>>? skippedRows}) {
    return _OperationPanelData(title: title ?? this.title, processed: processed ?? this.processed, total: total ?? this.total, progress: progress ?? this.progress, cancelling: cancelling ?? this.cancelling, status: status ?? this.status, resultMessage: resultMessage ?? this.resultMessage, error: error ?? this.error, skippedRows: skippedRows ?? this.skippedRows);
  }
}

class _EmptyClients extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onCreate;
  const _EmptyClients({required this.hasSearch, required this.onCreate});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(hasSearch ? Icons.search_off_rounded : Icons.people_outline, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text(hasSearch ? 'No matches.' : 'No clients yet.', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)), if (!hasSearch && AuthService.isSuperAdmin) ...[const SizedBox(height: 24), ElevatedButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('Create First Client'))]]));
  }
}
