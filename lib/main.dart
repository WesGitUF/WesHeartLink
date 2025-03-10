import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:heart_link_app/screens/home/home_screen.dart';
import 'package:heart_link_app/screens/session/session_screen.dart';
import 'package:heart_link_app/screens/session/sensor_selection_screen.dart';
import 'package:heart_link_app/screens/session/tracking_screen.dart';
import 'package:heart_link_app/screens/session/tracking_result_screen.dart';
import 'package:heart_link_app/screens/profile/profile_screen.dart';
import 'package:heart_link_app/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        '/tracking': (context) => const TrackingScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/trackingResult': (context) {
          final elapsed = ModalRoute.of(context)!.settings.arguments as Duration;
          return TrackingResultScreen(elapsedTime: elapsed);
        },
      },
    );
  }
}
