import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:heart_link_app/app/theme/app_theme.dart';
import 'package:heart_link_app/services/auth_service.dart';
import 'package:heart_link_app/screens/signup_screen.dart';
import 'package:heart_link_app/screens/complete_profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  String _email = '';
  String _password = '';
  bool _isLoading = false;

  // ── Auth handlers ─────────────────────────────────────────────────────────

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final User? user = await _authService.signInWithEmail(_email, _password);
      if (user == null) throw Exception('Sign-in failed');
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleFacebookLogin() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Facebook login coming soon')),
    );
  }

  Future<void> _handleGoogleLogin() async {
    try {
      final User? user = await _authService.signInWithGoogle();
      if (user == null || !mounted) return;

      // Check if profile is already complete
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;

      final hasProfile = doc.exists && doc.data()?['age'] != null;
      if (hasProfile) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => CompleteProfileScreen(user: user),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
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
                    const SizedBox(height: 80),
                    _buildHeader(),
                    const SizedBox(height: 12),
                    _buildFormFields(),
                    const SizedBox(height: 20),
                    _buildLoginButton(),
                    const SizedBox(height: 16),
                    _buildSignUpRow(),
                    const SizedBox(height: 20),
                    _buildSocialButtons(),
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

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: const Color(0x1A17191C),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.strokeSoft),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.favorite, color: AppColors.red, size: 48),
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
        const SizedBox(height: 12),
      ],
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────────

  Widget _buildFormFields() {
    return Column(
      children: [
        TextFormField(
          keyboardType: TextInputType.emailAddress,
          onChanged: (v) => _email = v.trim(),
          validator: (v) => (v == null || v.isEmpty) ? 'Enter email' : null,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            letterSpacing: -0.31,
          ),
          decoration: _inputDecoration(hint: 'Email', icon: Icons.mail_outline),
        ),
        const SizedBox(height: 20),
        TextFormField(
          obscureText: true,
          onChanged: (v) => _password = v,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Enter password' : null,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            letterSpacing: -0.31,
          ),
          decoration:
              _inputDecoration(hint: 'Password', icon: Icons.lock_outline),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {},
            child: const Text(
              'Forgot Password?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
                letterSpacing: -0.15,
              ),
            ),
          ),
        ),
      ],
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
      fillColor: AppColors.cardOverlayStrong,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.strokeSoft, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.strokeSoft, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.strokeSubtle, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.redStrong, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.redStrong, width: 1),
      ),
    );
  }

  // ── Login button ──────────────────────────────────────────────────────────

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleEmailLogin,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF6467), AppColors.redStrong],
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
                'Login',
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

  // ── Sign-up row ───────────────────────────────────────────────────────────

  Widget _buildSignUpRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Not a member? ',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textTertiary,
            letterSpacing: -0.15,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          ),
          child: const Text(
            'Sign-up',
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

  // ── Social buttons ────────────────────────────────────────────────────────

  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _socialButton(label: 'G', onTap: _handleGoogleLogin),
        const SizedBox(width: 16),
        _socialButton(label: 'f', onTap: _handleFacebookLogin),
      ],
    );
  }

  Widget _socialButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.cardOverlayStrong,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.strokeSoft),
        ),
        alignment: Alignment.center,
        child: Text(
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
}
