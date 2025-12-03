import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:heart_link_app/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:heart_link_app/screens/login_screen.dart';
import 'package:heart_link_app/screens/heartratedial/hr.state.dart';
import 'package:heart_link_app/shell/app_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _email = '';
  String _password = '';
  String _displayName = '';
  String _ageForMaxHr = '';
  String _weight = '';
  String? _gender;
  bool _isLoading = false;

  InputDecoration _inputDeco(
    BuildContext context, {
    required String hint,
    required IconData icon,
  }) {
    final ColorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: ColorScheme.primary),
      filled: true,
      fillColor: ColorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(
          color: ColorScheme.outline.withOpacity(.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(
          color: ColorScheme.primary,
          width: 1.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // background circles
            Positioned(
              right: -150,
              top: -100,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      cs.primary.withOpacity(.15),
                      cs.primary.withOpacity(.05),
                    ],
                  ),
                ),
              ),
            ),

            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // back button
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: cs.primary.withOpacity(.15),
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, color: cs.primary),
                  ),
                  const SizedBox(height: 16),

                  // title
                  Text(
                    'Heart Link',
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Stay in sync',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 28),

                  // registration form card
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New User',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 18),

                          // user name input
                          TextFormField(
                            decoration: _inputDeco(
                              context,
                              hint: 'User Name',
                              icon: Icons.person,
                            ),
                            onChanged: (InputText) => _displayName = InputText.trim(),
                            validator: (InputText) => InputText == null || InputText.isEmpty ? 'Enter name' : null,),
                          const SizedBox(height: 14),

                          // email input
                          TextFormField(
                            decoration: _inputDeco(
                              context,
                              hint: 'Email',
                              icon: Icons.mail_outline,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (InputText) => _email = InputText.trim(),
                            validator: (InputText) => InputText == null || InputText.isEmpty ? 'Enter email' : null,),
                          const SizedBox(height: 14),

                          // text form
                          TextFormField(
                            decoration: _inputDeco(
                              context,
                              hint: 'Password',
                              icon: Icons.lock_outline,
                            ),
                            obscureText: true,
                            onChanged: (InputText) => _password = InputText,
                            validator: (InputText) => InputText == null || InputText.length < 6 ? 'Min 6 chars' : null,),
                          const SizedBox(height: 14),

                          // age input
                          TextFormField(
                            decoration: _inputDeco(
                              context,
                              hint: 'Age',
                              icon: Icons.cake,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (InputText) => _ageForMaxHr = InputText,
                            validator: (InputText) {
                              final age = int.tryParse(InputText ?? '');
                              if (age == null || age <= 0 || age >= 200) {
                                return 'Enter valid age';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // weight input
                          TextFormField(
                            decoration: _inputDeco(
                              context,
                              hint: 'Weight',
                              icon: Icons.monitor_weight,
                            ).copyWith(
                              suffixText: 'lb',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (InputText) => _weight = InputText,
                            validator: (InputText) {
                              final weight = int.tryParse(InputText ?? '');
                              if (weight == null || weight <= 0 || weight >= 500) {
                                return 'Enter valid weight';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // gender
                          DropdownButtonFormField<String>(
                            value: _gender,
                            decoration: _inputDeco(
                              context,
                              hint: 'Gender',
                              icon: Icons.person_outline,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'male',
                                child: Text('Male'),
                              ),
                              DropdownMenuItem(
                                value: 'female',
                                child: Text('Female'),
                              ),
                            ],
                            onChanged: (value) => setState(() => _gender = value),
                            validator: (value) => value == null ? 'Select gender' : null,),
                          const SizedBox(height: 20),

                          // register button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      if (!_formKey.currentState!.validate()) {
                                        return;
                                      }
                                      setState(() => _isLoading = true);
                                      try {
                                        final user =
                                            await _authService
                                                .signUpWithEmail(
                                          _email,
                                          _password,
                                        );

                                        if (user != null) {
                                          if (_displayName.isNotEmpty) {
                                            await user.updateDisplayName(
                                                _displayName);
                                            await user.reload();
                                          }

                                          final age = int.parse(
                                              _ageForMaxHr.trim());
                                          final weight =
                                              int.parse(_weight.trim());

                                          await hrState.updateAge(age);
                                          await hrState.setCustomMaxHr(null);

                                          await _db
                                              .collection('users')
                                              .doc(user.uid)
                                              .set({
                                            'displayName': _displayName,
                                            'email': _email,
                                            'age': age,
                                            'weight': weight,
                                            'gender': _gender,
                                            'createdAt':
                                                FieldValue.serverTimestamp(),
                                          }, SetOptions(merge: true));

                                          if (!mounted) return;
                                          Navigator.of(context)
                                              .pushAndRemoveUntil(
                                            MaterialPageRoute(
                                              builder: (_) => const AppShell(),),
                                              (route) => false,
                                          );
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(e.toString()),
                                          ),
                                        );
                                      } finally {
                                        if (mounted) {
                                          setState(
                                            () => _isLoading = false,
                                          );
                                        }
                                      }
                                    },
                              style: FilledButton.styleFrom(
                                backgroundColor: cs.primary,
                                shape: const StadiumBorder(),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // already have account then back to login screen
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Already have an account? Sign In',
                                style: TextStyle(color: cs.primary),
                              ),
                            ),
                          ),
                        ],
                      ),
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