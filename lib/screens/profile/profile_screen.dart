import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';           // 🔹 新增
import 'package:heart_link_app/services/auth_service.dart';
import 'package:heart_link_app/screens/heartratedial/hr.state.dart';
import 'package:heart_link_app/shell/app_shell.dart';

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
    _user = FirebaseAuth.instance.currentUser;
  }

  // age custom
  Future<void> _editAge({
    required String title,
    required int initial,
  }) async {
    final ctrl = TextEditingController(
      text: initial > 0 ? '$initial' : '',
    );

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Enter age'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final customAge = int.tryParse(ctrl.text.trim());
              if (customAge == null || customAge <= 0 || customAge > 200) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid age.')),
                );
                return;
              }
              await hrState.updateAge(customAge);
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final cs = Theme.of(context).colorScheme;  

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AppShell()),
            );
          },
        ),
      ),
      body: user == null
          ? const Center(child: Text('No user info'))
          : AnimatedBuilder(
              animation: hrState,
              builder: (context, _) {
                final int? age = hrState.age;
                final int maxHr = hrState.maxHr;

                // get gender and weight from Firestore
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, snap) {
                    // default texts
                    String genderText = 'Not set';
                    String weightText = 'Not set';

                    if (snap.hasData && snap.data!.exists) {
                      final data =
                          snap.data!.data() as Map<String, dynamic>? ?? {};

                      final gender = data['gender'];
                      final weight = data['weight'];

                      if (gender is String && gender.trim().isNotEmpty) {
                        genderText = gender.trim();
                      }
                      if (weight != null) {
                        final w = weight.toString();
                        if (w.isNotEmpty) {
                          weightText = '$w bl';
                        }
                      }
                    }

                    String displayName;
                    if (user.displayName != null &&
                        user.displayName!.isNotEmpty) {
                      displayName = user.displayName!;
                    } else {
                      displayName = 'Unknown';
                    }

                    String initials;
                    if (displayName.isNotEmpty) {
                      initials = displayName[0].toUpperCase();
                    } else {
                      initials = 'N';
                    }

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: cs.primary.withOpacity(.25),
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
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
                        // Gender
                        ListTile(
                          title: const Text('Gender'),
                          subtitle: Text(genderText),
                        ),
                        // Weight
                        ListTile(
                          title: const Text('Weight'),
                          subtitle: Text(weightText),
                        ),

                        const SizedBox(height: 8),

                        // Heart Rate Settings
                        _sectionTitle('Heart Rate Settings'),
                        ListTile(
                          title: const Text("Age"),
                          subtitle: Text(
                            age != null ? "$age years" : "Not set",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _editAge(
                            title: "Set Age",
                            initial: age ?? 0,
                          ),
                        ),
                        ListTile(
                          title: const Text('MaxHR'),
                          subtitle: Text('$maxHr bpm'),
                        ),

                        const SizedBox(height: 8),
                        const Divider(),

                        // sign out
                        FilledButton(
                          onPressed: () async {
                            await _authService.signOut();
                            if (!mounted) return;
                            Navigator.pushReplacementNamed(
                                context, '/login');
                          },
                          child: const Text('Sign Out'),
                        ),
                      ],
                    );
                  },
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
        style: const TextStyle(
          fontSize: 14,
          color: Color.fromARGB(137, 244, 236, 236),
        ),
      ),
    );
  }
}