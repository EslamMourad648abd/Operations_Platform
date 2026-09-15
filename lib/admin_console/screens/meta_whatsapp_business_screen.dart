
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../models/meta_waba_model.dart';
import '../models/meta_phone_number_model.dart';
import '../services/meta_business_services.dart';

class MetaWhatsAppBusinessScreen extends StatefulWidget {
final FirebaseFunctions functions;

const MetaWhatsAppBusinessScreen({
super.key,
required this.functions,
});

@override
State<MetaWhatsAppBusinessScreen> createState() =>
_MetaWhatsAppBusinessScreenState();
}

class _MetaWhatsAppBusinessScreenState
extends State<MetaWhatsAppBusinessScreen> {
late final MetaBusinessService _service;
late final TextEditingController _searchController;

MetaWabaSnapshot? _snapshot;
bool _loading = true;
bool _syncing = false;
String? _error;
String _searchQuery = '';

@override
void initState() {
super.initState();

_service = MetaBusinessService(functions: widget.functions);
_searchController = TextEditingController();

_searchController.addListener(() {
if (!mounted) return;

setState(() {
_searchQuery = _normalizeSearchValue(
_searchController.text,
);
});
});

_loadStoredData();
}

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

String _normalizeSearchValue(String value) {
return value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]'), '');
}

Future<void> _loadStoredData() async {
debugPrint('➡️ UI: User pressed reload stored data');

setState(() {
_loading = true;
_error = null;
});

try {
final snapshot = await _service.loadStoredAccounts();

debugPrint('✅ LOAD STORED DATA RESPONSE:');
debugPrint('   Total Accounts: ${snapshot.totalAccounts}');
debugPrint(
'   Total Phone Numbers: ${snapshot.totalPhoneNumbers}',
);
debugPrint('   Updated At: ${snapshot.updatedAt}');

for (var acc in snapshot.accounts) {
debugPrint(
'   - Account: ${acc.name} (${acc.id})',
);

for (var phone in acc.phoneNumbers) {
debugPrint(
'     • Phone: ${phone.displayPhoneNumber} '
'(ID: ${phone.id}) | Status: ${phone.status}',
);
}
}

if (!mounted) return;

setState(() {
_snapshot = snapshot;
_loading = false;
});
} on FirebaseFunctionsException catch (e) {
debugPrint(
'❌ LOAD STORED DATA ERROR (Firebase): '
'${e.message} (${e.code})',
);

if (!mounted) return;

setState(() {
_error = e.message ?? e.code;
_loading = false;
});
} catch (e) {
debugPrint(
'❌ LOAD STORED DATA ERROR (Unknown): $e',
);

if (!mounted) return;

setState(() {
_error = e.toString();
_loading = false;
});
}
}

Future<void> _syncFromMeta() async {
if (_syncing) return;

debugPrint('➡️ UI: User pressed Sync from Meta');

setState(() {
_syncing = true;
_error = null;
});

try {
final snapshot = await _service.syncAccounts();

debugPrint('✅ SYNC FROM META RESPONSE:');
debugPrint('   Total Accounts: ${snapshot.totalAccounts}');
debugPrint(
'   Total Phone Numbers: ${snapshot.totalPhoneNumbers}',
);

for (var acc in snapshot.accounts) {
debugPrint(
'   - Account: ${acc.name} (${acc.id})',
);

for (var phone in acc.phoneNumbers) {
debugPrint(
'     • Phone: ${phone.displayPhoneNumber} '
'(ID: ${phone.id}) | Status: ${phone.status}',
);
}
}

if (!mounted) return;

setState(() {
_snapshot = snapshot;
_syncing = false;
});

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
duration: const Duration(seconds: 10),
behavior: SnackBarBehavior.floating,
content: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Meta Sync Complete',
style: TextStyle(
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 4),
Text(
'Accounts: ${snapshot.totalAccounts}',
),
Text(
'Phone Numbers: ${snapshot.totalPhoneNumbers}',
),
const SizedBox(height: 4),
const Text(
'Data successfully fetched from Meta Graph API and stored in Firestore.',
style: TextStyle(fontSize: 12),
),
],
),
action: SnackBarAction(
label: 'Dismiss',
onPressed: () {},
),
),
);
} on FirebaseFunctionsException catch (e) {
debugPrint(
'❌ SYNC FROM META ERROR (Firebase): '
'${e.message} (${e.code})',
);

if (!mounted) return;

setState(() {
_error = e.message ?? e.code;
_syncing = false;
});
} catch (e) {
debugPrint(
'❌ SYNC FROM META ERROR (Unknown): $e',
);

if (!mounted) return;

setState(() {
_error = e.toString();
_syncing = false;
});
}
}

List<_FilteredWaba> _getFilteredAccounts(
MetaWabaSnapshot snapshot,
) {
if (_searchQuery.isEmpty) {
return snapshot.accounts
    .map(
(account) => _FilteredWaba(
account: account,
phoneNumbers: account.phoneNumbers,
),
)
    .toList();
}

final results = <_FilteredWaba>[];

for (final account in snapshot.accounts) {
final accountId = _normalizeSearchValue(
account.id,
);

final wabaMatches =
accountId.contains(_searchQuery);

if (wabaMatches) {
results.add(
_FilteredWaba(
account: account,
phoneNumbers: account.phoneNumbers,
),
);

continue;
}

final matchingPhones =
account.phoneNumbers.where((phone) {
final displayPhone = _normalizeSearchValue(
phone.displayPhoneNumber,
);

final phoneId = _normalizeSearchValue(
phone.id,
);

return displayPhone.contains(_searchQuery) ||
phoneId.contains(_searchQuery);
}).toList();

if (matchingPhones.isNotEmpty) {
results.add(
_FilteredWaba(
account: account,
phoneNumbers: matchingPhones,
),
);
}
}

return results;
}

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);

return Scaffold(
backgroundColor: theme.colorScheme.surface,
appBar: AppBar(
backgroundColor: theme.colorScheme.surface,
elevation: 0,
title: const Text(
'Meta WhatsApp Business',
style: TextStyle(
fontWeight: FontWeight.bold,
),
),
actions: [
IconButton(
tooltip: 'Reload stored data',
onPressed:
_loading || _syncing ? null : _loadStoredData,
icon: const Icon(Icons.refresh),
),
Padding(
padding: const EdgeInsets.only(right: 16),
child: FilledButton.icon(
onPressed:
_syncing ? null : _syncFromMeta,
icon: _syncing
? const SizedBox(
width: 16,
height: 16,
child: CircularProgressIndicator(
strokeWidth: 2,
),
)
    : const Icon(Icons.sync),
label: Text(
_syncing
? 'Syncing...'
    : 'Sync from Meta',
),
),
),
],
),
body: _buildBody(theme),
);
}

Widget _buildBody(ThemeData theme) {
if (_loading) {
return const Center(
child: CircularProgressIndicator(),
);
}

if (_error != null) {
return Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(
Icons.error_outline,
color: Colors.red,
size: 48,
),
const SizedBox(height: 12),
Text(
_error!,
textAlign: TextAlign.center,
),
const SizedBox(height: 16),
FilledButton.icon(
onPressed: _loadStoredData,
icon: const Icon(Icons.refresh),
label: const Text('Retry'),
),
],
),
),
);
}

final snapshot = _snapshot ??
const MetaWabaSnapshot(
totalAccounts: 0,
totalPhoneNumbers: 0,
updatedAt: null,
accounts: [],
);

final filteredAccounts =
_getFilteredAccounts(snapshot);

final filteredPhoneCount =
filteredAccounts.fold<int>(
0,
(total, item) =>
total + item.phoneNumbers.length,
);

return RefreshIndicator(
onRefresh: _loadStoredData,
child: ListView(
padding: const EdgeInsets.all(24),
children: [
_buildSummary(theme, snapshot),
const SizedBox(height: 24),
_buildSearchField(theme),
const SizedBox(height: 16),

if (_searchQuery.isNotEmpty)
Padding(
padding: const EdgeInsets.only(
bottom: 16,
),
child: Text(
filteredAccounts.isEmpty
? 'No matching WABA accounts or phone numbers found.'
    : 'Showing ${filteredAccounts.length} '
'WABA account'
'${filteredAccounts.length == 1 ? '' : 's'} '
'and $filteredPhoneCount matching phone number'
'${filteredPhoneCount == 1 ? '' : 's'}.',
style: TextStyle(
color: theme.colorScheme.onSurface
    .withValues(alpha: .65),
fontSize: 13,
),
),
),

if (snapshot.accounts.isEmpty)
_buildEmptyState(theme)
else if (filteredAccounts.isEmpty)
_buildNoSearchResults(theme)
else
...filteredAccounts.map(
(item) => Padding(
padding: const EdgeInsets.only(
bottom: 12,
),
child: _WabaCard(
account: item.account,
phoneNumbers: item.phoneNumbers,
),
),
),
],
),
);
}

Widget _buildSearchField(ThemeData theme) {
return TextField(
controller: _searchController,
textInputAction: TextInputAction.search,
decoration: InputDecoration(
hintText:
'Search by phone number or WABA ID',
prefixIcon: const Icon(Icons.search),
suffixIcon: _searchQuery.isEmpty
? null
    : IconButton(
tooltip: 'Clear search',
onPressed:
_searchController.clear,
icon: const Icon(Icons.clear),
),
filled: true,
fillColor: theme.colorScheme
    .surfaceContainerHighest
    .withValues(alpha: .35),
border: OutlineInputBorder(
borderRadius:
BorderRadius.circular(12),
borderSide: BorderSide(
color: theme.dividerColor,
),
),
enabledBorder: OutlineInputBorder(
borderRadius:
BorderRadius.circular(12),
borderSide: BorderSide(
color: theme.dividerColor,
),
),
focusedBorder: OutlineInputBorder(
borderRadius:
BorderRadius.circular(12),
borderSide: BorderSide(
color: theme.colorScheme.primary,
width: 1.5,
),
),
),
);
}

Widget _buildSummary(
ThemeData theme,
MetaWabaSnapshot snapshot,
) {
return Wrap(
spacing: 12,
runSpacing: 12,
children: [
_SummaryCard(
icon: Icons.business,
title: 'WABA Accounts',
value:
snapshot.totalAccounts.toString(),
),
_SummaryCard(
icon: Icons.phone,
title: 'Phone Numbers',
value: snapshot.totalPhoneNumbers
    .toString(),
),
_SummaryCard(
icon: Icons.update,
title: 'Last Sync',
value:
_formatDate(snapshot.updatedAt),
),
],
);
}

String _formatDate(String? value) {
if (value == null || value.isEmpty) {
return 'Never';
}

final date = DateTime.tryParse(value);

if (date == null) return value;

final local = date.toLocal();

return '${local.year}-'
'${local.month.toString().padLeft(2, '0')}-'
'${local.day.toString().padLeft(2, '0')} '
'${local.hour.toString().padLeft(2, '0')}:'
'${local.minute.toString().padLeft(2, '0')}';
}

Widget _buildEmptyState(ThemeData theme) {
return Container(
padding: const EdgeInsets.all(32),
decoration: BoxDecoration(
border: Border.all(
color: theme.dividerColor,
),
borderRadius:
BorderRadius.circular(12),
),
child: const Column(
children: [
Icon(
Icons.cloud_download_outlined,
size: 48,
),
SizedBox(height: 12),
Text(
'No stored Meta data yet.',
style: TextStyle(
fontWeight: FontWeight.bold,
),
),
SizedBox(height: 6),
Text(
'Use "Sync from Meta" to create the first snapshot.',
textAlign: TextAlign.center,
),
],
),
);
}

Widget _buildNoSearchResults(
ThemeData theme,
) {
return Container(
padding: const EdgeInsets.all(32),
decoration: BoxDecoration(
border: Border.all(
color: theme.dividerColor,
),
borderRadius:
BorderRadius.circular(12),
),
child: const Column(
children: [
Icon(
Icons.search_off,
size: 48,
),
SizedBox(height: 12),
Text(
'No matching results.',
style: TextStyle(
fontWeight: FontWeight.bold,
),
),
SizedBox(height: 6),
Text(
'Try searching with a phone number or WABA ID.',
textAlign: TextAlign.center,
),
],
),
);
}
}

class _FilteredWaba {
final MetaWabaModel account;
final List<MetaPhoneNumberModel> phoneNumbers;

const _FilteredWaba({
required this.account,
required this.phoneNumbers,
});
}

class _SummaryCard extends StatelessWidget {
final IconData icon;
final String title;
final String value;

const _SummaryCard({
required this.icon,
required this.title,
required this.value,
});

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);

return Container(
width: 220,
padding: const EdgeInsets.all(18),
decoration: BoxDecoration(
color: theme.colorScheme.surface,
border: Border.all(
color: theme.dividerColor,
),
borderRadius:
BorderRadius.circular(12),
),
child: Row(
children: [
Icon(
icon,
color: theme.colorScheme.primary,
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
title,
style: TextStyle(
color: theme.colorScheme
    .onSurface
    .withValues(alpha: .65),
fontSize: 12,
),
),
const SizedBox(height: 4),
Text(
value,
overflow:
TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 18,
fontWeight:
FontWeight.bold,
),
),
],
),
),
],
),
);
}
}

class _WabaCard extends StatelessWidget {
final MetaWabaModel account;
final List<MetaPhoneNumberModel> phoneNumbers;

const _WabaCard({
required this.account,
required this.phoneNumbers,
});

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);

return Card(
elevation: 0,
margin: EdgeInsets.zero,
shape: RoundedRectangleBorder(
side: BorderSide(
color: theme.dividerColor,
),
borderRadius:
BorderRadius.circular(12),
),
child: ExpansionTile(
tilePadding:
const EdgeInsets.symmetric(
horizontal: 18,
vertical: 4,
),
childrenPadding:
const EdgeInsets.fromLTRB(
18,
0,
18,
18,
),
title: Text(
account.name.isEmpty
? 'Unnamed WABA'
    : account.name,
style: const TextStyle(
fontWeight: FontWeight.bold,
),
),
subtitle: Padding(
padding:
const EdgeInsets.only(top: 4),
child: Text(
'ID: ${account.id}  •  Limit: '
'${account.messagingLimit.isEmpty ? 'N/A' : account.messagingLimit}',
),
),
children: phoneNumbers.isEmpty
? [
const Align(
alignment:
Alignment.centerLeft,
child: Text(
'No phone numbers found.',
),
),
]
    : phoneNumbers
    .map(
(phone) => _PhoneNumberRow(
phone: phone,
),
)
    .toList(),
),
);
}
}

class _PhoneNumberRow extends StatelessWidget {
final MetaPhoneNumberModel phone;

const _PhoneNumberRow({
required this.phone,
});

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);

final quality =
_qualityState(phone.qualityRating);

final status =
_statusState(phone.status);

return Container(
margin: const EdgeInsets.only(top: 8),
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(
color: theme.colorScheme
    .surfaceContainerHighest
    .withValues(alpha: .35),
borderRadius:
BorderRadius.circular(10),
),
child: Wrap(
spacing: 24,
runSpacing: 12,
crossAxisAlignment:
WrapCrossAlignment.center,
children: [
_Info(
label: 'Phone',
value: phone.displayPhoneNumber,
),
_StatusBadge(
label: status.label,
color: status.color,
icon: status.icon,
),
_QualityBadge(
quality: quality,
),
_Info(
label: 'Verified name',
value: phone.verifiedName,
),
_Info(
label: 'Phone ID',
value: phone.id,
),
],
),
);
}

_QualityState _qualityState(
String value,
) {
final normalized =
value.trim().toUpperCase();

switch (normalized) {
case 'GREEN':
return const _QualityState(
label: 'Good',
color: Colors.green,
icon: Icons.check_circle,
);

case 'YELLOW':
return const _QualityState(
label: 'Medium',
color: Colors.amber,
icon: Icons.warning_amber_rounded,
);

case 'RED':
return const _QualityState(
label: 'Poor',
color: Colors.red,
icon: Icons.error,
);

default:
return const _QualityState(
label: 'Unknown',
color: Colors.grey,
icon: Icons.help_outline,
);
}
}

_StatusState _statusState(
String value,
) {
final normalized =
value.trim().toUpperCase();

if (normalized.contains('UNVERIFIED') ||
normalized.contains('NOT_VERIFIED') ||
normalized.contains('VERIFICATION')) {
return const _StatusState(
label: 'Unverified',
color: Colors.red,
icon: Icons.verified_outlined,
);
}

if (normalized.contains('SUSPEND') ||
normalized.contains('BLOCK') ||
normalized.contains('BANN')) {
return const _StatusState(
label: 'Suspended',
color: Colors.red,
icon: Icons.block,
);
}

if (normalized.contains('PENDING') ||
normalized.contains('REGISTERING') ||
normalized.contains('IN_REVIEW')) {
return const _StatusState(
label: 'Pending',
color: Colors.amber,
icon: Icons.hourglass_top,
);
}

if (normalized.contains('CONNECTED') ||
normalized == 'ACTIVE' ||
normalized == 'ONLINE') {
return const _StatusState(
label: 'Connected',
color: Colors.green,
icon: Icons.check_circle,
);
}

if (normalized.contains('DISCONNECTED') ||
normalized.contains('OFFLINE') ||
normalized == 'INACTIVE') {
return const _StatusState(
label: 'Offline',
color: Colors.grey,
icon: Icons.cloud_off,
);
}

return const _StatusState(
label: 'Unknown',
color: Colors.grey,
icon: Icons.help_outline,
);
}
}

class _QualityState {
final String label;
final Color color;
final IconData icon;

const _QualityState({
required this.label,
required this.color,
required this.icon,
});
}

class _StatusState {
final String label;
final Color color;
final IconData icon;

const _StatusState({
required this.label,
required this.color,
required this.icon,
});
}

class _QualityBadge extends StatelessWidget {
final _QualityState quality;

const _QualityBadge({
required this.quality,
});

@override
Widget build(BuildContext context) {
final color = quality.color;

return Container(
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 7,
),
decoration: BoxDecoration(
color: color.withValues(alpha: .12),
border: Border.all(
color: color.withValues(alpha: .35),
),
borderRadius:
BorderRadius.circular(20),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
quality.icon,
size: 16,
color: color,
),
const SizedBox(width: 6),
Text(
'Quality: ${quality.label}',
style: TextStyle(
color: color,
fontSize: 12,
fontWeight: FontWeight.bold,
),
),
],
),
);
}
}

class _StatusBadge extends StatelessWidget {
final String label;
final Color color;
final IconData icon;

const _StatusBadge({
required this.label,
required this.color,
required this.icon,
});

@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 7,
),
decoration: BoxDecoration(
color: color.withValues(alpha: .12),
border: Border.all(
color: color.withValues(alpha: .35),
),
borderRadius:
BorderRadius.circular(20),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
icon,
size: 16,
color: color,
),
const SizedBox(width: 6),
Text(
label,
style: TextStyle(
color: color,
fontSize: 12,
fontWeight: FontWeight.bold,
),
),
],
),
);
}
}

class _Info extends StatelessWidget {
final String label;
final String value;

const _Info({
required this.label,
required this.value,
});

@override
Widget build(BuildContext context) {
return SizedBox(
width: 190,
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
label,
style: const TextStyle(
fontSize: 11,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 2),
Text(
value.isEmpty
? 'N/A'
    : value,
overflow:
TextOverflow.ellipsis,
),
],
),
);
}
}



