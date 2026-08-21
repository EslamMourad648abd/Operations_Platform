import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
class UserManagement extends StatefulWidget {
  final FirebaseFunctions functions;
  const UserManagement({
    super.key,
    required this.functions,
  });
  @override
  State<UserManagement> createState() =>
      _UserManagementState();
}
class _UserManagementState extends State<UserManagement> {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool loading = true;
  String? error;
  String searchQuery = "";
  // ============================================================
  // INIT
  // ============================================================
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
  // ============================================================
  // LOAD USERS
  // ============================================================
  Future<void> _loadUsers() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final callable = widget.functions.httpsCallable(
        "listUsers",
      );
      final result = await callable();
      final data = result.data;
      if (data is Map && data["users"] is List) {
        final loaded =
        List<Map<String, dynamic>>.from(
          data["users"],
        );
        if (!mounted) return;
        setState(() {
          users = loaded;
          filteredUsers = loaded;
          loading = false;
        });
      } else {
        throw Exception(
          "Invalid users response",
        );
      }
    } catch (e) {
      debugPrint(
        "LOAD USERS ERROR: $e",
      );
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }
  // ============================================================
  // MIGRATE EXISTING USERS ROLES TO FIRESTORE
  // ============================================================
  Future<void> _migrateUserRoles() async {
    try {
      final callable =
      widget.functions.httpsCallable(
        "migrateUserRolesToFirestore",
      );
      final result = await callable();
      _showMessage(
        result.data["message"] ??
            "Roles migrated successfully",
        Colors.green,
      );
      await _loadUsers();
    } catch (e) {
      _showMessage(
        "Migration failed: $e",
        Colors.red,
      );
    }
  }
  // ============================================================
  // SEARCH
  // ============================================================
  void _searchUsers(String value) {
    setState(() {
      searchQuery = value.toLowerCase();
      if (value.isEmpty) {
        filteredUsers = users;
      } else {
        filteredUsers = users.where((user) {
          final email = (user["email"] ?? "")
              .toString()
              .toLowerCase();
          final name = (user["displayName"] ?? "")
              .toString()
              .toLowerCase();
          return email.contains(searchQuery) ||
              name.contains(searchQuery);
        }).toList();
      }
    });
  }
  // ============================================================
  // ADD USER
  // ============================================================
  Future<void> _addUser(
      Map<String, dynamic> data,
      ) async {
    try {
      final callable =
      widget.functions.httpsCallable(
        "createUser",
      );
      await callable(data);
      _showMessage(
        "User created successfully",
        Colors.green,
      );
      await _loadUsers();
    } catch (e) {
      _showMessage(
        e.toString(),
        Colors.red,
      );
    }
  }
  // ============================================================
  // EDIT USER
  // ============================================================
  Future<void> _editUser(
      Map<String, dynamic> data,
      ) async {
    try {
      final callable =
      widget.functions.httpsCallable(
        "updateUser",
      );
      await callable(data);
      _showMessage(
        "User updated successfully",
        Colors.green,
      );
      await _loadUsers();
    } catch (e) {
      _showMessage(
        e.toString(),
        Colors.red,
      );
    }
  }
  // ============================================================
  // DELETE USER
  // ============================================================
  Future<void> _deleteUser(
      String uid,
      ) async {
    try {
      final callable =
      widget.functions.httpsCallable(
        "deleteUser",
      );
      await callable({
        "uid": uid,
      });
      _showMessage(
        "User deleted",
        Colors.green,
      );
      await _loadUsers();
    } catch (e) {
      _showMessage(
        e.toString(),
        Colors.red,
      );
    }
  }
  // ============================================================
  // UPDATE ROLE
  // ============================================================
  Future<void> _updateRole(
      String uid,
      String role,
      ) async {
    try {
      final callable =
      widget.functions.httpsCallable(
        "setUserRole",
      );
      await callable({
        "uid": uid,
        "role": role,
      });
      await _loadUsers();
    } catch (e) {
      _showMessage(
        e.toString(),
        Colors.red,
      );
    }
  }
  // ============================================================
  // MESSAGE
  // ============================================================
  void _showMessage(
      String text,
      Color color,
      ) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: color,
      ),
    );
  }
  // ============================================================
  // ADD USER DIALOG
  // ============================================================
  void _showAddDialog() {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    String role = "agent";
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
              context,
              setDialogState,
              ) {
            return AlertDialog(
              title: const Text(
                "Add User",
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration:
                    const InputDecoration(
                      labelText: "Name",
                    ),
                  ),
                  TextField(
                    controller: email,
                    decoration:
                    const InputDecoration(
                      labelText: "Email",
                    ),
                  ),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration:
                    const InputDecoration(
                      labelText: "Password",
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration:
                    const InputDecoration(
                      labelText: "Role",
                    ),
                    items: _roles(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        role = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child: const Text(
                    "Cancel",
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _addUser({
                      "displayName":
                      name.text.trim(),
                      "email":
                      email.text.trim(),
                      "password":
                      password.text.trim(),
                      "role": role,
                    });
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child: const Text(
                    "Create",
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  // ============================================================
  // EDIT USER DIALOG
  // ============================================================
  void _showEditDialog(
      Map<String, dynamic> user,
      ) {
    final name = TextEditingController(
      text: user["displayName"] ?? "",
    );
    final email = TextEditingController(
      text: user["email"] ?? "",
    );
    final password = TextEditingController();
    String role =
        user["role"] ?? "agent";
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
              context,
              setDialogState,
              ) {
            return AlertDialog(
              title: const Text(
                "Edit User",
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration:
                    const InputDecoration(
                      labelText: "Name",
                    ),
                  ),
                  TextField(
                    controller: email,
                    decoration:
                    const InputDecoration(
                      labelText: "Email",
                    ),
                  ),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration:
                    const InputDecoration(
                      labelText:
                      "New Password (optional)",
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    value: role,
                    items: _roles(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        role = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child: const Text(
                    "Cancel",
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final data =
                    <String, dynamic>{
                      "uid": user["uid"],
                      "displayName":
                      name.text.trim(),
                      "email":
                      email.text.trim(),
                      "role": role,
                    };
                    if (password.text
                        .trim()
                        .isNotEmpty) {
                      data["password"] =
                          password.text.trim();
                    }
                    _editUser(data);
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child: const Text(
                    "Save",
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  // ============================================================
  // ROLES
  // ============================================================
  List<DropdownMenuItem<String>> _roles() {
    return const [
      DropdownMenuItem(
        value: "agent",
        child: Text(
          "Agent",
        ),
      ),
      DropdownMenuItem(
        value: "trainee",
        child: Text(
          "Trainee",
        ),
      ),
      DropdownMenuItem(
        value: "superadmin",
        child: Text(
          "Super Admin",
        ),
      ),
    ];
  }
  // ============================================================
  // DELETE CONFIRMATION
  // ============================================================
  Future<void> _confirmDelete(
      Map<String, dynamic> user,
      ) async {
    final result =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Delete User",
          ),
          content: Text(
            "Delete ${user["email"]}?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                "Cancel",
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                Colors.red,
                foregroundColor:
                Colors.white,
              ),
              child: const Text(
                "Delete",
              ),
            ),
          ],
        );
      },
    );
    if (result == true) {
      await _deleteUser(
        user["uid"],
      );
    }
  }
  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xffF5F8FC),
      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        title: const Text(
          "User Management",
        ),
        actions: [
          IconButton(
            tooltip: "Refresh Users",
            onPressed:
            loading ? null : _loadUsers,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
          const SizedBox(
            width: 8,
          ),
        ],
      ),
      // ========================================================
      // BODY
      // ========================================================
      body: _buildBody(),
    );
  }
  // ============================================================
  // BODY
  // ============================================================
  Widget _buildBody() {
    // ----------------------------------------------------------
    // Loading
    // ----------------------------------------------------------
    if (loading) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }
    // ----------------------------------------------------------
    // Error
    // ----------------------------------------------------------
    if (error != null) {
      return Center(
        child: Padding(
          padding:
          const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                error!,
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  color: Colors.red,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton.icon(
                onPressed:
                _loadUsers,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  "Retry",
                ),
              ),
            ],
          ),
        ),
      );
    }
    // ----------------------------------------------------------
    // Main Content
    // ----------------------------------------------------------
    return Column(
      children: [
        // ======================================================
        // HEADER
        // ======================================================
        Padding(
          padding:
          const EdgeInsets.all(20),
          child: Row(
            children: [

              const Spacer(),
              // ------------------------------------------------
              // ADD USER
              // ------------------------------------------------
              ElevatedButton.icon(
                onPressed:
                _showAddDialog,
                icon: const Icon(

                  Icons.add,
                ),
                label: const Text(
                  "Add User",
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              // ------------------------------------------------
              // SEARCH
              // ------------------------------------------------
              SizedBox(
                width: 250,
                child: TextField(
                  onChanged:
                  _searchUsers,
                  decoration:
                  const InputDecoration(
                    hintText:
                    "Search",
                    prefixIcon:
                    Icon(
                      Icons.search,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // ======================================================
        // USER LIST
        // ======================================================
        Expanded(
          child:
          filteredUsers.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
            onRefresh:
            _loadUsers,
            child:
            ListView.builder(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding:
              const EdgeInsets.only(
                bottom: 24,
              ),
              itemCount:
              filteredUsers
                  .length,
              itemBuilder:
                  (
                  context,
                  index,
                  ) {
                final user =
                filteredUsers[
                index];
                return _buildUserCard(
                  user,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
  // ============================================================
  // EMPTY STATE
  // ============================================================
  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height:
            MediaQuery.of(context)
                .size
                .height *
                0.35,
          ),
          const Icon(
            Icons.people_outline,
            size: 70,
            color: Color(0xff003366),
          ),
          const SizedBox(
            height: 20,
          ),
          Center(
            child: Text(
              searchQuery.isEmpty
                  ? "No users found"
                  : "No users match your search",
              style:
              const TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
                color:
                Color(0xff003366),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // ============================================================
  // USER CARD
  // ============================================================
  Widget _buildUserCard(
      Map<String, dynamic> user,
      ) {
    final email =
    (user["email"] ?? "")
        .toString()
        .trim();
    final displayName =
    (user["displayName"] ?? "")
        .toString()
        .trim();
    // IMPORTANT:
    // There is NEVER an "Unknown" fallback.
    // If displayName is empty, email is always used.
    final shownName =
    displayName.isNotEmpty
        ? displayName
        : email;
    final role =
    (user["role"] ?? "agent")
        .toString();
    return Card(
      margin:
      const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 6,
      ),
      elevation: 1,
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        // ------------------------------------------------------
        // AVATAR
        // ------------------------------------------------------
        leading: CircleAvatar(
          radius: 23,
          backgroundColor:
          const Color(0xff003366),
          child: Text(
            shownName.isNotEmpty
                ? shownName[0]
                .toUpperCase()
                : "?",
            style:
            const TextStyle(
              color: Colors.white,
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ),
        // ------------------------------------------------------
        // NAME + EMAIL
        // ------------------------------------------------------
        title: Text(
          shownName,
          style:
          const TextStyle(
            fontWeight:
            FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle:
        displayName.isNotEmpty
            ? Text(
          email,
        )
            : null,
        // ------------------------------------------------------
        // ACTIONS
        // ------------------------------------------------------
        trailing: Row(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            // --------------------------------------------------
            // ROLE
            // --------------------------------------------------
            DropdownButton<String>(
              value: _roles()
                  .any(
                    (item) =>
                item.value ==
                    role,
              )
                  ? role
                  : "agent",
              items: _roles(),
              onChanged:
                  (value) {
                if (value != null) {
                  _updateRole(
                    user["uid"],
                    value,
                  );
                }
              },
            ),
            const SizedBox(
              width: 8,
            ),
            // --------------------------------------------------
            // EDIT
            // --------------------------------------------------
            IconButton(
              tooltip:
              "Edit User",
              icon: const Icon(
                Icons.edit,
              ),
              onPressed: () {
                _showEditDialog(
                  user,
                );
              },
            ),
            // --------------------------------------------------
            // DELETE
            // --------------------------------------------------
            IconButton(
              tooltip:
              "Delete User",
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              onPressed: () {
                _confirmDelete(
                  user,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}