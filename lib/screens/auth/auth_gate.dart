import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:heart_link_app/shell/app_shell.dart';
import 'package:heart_link_app/screens/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Not logged in
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // Logged in → show shell
        return const AppShell();
      },
    );
  }
}
