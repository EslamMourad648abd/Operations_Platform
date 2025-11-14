// main.dart
import 'package:bbc_api_tool/ui/super_admin_console.dart';
import 'package:bbc_api_tool/ui/home_dashboard.dart';
import 'package:bbc_api_tool/ui/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_functions/cloud_functions.dart'; // ✅ must be imported


Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase once
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );




  runApp(const ApiTesterApp());
}

class ApiTesterApp extends StatelessWidget {
  const ApiTesterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BBC API Tool',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,

      // ✅ Works with Flutter Web: handles deep links like /admin-console
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');
        debugPrint("🔍 Route detected: ${uri.path}");

        // Handle routes
        if (uri.path == '/admin-console') {
          return MaterialPageRoute(builder: (_) => const SuperAdminConsole());
        } else if (uri.path == '/home') {
          return MaterialPageRoute(builder: (_) => const HomeDashboard());
        } else {
          return MaterialPageRoute(builder: (_) => const LoginPage());
        }
      },

      // ✅ Keep auth state persistent (decides which screen to show on app start)
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // If user is logged in but URL is /admin-console, go there directly
          final currentUrl = Uri.base.path;
          debugPrint("🌐 Current URL: $currentUrl");

          if (snapshot.hasData) {
            if (currentUrl.contains('/admin-console')) {
              return const SuperAdminConsole();
            }
            return const HomeDashboard();
          }

          // Not logged in
          return const LoginPage();
        },
      ),
    );
  }
}

