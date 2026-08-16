// main.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'platform/dashboard.dart';
import 'modules/login.dart';
import 'admin/super_admin_console.dart';


// ============================================================
// MAIN
// ============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ==========================================================
  // INITIALIZE FIREBASE ONCE
  // ==========================================================

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ApiTesterApp());
}


// ============================================================
// APP
// ============================================================

class ApiTesterApp extends StatelessWidget {
  const ApiTesterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BBC Operations Platform',

      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      debugShowCheckedModeBanner: false,

      // ========================================================
      // GLOBAL APP WATERMARK
      // ========================================================
      //
      // This wraps every screen in the application.
      //
      // Because the watermark is placed here, you do NOT need
      // to add it individually to every page.
      //
      // ========================================================

      builder: (context, child) {
        return Stack(
          children: [
            // --------------------------------------------------
            // CURRENT SCREEN
            // --------------------------------------------------

            child ?? const SizedBox.shrink(),

            // --------------------------------------------------
            // GLOBAL WATERMARK
            // --------------------------------------------------

            const Positioned(
              right: 18,
              bottom: 10,
              child: AppWatermark(),
            ),
          ],
        );
      },

      // ========================================================
      // ROUTING
      // ========================================================

      onGenerateRoute: (settings) {
        final uri = Uri.parse(
          settings.name ?? '/',
        );

        debugPrint(
          "🔍 Route detected: ${uri.path}",
        );

        // ------------------------------------------------------
        // ADMIN CONSOLE
        // ------------------------------------------------------

        if (uri.path == '/admin-console') {
          return MaterialPageRoute(
            builder: (_) =>
            const PlatformAdminConsole(),
          );
        }

        // ------------------------------------------------------
        // HOME
        // ------------------------------------------------------

        else if (uri.path == '/home') {
          return MaterialPageRoute(
            builder: (_) =>
            const PlatformDashboard(),
          );
        }

        // ------------------------------------------------------
        // DEFAULT
        // ------------------------------------------------------

        else {
          return MaterialPageRoute(
            builder: (_) =>
            const LoginPage(),
          );
        }
      },

      // ========================================================
      // AUTH STATE
      // ========================================================

      home: StreamBuilder<User?>(
        stream:
        FirebaseAuth.instance.authStateChanges(),

        builder: (
            context,
            snapshot,
            ) {
          // ----------------------------------------------------
          // AUTH LOADING
          // ----------------------------------------------------

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child:
                CircularProgressIndicator(),
              ),
            );
          }

          // ----------------------------------------------------
          // CURRENT URL
          // ----------------------------------------------------

          final currentUrl =
              Uri.base.path;

          debugPrint(
            "🌐 Current URL: $currentUrl",
          );

          // ----------------------------------------------------
          // USER LOGGED IN
          // ----------------------------------------------------

          if (snapshot.hasData) {
            return FutureBuilder(
              future:
              AuthService.loadUserRole(),

              builder: (
                  context,
                  roleSnapshot,
                  ) {
                // ------------------------------------------------
                // ROLE LOADING
                // ------------------------------------------------

                if (roleSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child:
                      CircularProgressIndicator(),
                    ),
                  );
                }

                // ------------------------------------------------
                // ADMIN CONSOLE URL
                // ------------------------------------------------

                if (currentUrl.contains(
                  '/admin-console',
                )) {
                  // ----------------------------------------------
                  // SUPER ADMIN
                  // ----------------------------------------------

                  if (AuthService.isSuperAdmin) {
                    return const PlatformAdminConsole();
                  }

                  // ----------------------------------------------
                  // NON ADMIN
                  // ----------------------------------------------

                  return const PlatformDashboard();
                }

                // ------------------------------------------------
                // NORMAL LOGGED-IN USER
                // ------------------------------------------------

                return const PlatformDashboard();
              },
            );
          }

          // ----------------------------------------------------
          // NOT LOGGED IN
          // ----------------------------------------------------

          return const LoginPage();
        },
      ),
    );
  }
}


// ============================================================
// GLOBAL APP WATERMARK
// ============================================================

class AppWatermark extends StatelessWidget {
  const AppWatermark({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.82),
            borderRadius:
            BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.withOpacity(0.18),
            ),
          ),
          child: const Text(
            'Powered by Eng. Eslam Mourad',
            style: TextStyle(
              fontSize: 20
              ,
              fontWeight: FontWeight.bold,
              color: Color(0xff6B7280),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}