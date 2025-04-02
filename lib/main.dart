import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:heart_link_app/screens/home/home_screen.dart';
import 'package:heart_link_app/screens/role_selection_screen.dart';
import 'package:heart_link_app/screens/session/session_screen.dart';
import 'package:heart_link_app/screens/session/sensor_selection_screen.dart';
import 'package:heart_link_app/screens/session/tracking_screen.dart';
import 'package:heart_link_app/screens/session/tracking_result_screen.dart';
import 'package:heart_link_app/screens/profile/profile_screen.dart';
import 'package:heart_link_app/services/auth_service.dart';
import 'package:heart_link_app/screens/max_hr_input_screen.dart';





void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
   // Sign in anonymously
  await firebase_auth.FirebaseAuth.instance.signInAnonymously();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return MaterialApp(
      title: 'HeartLink',
      theme: ThemeData(primarySwatch: Colors.red),
      // Use a StreamBuilder to listen to auth changes
      home: StreamBuilder<firebase_auth.User?>(
        stream: authService.userChanges,
        builder: (context, snapshot) {
          // If the connection is active, check for a logged-in user
          if (snapshot.connectionState == ConnectionState.active) {
            final firebase_auth.User? user = snapshot.data;
            if (user == null) {
              // return const LoginScreen();
              return const HomeScreen();
            } else {
              return const HomeScreen();
            }
          }
          // While waiting for auth state, show a loading indicator
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
      routes: {
        // '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/session': (context) => const SessionScreen(),
        '/sensorSelection': (context) => const SensorSelectionScreen(),
        '/roleSelection': (context) => const RoleSelectionScreen(),
        '/tracking': (context) => const TrackingScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/maxHR': (context) => const MaxHRInputScreen(),
        '/trackingResult': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return TrackingResultScreen(
              elapsedTime: args['elapsed'] as Duration,
              sameZoneTime: args['sameZone'] as Duration,
              avgUserHR: args['avgUserHR'] as double,
              avgPartnerHR: args['avgPartnerHR'] as double,
              avgHR: args['avgHR'] as double,
            );
        },
      },
    );
  }
}
