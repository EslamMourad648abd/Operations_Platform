import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // FIREBASE
  // ============================================================

  await Firebase.initializeApp(
    options:
    DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ApiTesterApp(),
  );
}

class ApiTesterApp extends StatelessWidget {
  const ApiTesterApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BBC Operations Platform',

      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      // ========================================================
      // ROUTER
      // ========================================================

      routerConfig:
      AppRouter.router,

      // ========================================================
      // GLOBAL APP WATERMARK
      // ========================================================

      builder: (
          context,
          child,
          ) {
        return Stack(
          children: [
            child ??
                const SizedBox.shrink(),

            const Positioned(
              right: 18,
              bottom: 10,
              child: AppWatermark(),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// GLOBAL APP WATERMARK
// ============================================================

class AppWatermark
    extends StatelessWidget {
  const AppWatermark({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.45,
        child: Container(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration:
          BoxDecoration(
            color:
            Colors.white.withOpacity(
              0.82,
            ),
            borderRadius:
            BorderRadius.circular(8),
            border:
            Border.all(
              color:
              Colors.grey.withOpacity(
                0.18,
              ),
            ),
          ),
          child: const Text(
            'Powered by Eng. Eslam Mourad',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
              FontWeight.bold,
              color:
              Color(0xff6B7280),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}