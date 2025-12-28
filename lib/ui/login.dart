import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  static const routeName = '/login';
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _isSubmitting = false;


  void _togglePassword() => setState(() => _obscure = !_obscure);

  // ✅ HIGHLIGHTED FUNCTION: Reset password
  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email before resetting password.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Password reset email sent successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Error sending reset email.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final email = _emailCtrl.text.trim();

      // ✅ Step 1: Restrict login to allowed emails only
      // if (!allowedEmails.map((e) => e.toLowerCase()).contains(email.toLowerCase())) {
      //   throw FirebaseAuthException(
      //     code: 'access-denied',
      //     message: 'This account is not authorized to use the tool.',
      //   );
      // }

      // ✅ Step 2: Authenticate with Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passwordCtrl.text.trim(),
      );

      // ✅ Step 3: Navigate to dashboard
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on FirebaseAuthException catch (e) {
      String message = e.message ?? 'Login failed';
      if (e.code == 'user-not-found') message = 'No user found for this email.';
      if (e.code == 'wrong-password') message = 'Incorrect password.';
      if (e.code == 'access-denied') message = e.message!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gradientStart = Color(0xFF001C38);
    const gradientEnd = Color(0xFF80CFFF);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientStart, gradientEnd],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, minWidth: 320),
            child: Card(
              elevation: 20,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // logo + heading
                    Column(
                      children: [
                        Image.asset('lib/assets/logo.png', height: 150, fit: BoxFit.contain),
                        const SizedBox(height: 5),
                        const Text(
                          'Sign in to BBC API Tool',
                          style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold, color: Color(0xFF1F5B8A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Email',
                              style: TextStyle(fontSize: 13, color: Color(0xFF6B7B8B))),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFEEF6FB),
                              contentPadding:
                              const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide.none),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Email is required';
                              if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
                                  .hasMatch(v)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          const Text('Password',
                              style: TextStyle(fontSize: 13, color: Color(0xFF6B7B8B))),
                          const SizedBox(height: 6),
                          Stack(
                            alignment: Alignment.centerRight,
                            children: [
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: _obscure,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFEEF6FB),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (v) =>
                                (v == null || v.isEmpty) ? 'Password is required' : null,
                              ),
                              IconButton(
                                tooltip: _obscure ? 'Show password' : 'Hide password',
                                icon: Icon(
                                  _obscure ? Icons.visibility : Icons.visibility_off,
                                  color: const Color(0xFF2B6F90),
                                ),
                                onPressed: _togglePassword,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF80CFFF),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              elevation: 6,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.0, color: Colors.white))
                                : const Text(
                              'Login',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                          // ✅ Forgot Password Button
                          TextButton(
                            onPressed: _resetPassword,
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: Color(0xFF1F5B8A),
                                fontWeight: FontWeight.w600,
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
