import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:heart_link_app/services/auth_service.dart';
import 'package:heart_link_app/screens/heartratedial/hr.state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  // ───────────────────────────────────────────────────────────────
  // Edit Age dialog
  // ───────────────────────────────────────────────────────────────
  Future<void> _editAge(int initialAge) async {
    final ctrl = TextEditingController(
      text: initialAge > 0 ? '$initialAge' : '',
    );

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Set Age"),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "Enter your age"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            child: const Text("Save"),
            onPressed: () async {
              final val = int.tryParse(ctrl.text.trim());
              if (val == null || val <= 0 || val > 120) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid age")));
                return;
              }

              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(user.uid)
                    .update({"age": val});
              }

              await hrState.updateAge(val);
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // BUILD
  // ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final cs = Theme.of(context).colorScheme;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Not signed in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
      ),

      // STREAM FIRESTORE DOC ───────────────────────────────────────
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.data!.exists) {
            return const Center(child: Text("Profile not found."));
          }

          final data = snap.data!.data() as Map<String, dynamic>? ?? {};

          // Extract Firestore fields
          final displayName = (data['displayName'] as String?)?.trim() ?? "";
          final email = (data['email'] as String?)?.trim() ?? user.email ?? "";
          final age = data['age'] as int?;
          final weight = data['weight']?.toString();
          final gender = data['gender']?.toString();
          final photoUrl = (data['photoURL'] as String?);

          final hrAge = hrState.age;
          //final maxHr = hrState.maxHr;
          final maxHr = data['age'] != null
              ? (208 - 0.7 * (data['age'] as int)).round()
              : hrState.maxHr;

          // initial letter for avatar
          final initials = displayName.isNotEmpty
              ? displayName[0].toUpperCase()
              : (email.isNotEmpty ? email[0].toUpperCase() : "?");

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ───────────────────────────────────────────────
              // HEADER - AVATAR + NAME
              // ───────────────────────────────────────────────
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: cs.primary.withOpacity(.25),
                    backgroundImage:
                        (photoUrl != null && photoUrl.isNotEmpty)
                            ? NetworkImage(photoUrl)
                            : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      displayName.isNotEmpty ? displayName : email,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ───────────────────────────────────────────────
              // ACCOUNT
              // ───────────────────────────────────────────────
              _sectionTitle("Account"),

              ListTile(
                title: const Text("Email"),
                subtitle: Text(email),
              ),
              ListTile(
                title: const Text("Gender"),
                subtitle: Text(gender ?? "Not set"),
              ),
              ListTile(
                title: const Text("Weight"),
                subtitle: Text(weight != null ? "$weight kg" : "Not set"),
              ),

              const SizedBox(height: 10),

              // ───────────────────────────────────────────────
              // HEART RATE SETTINGS
              // ───────────────────────────────────────────────
              _sectionTitle("Heart Rate Settings"),

              ListTile(
                title: const Text("Age"),
                subtitle: Text(age != null ? "$age years" : "Not set"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editAge(age ?? 0),
              ),
              ListTile(
                title: const Text("Max HR"),
                subtitle: Text("$maxHr bpm"),
              ),

              const SizedBox(height: 30),

              // ───────────────────────────────────────────────
              // SIGN OUT BUTTON
              // ───────────────────────────────────────────────
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                ),
                onPressed: () async {
                  await _authService.signOut();
                  if (!mounted) return;
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text(
                  "Sign Out",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Section label
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Color.fromARGB(180, 255, 255, 255),
        ),
      ),
    );
  }
}