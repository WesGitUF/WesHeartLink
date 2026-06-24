import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:heart_link_app/app/theme/app_theme.dart';
import 'package:heart_link_app/screens/heartratedial/hr.state.dart';
import 'package:heart_link_app/shell/app_shell.dart';

class CompleteProfileScreen extends StatefulWidget {
  final User user;
  const CompleteProfileScreen({super.key, required this.user});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = FirebaseFirestore.instance;

  late String _displayName;
  String _ageForMaxHr = '';
  String _weight = '';
  String? _gender;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill name from Google/Facebook if available
    _displayName = widget.user.displayName ?? '';
  }

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
                    const SizedBox(height: 48),
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildFormFields(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
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
          child: const Icon(Icons.person_outline, color: AppColors.red, size: 48),
        ),
        const SizedBox(height: 16),
        const Text(
          'Complete Your Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'We need a few more details to personalise your experience.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textTertiary,
            letterSpacing: -0.15,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _inputField(
          hint: 'Username',
          icon: Icons.person_outline,
          initialValue: _displayName,
          onChanged: (v) => _displayName = v.trim(),
          validator: (v) => (v == null || v.isEmpty) ? 'Enter username' : null,
        ),
        const SizedBox(height: 18),
        _inputField(
          hint: 'Age',
          icon: Icons.calendar_today_outlined,
          keyboardType: TextInputType.number,
          onChanged: (v) => _ageForMaxHr = v,
          validator: (v) {
            final age = int.tryParse(v ?? '');
            if (age == null || age <= 0 || age >= 200) return 'Enter valid age';
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
            if (weight == null || weight <= 0 || weight >= 500) return 'Enter valid weight';
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
    String? initialValue,
    TextInputType? keyboardType,
    required void Function(String) onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      initialValue: initialValue,
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
      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.iconDefault),
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

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.strokeSoft, width: 0.68),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.strokeSoft, width: 0.68),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.strokeSubtle, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.redStrong, width: 0.68),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.redStrong, width: 1),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleSave,
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
                'Save & Continue',
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final age = int.parse(_ageForMaxHr.trim());
      final weight = int.parse(_weight.trim());

      await widget.user.updateDisplayName(_displayName);
      await widget.user.reload();

      await hrState.updateAge(age);
      await hrState.setCustomMaxHr(null);

      await _db.collection('users').doc(widget.user.uid).set({
        'displayName': _displayName,
        'email': widget.user.email ?? '',
        'age': age,
        'weight': weight,
        'gender': _gender,
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
