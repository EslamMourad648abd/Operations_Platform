// import 'package:bbc_api_tool/models/api_preset.dart';
// import 'package:bbc_api_tool/models/api_prest_group.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart'; // 🔸 Added for opening admin console link
// import '../data/postman_loader.dart';
// import 'widgets/request_editor.dart';
// import 'dart:html' as html; // ⬅️ add this at the top
//
//
// class HomeDashboard extends StatefulWidget {
//   const HomeDashboard({super.key});
//
//   @override
//   State<HomeDashboard> createState() => _HomeDashboardState();
// }
//
// class _HomeDashboardState extends State<HomeDashboard> {
//   List<ApiPresetGroup> groups = [];
//   bool loading = true;
//   String? error;
//   dynamic selectedPreset;
//   // 🔸 Add flag for Superadmin status
//   bool isSuperAdmin = false;
//   bool _disposed = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadCollection();
//     _checkSuperAdmin(); // 🔸 Check user role when page loads
//   }
//   @override
//   void dispose() {
//     _disposed = true; // 🟢 Mark as disposed
//     super.dispose();
//   }
//   // 🔸 Function to check custom claims
//   Future<void> _checkSuperAdmin() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       final tokenResult = await user.getIdTokenResult(true);
//       final claims = tokenResult.claims ?? {};
//       if (!_disposed && mounted) { // 🟢 Prevent setState after dispose
//         setState(() {
//           isSuperAdmin = claims['superadmin'] == true;
//         });
//       }
//       debugPrint('👑 Superadmin status: $isSuperAdmin');
//     }
//   }
//
//   // 🔸 Function to open Admin Console in new tab
//   Future<void> _openAdminConsole() async {
//     final baseUrl = Uri.base.origin; // gets current domain dynamically
//     html.window.open('$baseUrl/admin-console', '_blank'); // open new tab
//   }
//
//
//   Future<void> _loadCollection() async {
//     try {
//       final loadedGroups = await PostmanLoader.loadFromAssets(
//         'lib/assets/BBC_Request.postman_collection.json',
//       );
//       if (!_disposed && mounted) { // 🟢 Safety check
//
//         setState(() {
//           groups = loadedGroups;
//           loading = false;
//         });
//       }
//     } catch (e) {
//       if (!_disposed && mounted) { // 🟢 Safety check
//
//         setState(() {
//           error = e.toString();
//           loading = false;
//         });
//       }
//     }
//   }
//
//   /// 🔹 Logout functionality
//   Future<void> _logout() async {
//     try {
//       await FirebaseAuth.instance.signOut();
//       if (mounted) {
//         Navigator.of(context).pushReplacementNamed('/login');
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Logout failed: $e"),
//           backgroundColor: Colors.redAccent,
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     const gradientStart = Color(0xFF001C38);
//     const gradientEnd = Color(0xFF80CFFF);
//     const sidebarTextTop = Colors.white;
//     const sidebarTextBottom = Color(0xFF001C38);
//     const mainBgColor = Color(0xFFF6F8FA);
//     const cardBorder = Color(0xFFE0E5EC);
//     const accentColor = Color(0xFF001C38);
//
//     if (loading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }
//
//     if (error != null) {
//       return Scaffold(
//         body: Center(child: Text('❌ Failed to load: $error')),
//       );
//     }
//
//     return Scaffold(
//       backgroundColor: mainBgColor,
//       body: Row(
//         children: [
//           // 🧭 Sidebar
//           Container(
//             width: 280,
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                   Color(0xCC001C38), // slightly transparent dark overlay
//                   Color(0xCC80CFFF), // ensures white text contrast
//                 ],
//               ),
//             ),
//             child: ListView(
//               children: [
//                 // 🔹 LOGO HEADER + Logout Button
//                 DrawerHeader(
//                   margin: EdgeInsets.zero,
//                   padding: const EdgeInsets.all(12),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Image.asset(
//                               'lib/assets/logo.png',
//                               height: 70,
//                               fit: BoxFit.contain,
//                             ),
//                             const SizedBox(height: 8),
//                             const Text(
//                               "BBC API Collections",
//                               style: TextStyle(
//                                 fontSize: 17,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                                 letterSpacing: 0.8,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                             const SizedBox(height: 10),
//
//                           ],
//                         ),
//                       ),
//                       // 🔸 Super Admin Console Button
//                       if (isSuperAdmin)
//                         IconButton(
//                           tooltip: "Admin Console",
//                           icon: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
//                           onPressed: _openAdminConsole,
//                         ),
//                       // 🚪 Logout Button
//                       IconButton(
//                         tooltip: "Logout",
//                         icon: const Icon(Icons.logout, color: Colors.white),
//                         onPressed: _logout,
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 // 🔹 Groups
//                 for (final group in groups)
//                   Container(
//                     margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.12), // slightly brighter card
//                       borderRadius: BorderRadius.circular(10),
//                       border: Border.all(color: Colors.white24, width: 1),
//                     ),
//                     child: Theme(
//                       data: Theme.of(context).copyWith(
//                         dividerColor: Colors.transparent,
//                         splashColor: Colors.transparent,
//                         highlightColor: Colors.transparent,
//                         iconTheme: const IconThemeData(color: Colors.white),
//                       ),
//                       child: ExpansionTile(
//                         collapsedIconColor: Colors.white,
//                         iconColor: Colors.white,
//                         tilePadding: const EdgeInsets.symmetric(horizontal: 12),
//                         title: Text(
//                           group.name,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 15,
//                             letterSpacing: 0.3,
//                           ),
//                         ),
//                         childrenPadding: const EdgeInsets.only(bottom: 8),
//                         children: group.presets.map((preset) {
//                           final bool isSelected = selectedPreset == preset;
//                           return ListTile(
//                             dense: true,
//                             title: Text(
//                               preset.name,
//                               style: TextStyle(
//                                 color: isSelected
//                                     ? Colors.white
//                                     : Colors.white.withOpacity(0.85),
//                                 fontWeight: isSelected
//                                     ? FontWeight.bold
//                                     : FontWeight.w600,
//                                 fontSize: 14,
//                               ),
//                             ),
//                             onTap: () => setState(() {
//                               selectedPreset = ApiPreset(
//                                 id: preset.id,
//                                 name: preset.name,
//                                 method: preset.method,
//                                 url: preset.url,
//                                 headers: Map<String, String>.from(preset.headers),
//                                 params: Map<String, String>.from(preset.params),
//                                 body: preset.body,
//                                 editableFields:
//                                 Map<String, bool>.from(preset.editableFields),
//                                 urlVariables: List<String>.from(preset.urlVariables),
//                                 authType: preset.authType,
//                                 authToken: preset.authToken,
//                               );
//                             }),
//                           );
//                         }).toList(),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//
//           // 🧰 Main Area
//           Expanded(
//             child: AnimatedSwitcher(
//               duration: const Duration(milliseconds: 300),
//               switchInCurve: Curves.easeInOut,
//               switchOutCurve: Curves.easeInOut,
//               layoutBuilder: (currentChild, previousChildren) {
//                 return Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     for (final child in previousChildren)
//                       Offstage(offstage: true, child: child),
//                     if (currentChild != null) currentChild,
//                   ],
//                 );
//               },
//               child: selectedPreset == null
//                   ? Center(
//                 key: const ValueKey('default'),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Image.asset(
//                       'lib/assets/backgound_asset.png',
//                       height: 130,
//                       fit: BoxFit.contain,
//                     ),
//                     const SizedBox(height: 16),
//                     const Text(
//                       "Select a request from the sidebar to begin",
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Color(0xFF7C8894),
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               )
//                   : Column(
//                 key: ValueKey(selectedPreset.id),
//                 children: [
//                   // 🔹 Sticky Top Bar
//                   Container(
//                     color: Colors.white,
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 14, vertical: 8),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Expanded(
//                           child: Text(
//                             selectedPreset.name,
//                             style: const TextStyle(
//                               fontSize: 17,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF2C2F36),
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.close,
//                               color: Colors.redAccent),
//                           tooltip: 'Close request',
//                           onPressed: () =>
//                               setState(() => selectedPreset = null),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   // 🔹 Main Request Editor
//                   Expanded(
//                     child: Container(
//                       margin: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: cardBorder, width: 1.2),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black12.withOpacity(0.04),
//                             blurRadius: 8,
//                             offset: const Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                       child: RequestEditor(
//                         key: ValueKey(selectedPreset.id),
//                         preset: selectedPreset,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:bbc_api_tool/models/api_preset.dart';
import 'package:bbc_api_tool/models/api_prest_group.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/postman_loader.dart';
import 'widgets/request_editor.dart';
import 'dart:html' as html; // ⬅️ add this at the top

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  List<ApiPresetGroup> groups = [];
  bool loading = true;
  String? error;
  dynamic selectedPreset;

  String? selectedGroupName; // 🔹 track selected group
  String? selectedCallTitle; // 🔹 track selected call title
  bool isSuperAdmin = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _loadCollection();
    _checkSuperAdmin();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _checkSuperAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final tokenResult = await user.getIdTokenResult(true);
      final claims = tokenResult.claims ?? {};
      if (!_disposed && mounted) {
        setState(() {
          isSuperAdmin = claims['superadmin'] == true;
        });
      }
      debugPrint('👑 Superadmin status: $isSuperAdmin');
    }
  }

  Future<void> _openAdminConsole() async {
    final baseUrl = Uri.base.origin;
    html.window.open('$baseUrl/admin-console', '_blank');
  }

  Future<void> _loadCollection() async {
    try {
      final loadedGroups = await PostmanLoader.loadFromAssets(
        'lib/assets/BBC_Request.postman_collection.json',
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

  // 🔹 Helper to generate a unique key for a preset (call)
  String _callKey(ApiPreset preset) => preset.name;

  @override
  Widget build(BuildContext context) {
    const mainBgColor = Color(0xFFF6F8FA);
    const cardBorder = Color(0xFFE0E5EC);

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(body: Center(child: Text('❌ Failed to load: $error')));
    }

    return Scaffold(
      backgroundColor: mainBgColor,
      body: Row(
        children: [
          // 🧭 Sidebar
          Container(
            width: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xCC001C38), Color(0xCC80CFFF)],
              ),
            ),
            child: ListView(
              children: [
                // 🔹 Header
                DrawerHeader(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'lib/assets/logo.png',
                              height: 70,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "BBC API Collections",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      if (isSuperAdmin)
                        IconButton(
                          tooltip: "Admin Console",
                          icon: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Colors.white,
                          ),
                          onPressed: _openAdminConsole,
                        ),
                      IconButton(
                        tooltip: "Logout",
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: _logout,
                      ),
                    ],
                  ),
                ),

                // 🔹 Groups
                for (final group in groups)
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          selectedGroupName == group.name
                              ? Colors.transparent
                              : Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            selectedGroupName == group.name
                                ? Colors.blueAccent
                                : Colors.white24,
                        width: 1,
                      ),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        iconTheme: const IconThemeData(color: Colors.white),
                      ),
                      child: ExpansionTile(
                        collapsedIconColor: Colors.white,
                        iconColor: Colors.white,
                        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                        title: Text(
                          group.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                        childrenPadding: const EdgeInsets.only(bottom: 8),
                        children:
                            group.presets.map((preset) {
                              final bool isSelected =
                                  selectedCallTitle == _callKey(preset);
                              return ListTile(
                                dense: true,
                                title: Text(
                                  preset.name,
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.black
                                            : Colors.white.withOpacity(0.85),
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                onTap:
                                    () => setState(() {
                                      selectedGroupName = group.name;
                                      selectedCallTitle = _callKey(preset);

                                      selectedPreset = ApiPreset(
                                        id: preset.id,
                                        name: preset.name,
                                        method: preset.method,
                                        url: preset.url,
                                        headers: Map<String, String>.from(
                                          preset.headers,
                                        ),
                                        params: Map<String, String>.from(
                                          preset.params,
                                        ),
                                        body: preset.body,
                                        editableFields: Map<String, bool>.from(
                                          preset.editableFields,
                                        ),
                                        urlVariables: List<String>.from(
                                          preset.urlVariables,
                                        ),
                                        authType: preset.authType,
                                        authToken: preset.authToken,
                                      );
                                    }),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 🧰 Main Area
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    for (final child in previousChildren)
                      Offstage(offstage: true, child: child),
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              child:
                  selectedPreset == null
                      ? Center(
                        key: const ValueKey('default'),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'lib/assets/backgound_asset.png',
                              height: 130,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Select a request from the sidebar to begin",
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF7C8894),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                      : Column(
                        key: ValueKey(selectedPreset.id),
                        children: [
                          // 🔹 Sticky Top Bar
                          Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedPreset.name,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C2F36),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.redAccent,
                                  ),
                                  tooltip: 'Close request',
                                  onPressed:
                                      () => setState(() {
                                        selectedPreset = null;
                                        selectedCallTitle = null;
                                        selectedGroupName = null;
                                      }),
                                ),
                              ],
                            ),
                          ),

                          // 🔹 Main Request Editor
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: cardBorder,
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: RequestEditor(
                                key: ValueKey(selectedPreset.id),
                                preset: selectedPreset,
                              ),
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
