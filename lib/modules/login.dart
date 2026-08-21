import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  static const routeName = '/login';

  const LoginPage({
    super.key,
  });

  @override
  State<LoginPage> createState() =>
      _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ============================================================
  // FORM
  // ============================================================

  final _formKey =
  GlobalKey<FormState>();

  final _emailCtrl =
  TextEditingController();

  final _passwordCtrl =
  TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  bool _obscure = true;
  bool _isSubmitting = false;

  // ============================================================
  // PASSWORD VISIBILITY
  // ============================================================

  void _togglePassword() {
    setState(() {
      _obscure = !_obscure;
    });
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  Future<void> _resetPassword() async {
    final email =
    _emailCtrl.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your email before resetting password.',
          ),
          backgroundColor:
          Colors.redAccent,
        ),
      );

      return;
    }

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset email sent successfully.',
          ),
          backgroundColor:
          Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.message ??
                'Error sending reset email.',
          ),
          backgroundColor:
          Colors.redAccent,
        ),
      );
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final email =
      _emailCtrl.text.trim();

      final password =
      _passwordCtrl.text.trim();

      // ========================================================
      // FIREBASE AUTHENTICATION
      // ========================================================

      final credential =
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ========================================================
      // FORCE TOKEN REFRESH
      // ========================================================
      //
      // This ensures the latest custom claims / role are loaded.
      //

      await credential.user!
          .getIdToken(true);

      // ========================================================
      // LOAD USER ROLE
      // ========================================================

      await AuthService.loadUserRole();

      // ========================================================
      // DEBUG FIREBASE CLAIMS
      // ========================================================

      final token =
      await credential.user!
          .getIdTokenResult(true);

      debugPrint(
        '========== FIREBASE CLAIMS ==========',
      );

      debugPrint(
        token.claims.toString(),
      );

      debugPrint(
        'Role from AuthService: '
            '${AuthService.role}',
      );

      debugPrint(
        '=====================================',
      );

      // ========================================================
      // NAVIGATION
      // ========================================================
      //
      // IMPORTANT:
      //
      // We now use GoRouter.
      //
      // This changes the browser URL to:
      //
      // /home
      //
      // instead of pushing a Flutter-only route.
      //
      // The AppRouter redirect will also protect the route.
      //

      if (mounted) {
        context.go('/home');
      }
    } on FirebaseAuthException catch (e) {
      String message =
          e.message ?? 'Login failed.';

      // --------------------------------------------------------
      // FIREBASE ERROR MESSAGES
      // --------------------------------------------------------

      if (e.code == 'user-not-found') {
        message =
        'No user found for this email.';
      }

      if (e.code == 'wrong-password') {
        message =
        'Incorrect password.';
      }

      if (e.code == 'invalid-credential') {
        message =
        'Invalid email or password.';
      }

      if (e.code == 'invalid-email') {
        message =
        'Please enter a valid email address.';
      }

      if (e.code == 'user-disabled') {
        message =
        'This account has been disabled.';
      }

      if (e.code == 'access-denied') {
        message =
            e.message ??
                'Access denied.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
          Colors.redAccent,
        ),
      );
    } catch (e) {
      // ========================================================
      // UNEXPECTED ERROR
      // ========================================================

      debugPrint(
        'Login error: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Login failed: $e',
          ),
          backgroundColor:
          Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    const gradientStart =
    Color(0xFF001C38);

    const gradientEnd =
    Color(0xFF80CFFF);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration:
        const BoxDecoration(
          gradient: LinearGradient(
            begin:
            Alignment.topCenter,
            end:
            Alignment.bottomCenter,
            colors: [
              gradientStart,
              gradientEnd,
            ],
          ),
        ),

        child: Center(
          child: ConstrainedBox(
            constraints:
            const BoxConstraints(
              maxWidth: 520,
              minWidth: 320,
            ),

            child: Card(
              elevation: 20,

              child: Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 36,
                ),

                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,

                  children: [

                    // ==================================================
                    // LOGO + TITLE
                    // ==================================================

                    Column(
                      children: [

                        Image.asset(
                          'assets/logo.png',
                          height: 150,
                          fit: BoxFit.contain,
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        const Text(
                          'Sign in to BBC Operations Platform',

                          textAlign:
                          TextAlign.center,

                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                            FontWeight.bold,
                            color:
                            Color(0xFF1F5B8A),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    // ==================================================
                    // FORM
                    // ==================================================

                    Form(
                      key: _formKey,

                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.stretch,

                        children: [

                          // ==========================================
                          // EMAIL
                          // ==========================================

                          const Text(
                            'Email',

                            style: TextStyle(
                              fontSize: 13,
                              color:
                              Color(0xFF6B7B8B),
                            ),
                          ),

                          const SizedBox(
                            height: 6,
                          ),

                          TextFormField(
                            controller:
                            _emailCtrl,

                            keyboardType:
                            TextInputType
                                .emailAddress,

                            textInputAction:
                            TextInputAction
                                .next,

                            decoration:
                            InputDecoration(
                              filled: true,

                              fillColor:
                              const Color(
                                0xFFEEF6FB,
                              ),

                              contentPadding:
                              const EdgeInsets
                                  .symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),

                              border:
                              OutlineInputBorder(
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  6,
                                ),

                                borderSide:
                                BorderSide.none,
                              ),
                            ),

                            validator: (value) {
                              if (value ==
                                  null ||
                                  value
                                      .trim()
                                      .isEmpty) {
                                return 'Email is required';
                              }

                              if (!RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              ).hasMatch(
                                value.trim(),
                              )) {
                                return 'Enter a valid email';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          // ==========================================
                          // PASSWORD
                          // ==========================================

                          const Text(
                            'Password',

                            style: TextStyle(
                              fontSize: 13,
                              color:
                              Color(0xFF6B7B8B),
                            ),
                          ),

                          const SizedBox(
                            height: 6,
                          ),

                          Stack(
                            alignment:
                            Alignment.centerRight,

                            children: [

                              TextFormField(
                                controller:
                                _passwordCtrl,

                                obscureText:
                                _obscure,

                                textInputAction:
                                TextInputAction
                                    .done,

                                onFieldSubmitted:
                                    (_) {
                                  if (!_isSubmitting) {
                                    _submit();
                                  }
                                },

                                decoration:
                                InputDecoration(
                                  filled: true,

                                  fillColor:
                                  const Color(
                                    0xFFEEF6FB,
                                  ),

                                  contentPadding:
                                  const EdgeInsets
                                      .symmetric(
                                    vertical: 12,
                                    horizontal: 12,
                                  ),

                                  border:
                                  OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                      6,
                                    ),

                                    borderSide:
                                    BorderSide.none,
                                  ),
                                ),

                                validator: (value) {
                                  if (value ==
                                      null ||
                                      value
                                          .isEmpty) {
                                    return 'Password is required';
                                  }

                                  return null;
                                },
                              ),

                              IconButton(
                                tooltip: _obscure
                                    ? 'Show password'
                                    : 'Hide password',

                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility
                                      : Icons
                                      .visibility_off,

                                  color:
                                  const Color(
                                    0xFF2B6F90,
                                  ),
                                ),

                                onPressed:
                                _togglePassword,
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          // ==========================================
                          // LOGIN BUTTON
                          // ==========================================

                          ElevatedButton(
                            onPressed:
                            _isSubmitting
                                ? null
                                : _submit,

                            style:
                            ElevatedButton
                                .styleFrom(
                              backgroundColor:
                              const Color(
                                0xFF80CFFF,
                              ),

                              disabledBackgroundColor:
                              const Color(
                                0xFF80CFFF,
                              ).withOpacity(
                                0.55,
                              ),

                              padding:
                              const EdgeInsets
                                  .symmetric(
                                vertical: 14,
                              ),

                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  8,
                                ),
                              ),

                              elevation: 6,
                            ),

                            child:
                            _isSubmitting
                                ? const SizedBox(
                              height: 18,
                              width: 18,

                              child:
                              CircularProgressIndicator(
                                strokeWidth:
                                2,

                                color:
                                Colors.white,
                              ),
                            )
                                : const Text(
                              'Login',

                              style:
                              TextStyle(
                                fontSize:
                                16,

                                fontWeight:
                                FontWeight
                                    .w600,
                              ),
                            ),
                          ),

                          // ==========================================
                          // FORGOT PASSWORD
                          // ==========================================

                          TextButton(
                            onPressed:
                            _isSubmitting
                                ? null
                                : _resetPassword,

                            child:
                            const Text(
                              'Forgot Password?',

                              style:
                              TextStyle(
                                color:
                                Color(
                                  0xFF1F5B8A,
                                ),

                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}