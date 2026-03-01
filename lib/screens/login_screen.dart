import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:heart_link_app/services/auth_service.dart';
import 'package:heart_link_app/screens/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // create auth service instance
  final AuthService _authService = AuthService();
  //form key for validation
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;

  // Input decoration
  InputDecoration _inputDeco(BuildContext context, {
    required String hint,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      //left icon
      prefixIcon: Icon(icon, color: colorScheme.primary),
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      // avoid overlap with system UI
      body: SafeArea(
        child: Stack(
          children: [
            // background circles
            Positioned(
              left: -120,
              top: -80,
              child: IgnorePointer( 
              child: Container(
                width: 520,
                height: 520,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primary.withOpacity(.15),
                      cs.primary.withOpacity(.06),
                    ],
                  ),
                ),
              ),
            ),
          ),

            // main page content
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // back button
                  IconButton.filledTonal(
                    onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterScreen(),
                                      ),
                                    );
                                  },
                    style: IconButton.styleFrom(
                      backgroundColor: cs.primary.withOpacity(.15),
                    ),
                    icon: Icon(Icons.arrow_back, color: cs.primary),
                  ),
                  const SizedBox(height: 16),

                  // title and logo area
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Heart Link',
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text('Stay in sync',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                      // love heart icon
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: cs.primary.withOpacity(.15),
                        child: Icon(Icons.favorite, color: cs.primary, size: 28),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // login card
                  Container(
                    decoration: BoxDecoration(
                      color: cs.background,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Login',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 18),

                        // login form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                decoration: _inputDeco(
                                  context,
                                  hint: 'Email',
                                  icon: Icons.mail_rounded,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                onChanged: (inputText) => _email = inputText.trim(),
                                validator: (inputText) => (inputText == null || inputText.isEmpty) ? 'Enter email' : null,
                              ),
                              const SizedBox(height: 14),

                              TextFormField(
                                decoration: _inputDeco(
                                  context,
                                  hint: 'Password',
                                  icon: Icons.lock_rounded,
                                ),
                                obscureText: true,
                                onChanged: (inputText) => _password = inputText,
                                validator: (inputText) => (inputText == null || inputText.isEmpty) ? 'Enter password' : null,
                              ),
                              const SizedBox(height: 20),

                              // Continue button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: FilledButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () async {
                                          if (!_formKey.currentState!.validate()) return;
                                          setState(() => _isLoading = true);
                                          try {
                                            final User? user =
                                                await _authService.signInWithEmail(
                                              _email,
                                              _password,
                                            );
                                            if (user == null) {
                                              throw Exception('Sign in failed');
                                            }
                                          } catch (e) {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(e.toString())),
                                            );
                                          } finally {
                                            if (mounted) {
                                              setState(() => _isLoading = false);
                                            }
                                          }
                                        },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: cs.primary,
                                    shape: const StadiumBorder(),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(strokeWidth: 2))
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Text('Continue',
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700)),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_right_alt_rounded),
                                          ],
                                        ),
                                ),
                              ),

                              // OR divider
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: cs.outline.withOpacity(.3),
                                      ),
                                    ),
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 12.0),
                                      child: Text('or'),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: cs.outline.withOpacity(.3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Google Sign-In button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                  try {
                                    User? user = await _authService.signInWithGoogle();
                                    if (user != null) {
                                      Navigator.pushReplacementNamed(context, '/home');
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                },
                                  style: OutlinedButton.styleFrom(
                                    shape: const StadiumBorder(),
                                  ),
                                  icon: const Icon(Icons.account_circle_rounded),
                                  label: const Text('Sign In with Google'),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Create New User button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterScreen(),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    shape: const StadiumBorder(),
                                    side: BorderSide(
                                      color: cs.outline.withOpacity(.4),
                                    ),
                                  ),
                                  child: const Text(
                                    'Create New User',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}