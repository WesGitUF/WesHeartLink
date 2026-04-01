import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:heart_link_app/app/theme/app_theme.dart';
import 'package:heart_link_app/services/auth_service.dart';
import 'package:heart_link_app/screens/login_screen.dart';
import 'package:heart_link_app/screens/heartratedial/hr.state.dart';
import 'package:heart_link_app/shell/app_shell.dart';
import 'package:heart_link_app/screens/complete_profile_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();

  String _email = '';
  String _password = '';
  String _displayName = '';
  String _ageForMaxHr = '';
  String _weight = '';
  String? _gender;

  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Page background gradient
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppGradients.pageBackground,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),
                    _Header(),
                    const SizedBox(height: 30),
                    _buildFormFields(),
                    const SizedBox(height: 18),
                    _buildSignUpButton(),
                    const SizedBox(height: 18),
                    _buildDivider(),
                    const SizedBox(height: 16),
                    _buildSocialButtons(),
                    const SizedBox(height: 18),
                    _buildLoginRow(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form fields ──────────────────────────────────────────────────────────

  Widget _buildFormFields() {
    return Column(
      children: [
        _inputField(
          hint: 'Username',
          icon: Icons.person_outline,
          onChanged: (v) => _displayName = v.trim(),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Enter username' : null,
        ),
        const SizedBox(height: 18),
        _inputField(
          hint: 'Email',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          onChanged: (v) => _email = v.trim(),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Enter email' : null,
        ),
        const SizedBox(height: 18),
        _inputField(
          hint: 'Password',
          icon: Icons.lock_outline,
          obscureText: true,
          onChanged: (v) => _password = v,
          validator: (v) =>
              (v == null || v.length < 6) ? 'Min 6 chars' : null,
        ),
        const SizedBox(height: 18),
        _inputField(
          hint: 'Age',
          icon: Icons.calendar_today_outlined,
          keyboardType: TextInputType.number,
          onChanged: (v) => _ageForMaxHr = v,
          validator: (v) {
            final age = int.tryParse(v ?? '');
            if (age == null || age <= 0 || age >= 200) {
              return 'Enter valid age';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        _inputField(
          hint: 'Weight',
          icon: Icons.monitor_weight_outlined,
          keyboardType: TextInputType.number,
          onChanged: (v) => _weight = v,
          validator: (v) {
            final weight = int.tryParse(v ?? '');
            if (weight == null || weight <= 0 || weight >= 500) {
              return 'Enter valid weight';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        _genderDropdown(),
      ],
    );
  }

  Widget _inputField({
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    required void Function(String) onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        letterSpacing: -0.31,
      ),
      decoration: _inputDecoration(hint: hint, icon: icon),
    );
  }

  Widget _genderDropdown() {
    return DropdownButtonFormField<String>(
      value: _gender,
      dropdownColor: AppColors.surfacePrimary,
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: AppColors.iconDefault,
      ),
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        letterSpacing: -0.31,
      ),
      decoration: _inputDecoration(hint: 'Gender', icon: Icons.person_outline),
      items: const [
        DropdownMenuItem(value: 'male', child: Text('Male')),
        DropdownMenuItem(value: 'female', child: Text('Female')),
      ],
      onChanged: (v) => setState(() => _gender = v),
      validator: (v) => v == null ? 'Select gender' : null,
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppColors.textTertiary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.31,
      ),
      prefixIcon: Icon(icon, color: AppColors.iconDefault, size: 20),
      filled: true,
      fillColor: AppColors.surfacePrimary,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            const BorderSide(color: AppColors.strokeSoft, width: 0.68),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            const BorderSide(color: AppColors.strokeSoft, width: 0.68),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            const BorderSide(color: AppColors.strokeSubtle, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            const BorderSide(color: AppColors.redStrong, width: 0.68),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.redStrong, width: 1),
      ),
    );
  }

  // ── Sign-up button ────────────────────────────────────────────────────────

  Widget _buildSignUpButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleSignUp,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF6467),
              AppColors.redStrong,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4CFB2C36),
              blurRadius: 15,
              offset: Offset(0, 10),
            ),
            BoxShadow(
              color: Color(0x4CFB2C36),
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : const Text(
                'Sign-up',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white,
                  letterSpacing: -0.31,
                ),
              ),
      ),
    );
  }

  // ── Divider ───────────────────────────────────────────────────────────────

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: AppColors.strokeSubtle),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Or sign-up with',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textTertiary,
              letterSpacing: -0.15,
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: AppColors.strokeSubtle),
        ),
      ],
    );
  }

  // ── Social buttons ────────────────────────────────────────────────────────

  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _socialButton(
          label: 'G',
          onTap: _isGoogleLoading ? null : _handleGoogleSignUp,
          isLoading: _isGoogleLoading,
        ),
        const SizedBox(width: 16),
        _socialButton(label: 'f'),
      ],
    );
  }

  Widget _socialButton({required String label, VoidCallback? onTap, bool isLoading = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          // rgba(23,25,28,0.8) = cardOverlayStrong
          color: AppColors.cardOverlayStrong,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.strokeSoft),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textTertiary,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                ),
              ),
      ),
    );
  }

  // ── Login row ─────────────────────────────────────────────────────────────

  Widget _buildLoginRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already a member? ',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textTertiary,
            letterSpacing: -0.15,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          child: const Text(
            'Login',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              letterSpacing: -0.31,
            ),
          ),
        ),
      ],
    );
  }

  // ── Auth logic ────────────────────────────────────────────────────────────

  Future<void> _handleGoogleSignUp() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (!mounted) return;
      if (user != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => CompleteProfileScreen(user: user),
          ),
          (route) => false,
        );
      }
      // user == null means they cancelled the Google picker — do nothing
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signUpWithEmail(
        email: _email,
        password: _password,
        name: _displayName,
        age: int.parse(_ageForMaxHr.trim()),
      );

      if (user != null) {
        if (_displayName.isNotEmpty) {
          await user.updateDisplayName(_displayName);
          await user.reload();
        }

        final age = int.parse(_ageForMaxHr.trim());
        final weight = int.parse(_weight.trim());

        await hrState.updateAge(age);
        await hrState.setCustomMaxHr(null);

        await _db.collection('users').doc(user.uid).set({
          'displayName': _displayName,
          'email': _email,
          'age': age,
          'weight': weight,
          'gender': _gender,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AppShell()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ── Header widget ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo container
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            // rgba(23,25,28,0.10)
            color: const Color(0x1A17191C),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.strokeSoft),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.favorite,
            color: AppColors.red,
            size: 48,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Heart Link',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
            letterSpacing: 0.76,
          ),
        ),
      ],
    );
  }
}
