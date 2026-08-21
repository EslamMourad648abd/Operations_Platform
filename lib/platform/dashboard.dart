import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html;
import '../widgets/platform_card.dart';
import '../services/auth_service.dart';

class PlatformDashboard extends StatelessWidget {
  const PlatformDashboard({
    super.key,
  });

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout(
      BuildContext context,
      ) async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) {
        return;
      }

      // GoRouter owns the URL.
      //
      // Do NOT use Navigator here.
      context.go('/login');
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
          Text('Failed to logout: $e'),
          backgroundColor:
          Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final user =
        FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor:
      const Color(0xffF5F8FC),

      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal:
            MediaQuery.of(context)
                .size
                .width >
                1200
                ? 40
                : 20,
            vertical: 30,
          ),

          child: Center(
            child: ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxWidth: 1600,
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  // ==================================================
                  // HEADER
                  // ==================================================

                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [

                            Text(
                              'BEVATEL',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight:
                                FontWeight.bold,
                                color:
                                Color(0xff003366),
                              ),
                            ),

                            SizedBox(
                              height: 10,
                            ),

                            Text(
                              'Operations Platform',
                              style: TextStyle(
                                fontSize: 18,
                                color:
                                Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      PopupMenuButton<String>(
                        tooltip: 'Account',

                        icon:
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor:
                          Color(0xff003366),

                          child: Icon(
                            Icons.person,
                            color:
                            Colors.white,
                          ),
                        ),

                        onSelected: (
                            value,
                            ) {
                          switch (value) {

                            case 'admin':
                              html.window.open(
                                '#/admin-console',
                                '_blank',
                              );
                              break;

                            case 'logout':
                              _logout(context);
                              break;
                          }
                        },

                        itemBuilder:
                            (context) => [

                          PopupMenuItem(
                            enabled: false,

                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                              children: [

                                Text(
                                  user
                                      ?.displayName
                                      ?.isNotEmpty ==
                                      true
                                      ? user!
                                      .displayName!
                                      : (user?.email ??
                                      'Unknown User'),

                                  style:
                                  const TextStyle(
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  AuthService
                                      .role
                                      .toUpperCase(),

                                  style:
                                  const TextStyle(
                                    color:
                                    Colors.grey,
                                    fontSize:
                                    12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const PopupMenuDivider(),

                          if (AuthService
                              .isSuperAdmin)
                            const PopupMenuItem(
                              value: 'admin',

                              child: ListTile(
                                leading: Icon(
                                  Icons
                                      .admin_panel_settings,
                                ),

                                title: Text(
                                  'Admin Console',
                                ),

                                contentPadding:
                                EdgeInsets.zero,
                              ),
                            ),

                          const PopupMenuItem(
                            value: 'logout',

                            child: ListTile(
                              leading: Icon(
                                Icons.logout,
                              ),

                              title: Text(
                                'Logout',
                              ),

                              contentPadding:
                              EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 40,
                  ),

                  const Text(
                    'Choose a Platform',

                    style: TextStyle(
                      fontSize: 26,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  // ==================================================
                  // PLATFORM GRID
                  // ==================================================

                  Expanded(
                    child: LayoutBuilder(
                      builder: (
                          context,
                          constraints,
                          ) {
                        int columns;

                        if (constraints
                            .maxWidth >=
                            1400) {
                          columns = 3;
                        } else if (constraints
                            .maxWidth >=
                            900) {
                          columns = 2;
                        } else {
                          columns = 1;
                        }

                        return GridView.count(
                          physics:
                          const BouncingScrollPhysics(),

                          crossAxisCount:
                          columns,

                          crossAxisSpacing: 25,
                          mainAxisSpacing: 25,

                          childAspectRatio:
                          columns == 1
                              ? 2.3
                              : columns == 2
                              ? 1.45
                              : 1.25,

                          children: [

                            // ==================================================
                            // BBC API
                            // ==================================================

                            if (AuthService
                                .isSuperAdmin ||
                                AuthService
                                    .isAgent ||
                                AuthService
                                    .isTrainee)
                              PlatformCard(
                                title:
                                'BBC API Tool',

                                subtitle:
                                'API Testing & Operations',

                                icon:
                                Icons.api,

                                onPressed: () {
                                  context.go(
                                    '/bbc-api',
                                  );
                                },
                              ),

                            // ==================================================
                            // TRAINING
                            // ==================================================

                            if (AuthService
                                .isSuperAdmin ||
                                AuthService
                                    .isTrainee)
                              PlatformCard(
                                title:
                                'Training Portal',

                                subtitle:
                                'Videos, Quizzes and Progress Tracking',

                                icon:
                                Icons.school,

                                enabled: true,

                                onPressed: () {
                                  context.go(
                                    '/training',
                                  );
                                },
                              ),

                            // ==================================================
                            // PRODUCT AWARENESS
                            // ==================================================

                            if (AuthService
                                .isSuperAdmin ||
                                AuthService
                                    .isAgent)
                              PlatformCard(
                                title:
                                'Product Awareness',

                                subtitle:
                                'Products, SOPs & Documentation',

                                icon:
                                Icons.menu_book,

                                enabled: false,

                                onPressed: () {},
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}