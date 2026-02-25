import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:heart_link_app/screens/signup_screen.dart';
import 'firebase_options.dart';
import 'package:heart_link_app/radial-gauge.dart';
import 'package:heart_link_app/screens/session/session_screen.dart';
import 'package:heart_link_app/screens/session/sensor_selection_screen.dart';
import 'package:heart_link_app/screens/session/tracking_screen.dart';
import 'package:heart_link_app/screens/session/tracking_result_screen.dart';
import 'package:heart_link_app/screens/profile/profile_screen.dart';
import 'package:heart_link_app/services/auth_service.dart';
import 'package:heart_link_app/screens/max_hr_input_screen.dart';
import 'package:heart_link_app/screens/login_screen.dart';
import 'package:heart_link_app/shell/app_shell.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Dark theme configuration
  ThemeData get _darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0D0D0D), 
      colorScheme: const ColorScheme.dark(
        primary: Color.fromARGB(255, 209, 97, 95), 
        secondary: Color.fromARGB(255, 159, 14, 14),
        surface: Color(0xFF121212),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Color.fromARGB(255, 161, 51, 50)),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFE53935),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1A1A1A),
        selectedItemColor: Color.fromARGB(255, 187, 90, 88),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(color: Colors.white),
      ),
      useMaterial3: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return MaterialApp(
      title: 'HeartLink',
      theme: _darkTheme,
      darkTheme: _darkTheme,
      themeMode: ThemeMode.dark,

      // Use a StreamBuilder to listen to auth changes
      home: StreamBuilder<firebase_auth.User?>(
        stream: authService.userChanges,
        builder: (context, snapshot) {
          // If the connection is active, check for a logged-in user
          if (snapshot.connectionState == ConnectionState.active) {
            final firebase_auth.User? user = snapshot.data;
            if (user == null) {
              // return const LoginScreen();
              return const LoginScreen();
            } else {
              return const AppShell();
            }
          }
          // While waiting for auth state, show a loading indicator
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const RegisterScreen(),
        '/home': (context) => const AppShell(),
        '/session': (context) => const SessionScreen(),
        '/sensorSelection': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return SensorSelectionScreen(
            workoutMode: args['workoutMode'] as String
          );
        },
        '/tracking': (context) => const TrackingScreen(),
        '/radialGauge': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return GaugeChart(
            userDeviceId: args['userDeviceId'],
            isOnline: args['isOnline'] as bool,
            isHost: args['isHost'] as bool,
            workoutMode: args['workoutMode'] as String
          );
        },
        '/profile': (context) => const ProfileScreen(),
        '/maxHR': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return MaxHRInputScreen(
            workoutMode: args['workoutMode'] as String
          );
        },
        '/trackingResult': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return TrackingResultScreen(
            elapsedTime: args['elapsed'] as Duration,
            sameZoneTime: args['sameZone'] as Duration,
            workoutMode: args['workoutMode'] as String,
            workoutModeIcon: args['workoutModeIcon'] as IconData,
            maxHeartRate: args['maxHR'] as int,
            avgHeartRate: (args['avgHR'] as num).toDouble(),
            series: args['series'] as List<int>,
            topZone: args['topZone'] as String,
            isSolo: args['isSolo'] as bool, //changed this
            theoreticalMaxHr: args['theoreticalMaxHr'] as int
          );
        },
      },
    );
  }
}
