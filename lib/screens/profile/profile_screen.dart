import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:heart_link_app/services/auth_service.dart';
import 'package:heart_link_app/screens/heartratedial/hr.state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  User? _user;

  @override
  void initState() {
    super.initState();
    // read current user from firebase
    _user = FirebaseAuth.instance.currentUser;
  }

  // edit age dialog
  Future<void> _editAge({
    required String title,
    required int initial,
  }) async {
    final ctrl = TextEditingController(text: '$initial');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
        ),
        actions: [
          //cancel button without saving
          TextButton(onPressed: () => Navigator.pop(context), 
          child: const Text('Cancel')),
          //save button
          FilledButton(
            onPressed: () async {
              final customAge = int.tryParse(ctrl.text.trim());
              if (customAge == null || customAge <= 0 || customAge > 200) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid age.')),
                );
                return;
              }
              // Update hrState age(recomputes maxHr)
              await hrState.updateAge(customAge);
              if (mounted) {
                Navigator.pop(context);}
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }


  // connect device (TODO)
  void _connectDevice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scan & connect device… (TODO)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: Text('No user info'))
          : AnimatedBuilder(
              animation: hrState, // listen to hrState changes
              builder: (context, _) {
                final int? age = hrState.age;
                final int maxHr = hrState.maxHr;   

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // User avatar and name
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: const Color(0xFFBD4658),
                          backgroundImage: user.photoURL != null
                              ? NetworkImage(user.photoURL!)
                              : null,
                          child: user.photoURL == null
                              ? const Icon(Icons.person, size: 36)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            user.displayName?.isNotEmpty == true
                                ? user.displayName!
                                : (user.email?.split('@').first ?? 'Unknown'),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Account
                    _sectionTitle('Account'),
                    ListTile(
                      title: const Text('Email'),
                      subtitle: Text(user.email ?? 'Unknown'),
                    ),

                    // Heart Rate Settings
                    const SizedBox(height: 8),
                    _sectionTitle('Heart Rate Settings'),

                    // Age
                    ListTile(
                      title: const Text('Age'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$age', style: const TextStyle(color: Colors.white70)),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => _editAge(title: 'Set Age', initial: age?? 0),
                    ),

                    // MaxHR
                    ListTile(
                      title: const Text('MaxHR'),
                      subtitle: Text('$maxHr bpm'),
                    ),

                    const SizedBox(height: 8),

                    // Device
                    _sectionTitle('Device'),
                    ListTile(
                      leading: const Icon(Icons.watch_rounded),
                      title: const Text('Connect Heart Rate Sensor'),
                      subtitle: const Text('BLE'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _connectDevice,
                    ),

                    const SizedBox(height: 16),
                    const Divider(),

                    FilledButton(
                      onPressed: () async {
                        await _authService.signOut();
                        if (!mounted) {
                          return;}
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text('Sign Out'),
                    ),
                  ],
                );
              },
            ),
    );
  }

  // section title widget
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: Color.fromARGB(137, 244, 236, 236)),
      ),
    );
  }
}