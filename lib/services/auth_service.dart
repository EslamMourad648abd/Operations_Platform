import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';


class AuthService {

  static String role = "agent";

  static Future<void> loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      role = "agent";
      return;
    }

    final token = await user.getIdTokenResult(true);

    debugPrint("Token claims: ${token.claims}");

    role = token.claims?['role'] ?? "agent";

    debugPrint("Loaded role: $role");
  }



  static bool get isSuperAdmin =>
      role == "superadmin";


  static bool get isAgent =>
      role == "agent";


  static bool get isTrainee =>
      role == "trainee";

}