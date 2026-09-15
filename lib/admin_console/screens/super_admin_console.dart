import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';

import '../../services/theme_service.dart';
import '../../router/app_router.dart';

import 'training_management_screen.dart';
import 'user_management_screen.dart';
import 'training_analytics_screen.dart';
import 'meta_whatsapp_business_screen.dart';

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

    if (path ==
        AppRouter.adminTrainingManagement) {
      return 1;
    }

    if (path ==
        AppRouter.adminAnalytics) {
      return 2;
    }

    if (path ==
        AppRouter.adminMetaWhatsApp) {
      return 3;
    }

    // ----------------------------------------------------------
    // DEFAULT
    //
    // /admin-console
    // /admin-console/users
    //
    // Both belong to Users.
    // ----------------------------------------------------------

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

      case 3:
        context.go(
          AppRouter.adminMetaWhatsApp,
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
    // TRAINING ANALYTICS
    // ----------------------------------------------------------

    if (path ==
        AppRouter.adminAnalytics) {
      return const TrainingAnalyticsScreen();
    }

    if (path ==
        AppRouter.adminMetaWhatsApp) {
      return MetaWhatsAppBusinessScreen(
        functions: _functions!,
      );
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
    final theme = Theme.of(context);

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

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 800;

      if (isMobile) {
        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            title: const Text('Admin Console', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            centerTitle: true,
            actions: [
              ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeService.themeNotifier,
                builder: (context, mode, _) {
                  final isDarkNow = mode == ThemeMode.dark;
                  return IconButton(
                    onPressed: ThemeService.toggleTheme,
                    icon: Icon(isDarkNow ? Icons.light_mode : Icons.dark_mode),
                  );
                },
              ),
            ],
            shape: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          body: _buildCurrentPage(context),
          bottomNavigationBar: NavigationBar(
            backgroundColor: theme.colorScheme.surface,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => _navigateToSection(context, index),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.people_outlined), selectedIcon: Icon(Icons.people), label: 'Users'),
              NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Training'),
              NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'Analytics'),
              NavigationDestination(icon: Icon(Icons.business_outlined), selectedIcon: Icon(Icons.business), label: 'Meta'),
            ],
          ),
        );
      }

      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: theme.colorScheme.surface,
              indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              unselectedIconTheme: IconThemeData(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              selectedIconTheme: IconThemeData(color: theme.colorScheme.primary),
              unselectedLabelTextStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 11),
              selectedLabelTextStyle: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
              selectedIndex: selectedIndex,
              labelType: NavigationRailLabelType.all,
              leading: Column(
                children: [
                  const SizedBox(height: 16),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: ThemeService.themeNotifier,
                    builder: (context, mode, _) {
                      final isDarkNow = mode == ThemeMode.dark;
                      return IconButton(
                        onPressed: ThemeService.toggleTheme,
                        icon: Icon(
                          isDarkNow ? Icons.light_mode : Icons.dark_mode,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        tooltip: isDarkNow ? 'Light Mode' : 'Dark Mode',
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
              onDestinationSelected: (index) {
                _navigateToSection(context, index);
              },
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.people_outlined), selectedIcon: Icon(Icons.people), label: Text('Users')),
                NavigationRailDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: Text('Training')),
                NavigationRailDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: Text('Analytics')),
                NavigationRailDestination(icon: Icon(Icons.business_outlined), selectedIcon: Icon(Icons.business), label: Text('Meta')),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _buildCurrentPage(context)),
          ],
        ),
      );
    });
  }
}
