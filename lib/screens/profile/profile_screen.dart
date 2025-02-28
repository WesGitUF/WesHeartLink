// TODO Implement this library.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:heart_link_app/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Dashboard')),
      body: _user == null
          ? const Center(child: Text('No user info'))
          : Column(
              children: [
                ListTile(
                  title: const Text('Name'),
                  subtitle: Text(_user!.displayName ?? 'Unknown'),
                ),
                ListTile(
                  title: const Text('Email'),
                  subtitle: Text(_user!.email ?? 'Unknown'),
                ),
                const Divider(),
                ElevatedButton(
                  onPressed: () {
                    _authService.signOut();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text('Sign Out'),
                ),
              ],
            ),
    );
  }
}
