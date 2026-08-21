import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../router/app_router.dart';

import 'training_management.dart';
import 'user_management.dart';
import 'training_analytics_screen.dart';

class PlatformAdminConsole extends StatefulWidget {
  const PlatformAdminConsole({
    super.key,
  });

  @override
  State<PlatformAdminConsole> createState() =>
      _PlatformAdminConsoleState();
}

class _PlatformAdminConsoleState
    extends State<PlatformAdminConsole> {
  FirebaseFunctions? _functions;

  bool loading = true;

  String? error;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  @override
  void initState() {
    super.initState();

    _initializeFunctions();
  }

  Future<void> _initializeFunctions() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      await FirebaseAuth.instance
          .authStateChanges()
          .first;

      _functions =
          FirebaseFunctions.instanceFor(
            region: 'us-central1',
          );

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  // ============================================================
  // CURRENT ADMIN SECTION
  // ============================================================

  int _getSelectedIndex(
      BuildContext context,
      ) {
    final path =
        GoRouterState.of(context).uri.path;

    if (path == AppRouter.adminTrainingManagement) {
      return 1;
    }

    if (path == AppRouter.adminAnalytics) {
      return 2;
    }

    // Default:
    //
    // /admin-console
    // /admin-console/users
    //
    // Both represent Users.
    return 0;
  }

  // ============================================================
  // ADMIN NAVIGATION
  // ============================================================

  void _navigateToSection(
      BuildContext context,
      int index,
      ) {
    switch (index) {
      case 0:
        context.go(
          AppRouter.adminUsers,
        );
        break;

      case 1:
        context.go(
          AppRouter.adminTrainingManagement,
        );
        break;

      case 2:
        context.go(
          AppRouter.adminAnalytics,
        );
        break;
    }
  }

  // ============================================================
  // CURRENT PAGE
  // ============================================================

  Widget _buildCurrentPage(
      BuildContext context,
      ) {
    if (_functions == null) {
      return const SizedBox.shrink();
    }

    final path =
        GoRouterState.of(context).uri.path;

    // ----------------------------------------------------------
    // USERS
    // ----------------------------------------------------------

    if (path == AppRouter.adminUsers ||
        path == AppRouter.adminConsole) {
      return UserManagement(
        functions: _functions!,
      );
    }

    // ----------------------------------------------------------
    // TRAINING MANAGEMENT
    // ----------------------------------------------------------

    if (path ==
        AppRouter.adminTrainingManagement) {
      return TrainingManagement(
        functions: _functions!,
      );
    }

    // ----------------------------------------------------------
    // ANALYTICS
    // ----------------------------------------------------------

    if (path ==
        AppRouter.adminAnalytics) {
      return const TrainingAnalyticsScreen();
    }

    // ----------------------------------------------------------
    // FALLBACK
    // ----------------------------------------------------------

    return UserManagement(
      functions: _functions!,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    // ==========================================================
    // LOADING
    // ==========================================================

    if (loading) {
      return const Scaffold(
        body: Center(
          child:
          CircularProgressIndicator(),
        ),
      );
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    if (error != null) {
      return Scaffold(
        body: Center(
          child: Text(
            error!,
            style:
            const TextStyle(
              color: Colors.red,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    // ==========================================================
    // CURRENT SECTION
    // ==========================================================

    final selectedIndex =
    _getSelectedIndex(context);

    // ==========================================================
    // ADMIN CONSOLE
    // ==========================================================

    return Scaffold(
      backgroundColor:
      const Color(0xffF5F2F7),

      body: Row(
        children: [
          // ====================================================
          // NAVIGATION RAIL
          // ====================================================

          NavigationRail(
            selectedIndex:
            selectedIndex,

            labelType:
            NavigationRailLabelType.all,

            onDestinationSelected:
                (index) {
              _navigateToSection(
                context,
                index,
              );
            },

            destinations: const [
              // =================================================
              // USERS
              // =================================================

              NavigationRailDestination(
                icon: Icon(
                  Icons.people,
                ),

                selectedIcon: Icon(
                  Icons.people,
                ),

                label: Text(
                  'Users',
                ),
              ),

              // =================================================
              // TRAINING
              // =================================================

              NavigationRailDestination(
                icon: Icon(
                  Icons.school,
                ),

                selectedIcon: Icon(
                  Icons.school,
                ),

                label: Text(
                  'Training',
                ),
              ),

              // =================================================
              // ANALYTICS
              // =================================================

              NavigationRailDestination(
                icon: Icon(
                  Icons.analytics,
                ),

                selectedIcon: Icon(
                  Icons.analytics,
                ),

                label: Text(
                  'Analytics',
                ),
              ),
            ],
          ),

          // ====================================================
          // DIVIDER
          // ====================================================

          const VerticalDivider(
            width: 1,
          ),

          // ====================================================
          // CONTENT
          // ====================================================

          Expanded(
            child:
            _buildCurrentPage(
              context,
            ),
          ),
        ],
      ),
    );
  }
}