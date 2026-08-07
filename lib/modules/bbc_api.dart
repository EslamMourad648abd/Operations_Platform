import 'dart:html' as html;

import 'package:bbc_api_tool/models/api_preset.dart';
import 'package:bbc_api_tool/models/api_prest_group.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/postman_loader.dart';
import '../widgets/request_editor.dart';

class BbcApiHomeScreen extends StatefulWidget {
  const BbcApiHomeScreen({super.key});

  @override
  State<BbcApiHomeScreen> createState() => _BbcApiHomeScreen();
}

class _BbcApiHomeScreen extends State<BbcApiHomeScreen> {
List<ApiPresetGroup> groups = [];

bool loading = true;
String? error;

dynamic selectedPreset;

String? selectedGroupName;
String? selectedCallTitle;

bool isSuperAdmin = false;
bool _disposed = false;

@override
void initState() {
super.initState();
_loadCollection();
}

@override
void dispose() {
_disposed = true;
super.dispose();
}

Future<void> _openAdminConsole() async {
final baseUrl = Uri.base.origin;
html.window.open('$baseUrl/admin-console', '_blank');
}

Future<void> _loadCollection() async {
try {
final loadedGroups = await PostmanLoader.loadFromAssets(
'assets/BBC_Request.postman_collection.json',
);

if (!_disposed && mounted) {
setState(() {
groups = loadedGroups;
loading = false;
});
}
} catch (e) {
if (!_disposed && mounted) {
setState(() {
error = e.toString();
loading = false;
});
}
}
}

Future<void> _logout() async {
try {
await FirebaseAuth.instance.signOut();

if (mounted) {
Navigator.of(context).pushReplacementNamed('/login');
}
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text("Logout failed: $e"),
backgroundColor: Colors.redAccent,
),
);
}
}

String _callKey(ApiPreset preset) => preset.name;

@override
Widget build(BuildContext context) {
const mainBgColor = Color(0xffF5F8FC);
const primaryColor = Color(0xff003366);
const accentColor = Color(0xff80CFFF);
const cardBorder = Color(0xFFE4E9F0);

if (loading) {
return const Scaffold(
body: Center(
child: CircularProgressIndicator(),
),
);
}

if (error != null) {
return Scaffold(
body: Center(
child: Text("❌ Failed to load: $error"),
),
);
}

return Scaffold(
backgroundColor: mainBgColor,
body: Row(
children: [

Container(
width: 310,
decoration: const BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
colors: [
primaryColor,
accentColor,
],
),
),

child: Column(
children: [

SafeArea(
bottom: false,
child: Padding(
padding: const EdgeInsets.fromLTRB(
18,
20,
18,
20,
),

child: Row(
crossAxisAlignment:
CrossAxisAlignment.center,

children: [

Container(
decoration: BoxDecoration(
color: Colors.white.withOpacity(.12),
borderRadius:
BorderRadius.circular(12),
),
child: IconButton(
icon: const Icon(
Icons.arrow_back,
color: Colors.white,
),
tooltip: "Back",
onPressed: () {
Navigator.pop(context);
},
),
),

const SizedBox(width: 14),

Expanded(
child: Column(
children: [

Image.asset(
"assets/logo.png",
height: 58,
),

const SizedBox(height: 10),

const Text(
"BBC API Collections",
textAlign: TextAlign.center,
style: TextStyle(
color: Colors.white,
fontWeight: FontWeight.bold,
fontSize: 18,
),
),
],
),
),

Container(
decoration: BoxDecoration(
color: Colors.white.withOpacity(.12),
borderRadius:
BorderRadius.circular(12),
),
),
],
),
),
),

const Divider(
color: Colors.white24,
height: 1,
),

Expanded(
child: ListView.builder(
padding: const EdgeInsets.symmetric(
horizontal: 12,
vertical: 18,
),

itemCount: groups.length,

itemBuilder: (context, index) {

final group = groups[index];

final selected =
selectedGroupName == group.name;

return Container(
margin: const EdgeInsets.only(
bottom: 14,
),

decoration: BoxDecoration(
color: Colors.white.withOpacity(
selected ? .20 : .10,
),

borderRadius:
BorderRadius.circular(18),

border: Border.all(
color: selected
? Colors.white
: Colors.white24,
),
),

child: Theme(
data: Theme.of(context).copyWith(
dividerColor:
Colors.transparent,
splashColor:
Colors.transparent,
highlightColor:
Colors.transparent,
),

child: ExpansionTile(
collapsedIconColor:
Colors.white,

iconColor:
Colors.white,

tilePadding:
const EdgeInsets.symmetric(
horizontal: 18,
),

title: Text(
group.name,
style: const TextStyle(
color: Colors.white,
fontWeight:
FontWeight.w700,
fontSize: 15,
),
),

children: group.presets.map((preset) {

final isSelected =
selectedCallTitle ==
_callKey(preset);

return Container(
margin:
const EdgeInsets.symmetric(
horizontal: 10,
vertical: 4,
),

decoration: BoxDecoration(
color: isSelected
? Colors.white
: Colors.transparent,

borderRadius:
BorderRadius.circular(
10),
),

child: ListTile(
dense: true,

shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(
10),
),

title: Text(
preset.name,

style: TextStyle(
color: isSelected
? primaryColor
: Colors.white,

fontWeight: isSelected
? FontWeight.bold
: FontWeight.w500,
),
),

onTap: () {
setState(() {
selectedGroupName =
group.name;

selectedCallTitle =
_callKey(preset);

selectedPreset =
ApiPreset(
id: preset.id,
name: preset.name,
method: preset.method,
url: preset.url,
headers:
Map<String,
String>.from(
preset.headers),
params:
Map<String,
String>.from(
preset.params),
body: preset.body,
editableFields:
Map<String,
bool>.from(
preset.editableFields),
urlVariables:
List<String>.from(
preset.urlVariables),
authType:
preset.authType,
authToken:
preset.authToken,
);
});
},
),
);
}).toList(),
),
),
);
},
),
),
],
),
),

// 🧰 Main Area
  Expanded(
    child: Container(
      color: mainBgColor,
      padding: const EdgeInsets.all(24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.center,
            children: [
              for (final child in previousChildren)
                Offstage(
                  offstage: true,
                  child: child,
                ),
              if (currentChild != null) currentChild,
            ],
          );
        },

        child: selectedPreset == null

            ? Center(
          key: const ValueKey("empty"),

          child: Container(
            constraints:
            const BoxConstraints(maxWidth: 500),

            padding: const EdgeInsets.all(40),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(24),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Image.asset(
                  "assets/backgound_asset.png",
                  height: 160,
                ),

                const SizedBox(height: 28),

                const Text(
                  "BBC API Collections",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  "Select a request from the left sidebar to start testing APIs.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        )

            : Column(
          key: ValueKey(selectedPreset.id),
          children: [

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 18,
              ),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(18),

                border: Border.all(
                  color: cardBorder,
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.04),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),

              child: Row(
                children: [

                  const Icon(
                    Icons.api,
                    color: primaryColor,
                    size: 28,
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Text(
                      selectedPreset.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  IconButton(
                    tooltip: "Close",

                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.redAccent,
                    ),

                    onPressed: () {
                      setState(() {
                        selectedPreset = null;
                        selectedGroupName = null;
                        selectedCallTitle = null;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                  BorderRadius.circular(20),

                  border: Border.all(
                    color: cardBorder,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.04),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),

                child: ClipRRect(
                  borderRadius:
                  BorderRadius.circular(20),

                  child: RequestEditor(
                    key: ValueKey(selectedPreset.id),
                    preset: selectedPreset,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
],
),
);
}
}