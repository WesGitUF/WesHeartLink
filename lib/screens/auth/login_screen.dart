import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:heart_link_app/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Center(
        // child: _isLoading
        //     ? const CircularProgressIndicator()
        //     : ElevatedButton(
        //         onPressed: () async {
        //         setState(() => _isLoading = true);
        //         try {
        //           final user = await _authService.signInWithEmail(_email, _password);
        //           if (user != null) {
        //             // Optional: seed only for your test email
        //             if ((user.email ?? '').toLowerCase() == 'email@email.com') {
        //               await _authService.updateProfileData(
        //                 user,
        //                 name: 'Ethan Willis',
        //                 age: 21
        //               );
        //             }
        //             Navigator.pushReplacementNamed(context, '/home');
        //           }
        //         } catch (e) {
        //           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        //         } finally {
        //           setState(() => _isLoading = false);
        //         }
        //       },
        //         child: const Text('Sign In with Hardcoded Credentials'),
        //       ),
      ),
    );
  }
}
