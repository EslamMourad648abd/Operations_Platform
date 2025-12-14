// lib/ui/super_admin_console.dart
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class SuperAdminConsole extends StatefulWidget {
  const SuperAdminConsole({Key? key}) : super(key: key);

  @override
  State<SuperAdminConsole> createState() => _SuperAdminConsoleState();
}

class _SuperAdminConsoleState extends State<SuperAdminConsole> {
  FirebaseFunctions? _functions;
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  String searchQuery = '';
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _initializeFunctions();
  }

  /// ✅ Initialize Firebase and Functions
  Future<void> _initializeFunctions() async {
    try {
      await Firebase.initializeApp();
      await FirebaseAuth.instance.authStateChanges().firstWhere(
        (_) => true,
        orElse: () => null,
      );

      final app = Firebase.app();
      _functions = FirebaseFunctions.instanceFor(
        app: app,
        region: 'us-central1',
      );
      await _loadUsers();
    } catch (e, st) {
      debugPrint('❌ Firebase init error: $e\n$st');
      setState(() {
        error = 'Firebase initialization failed: $e';
        loading = false;
      });
    }
  }

  /// 🔹 Load all users
  Future<void> _loadUsers() async {
    if (_functions == null) {
      setState(() {
        error = 'Firebase Functions not initialized yet.';
        loading = false;
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final callable = _functions!.httpsCallable('listUsers');
      final result = await callable();
      final data = result.data;

      if (data is Map && data['users'] is List) {
        final allUsers = List<Map<String, dynamic>>.from(data['users']);
        setState(() {
          users = allUsers;
          filteredUsers = allUsers;
          loading = false;
        });
      } else {
        throw Exception('Invalid data format from Cloud Function.');
      }
    } catch (e, st) {
      debugPrint('🔥 listUsers failed: $e\n$st');
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  /// 🔍 Search filter
  void _applySearchFilter(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      if (query.isEmpty) {
        filteredUsers = users;
      } else {
        filteredUsers =
            users.where((u) {
              final email = (u['email'] ?? '').toString().toLowerCase();
              final name = (u['displayName'] ?? '').toString().toLowerCase();
              return email.contains(searchQuery) || name.contains(searchQuery);
            }).toList();
      }
    });
  }

  /// ➕ Add new user
  Future<void> _showAddUserDialog() async {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool superadmin = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setStateDialog) => AlertDialog(
                title: const Text('Add New User'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      TextField(
                        controller: passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: superadmin,
                            onChanged:
                                (v) => setStateDialog(
                                  () => superadmin = v ?? false,
                                ),
                          ),
                          const Text('Grant Superadmin Role'),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF001C38),
                    ),
                    onPressed: () async {
                      try {
                        final callable = _functions!.httpsCallable(
                          'createUser',
                        );
                        await callable({
                          'email': emailCtrl.text.trim(),
                          'password': passCtrl.text.trim(),
                          'superadmin': superadmin,
                        });
                        Navigator.pop(context);
                        _loadUsers();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ User created successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
        );
      },
    );
  }

  /// ✏️ Edit user
  Future<void> _showEditUserDialog(Map<String, dynamic> user) async {
    final emailCtrl = TextEditingController(text: user['email'] ?? '');
    final passCtrl = TextEditingController();
    bool superadmin = user['superadmin'] ?? false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setStateDialog) => AlertDialog(
                title: const Text('Edit User'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      TextField(
                        controller: passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New Password (leave blank to keep)',
                        ),
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: superadmin,
                            onChanged:
                                (v) => setStateDialog(
                                  () => superadmin = v ?? false,
                                ),
                          ),
                          const Text('Superadmin Role'),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF001C38),
                    ),
                    onPressed: () async {
                      try {
                        final updateUser = _functions!.httpsCallable(
                          'updateUser',
                        );
                        await updateUser({
                          'uid': user['uid'],
                          'email': emailCtrl.text.trim(),
                          if (passCtrl.text.trim().isNotEmpty)
                            'password': passCtrl.text.trim(),
                        });

                        final setRole = _functions!.httpsCallable(
                          'setUserRole',
                        );
                        await setRole({
                          'uid': user['uid'],
                          'superadmin': superadmin,
                        });

                        Navigator.pop(context);
                        _loadUsers();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ User updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error updating user: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
        );
      },
    );
  }

  /// 🗑️ Delete user
  Future<void> _deleteUser(String uid) async {
    try {
      final callable = _functions!.httpsCallable('deleteUser');
      await callable({'uid': uid});
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting user: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// 🔄 Toggle SuperAdmin
  Future<void> _toggleSuperAdmin(String uid, bool currentStatus) async {
    try {
      final callable = _functions!.httpsCallable('setUserRole');
      await callable({'uid': uid, 'superadmin': !currentStatus});
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating role: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleUsers = searchQuery.isEmpty ? users : filteredUsers;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2F7),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(
                child: Text(
                  '❌ $error',
                  style: const TextStyle(fontSize: 16, color: Colors.redAccent),
                ),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🧭 Header with title, search, and logout
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "User Management",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF001C38),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 280,
                          child: TextField(
                            onChanged: _applySearchFilter,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              hintText: 'Search by email or name...',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF001C38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          onPressed: _showAddUserDialog,
                          icon: const Icon(
                            Icons.person_add_alt_1,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Add User",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF001C38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          },
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: const Text(
                            "Logout",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 🌐 Table headers
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF80CFFF),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Center(
                              child: Text(
                                'Email',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                'Super Admin',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Center(
                              child: Text(
                                'Actions',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                      ),
                    ),
                  ),

                  // 🧾 User list
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        separatorBuilder:
                            (_, __) =>
                                const Divider(height: 1, color: Colors.grey),
                        itemCount: visibleUsers.length,
                        itemBuilder: (context, index) {
                          final u = visibleUsers[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    u['email'] ?? '—',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Icon(
                                      u['superadmin']
                                          ? Icons.check_circle
                                          : Icons.remove_circle,
                                      color:
                                          u['superadmin']
                                              ? Colors.green
                                              : Colors.redAccent,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        tooltip: 'Edit User',
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Color(0xFF1F5B8A),
                                        ),
                                        onPressed: () => _showEditUserDialog(u),
                                      ),
                                      IconButton(
                                        tooltip: 'Toggle SuperAdmin',
                                        icon: const Icon(
                                          Icons.admin_panel_settings_rounded,
                                          color: Color(0xFF001C38),
                                        ),
                                        onPressed:
                                            () => _toggleSuperAdmin(
                                              u['uid'],
                                              u['superadmin'],
                                            ),
                                      ),
                                      IconButton(
                                        tooltip: 'Delete User',
                                        icon: const Icon(
                                          Icons.delete_forever,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () => _deleteUser(u['uid']),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
