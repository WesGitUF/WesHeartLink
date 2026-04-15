import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:heart_link_app/screens/signup_screen.dart';
import 'package:heart_link_app/screens/splash/splash_screen.dart';
import 'firebase_options.dart';
import 'package:heart_link_app/radial-gauge.dart';
import 'package:heart_link_app/screens/session/session_screen.dart';
import 'package:heart_link_app/screens/session/choose_mode_screen.dart';
import 'package:heart_link_app/screens/session/sensor_selection_screen.dart';
import 'package:heart_link_app/screens/session/tracking_screen.dart';
import 'package:heart_link_app/screens/session/tracking_result_screen.dart';
import 'package:heart_link_app/screens/profile/profile_screen.dart';
import 'package:heart_link_app/services/auth_service.dart';
import 'package:heart_link_app/screens/max_hr_input_screen.dart';
import 'package:heart_link_app/screens/login_screen.dart';
import 'package:heart_link_app/shell/app_shell.dart';
import 'package:heart_link_app/app/theme/app_theme.dart';
import 'package:heart_link_app/screens/heartratedial/hr.state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  await hrState.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return MaterialApp(
      title: 'HeartLink',
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,

      home: SplashScreen(
        nextScreen: StreamBuilder<firebase_auth.User?>(
          stream: authService.userChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.active) {
              final firebase_auth.User? user = snapshot.data;
              if (user == null) {
                return const LoginScreen();
              } else {
                return const AppShell();
              }
            }
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const RegisterScreen(),
        '/home': (context) => const AppShell(),
        '/session': (context) => const SessionScreen(),
        '/sensorSelection': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return SensorSelectionScreen(
            workoutMode: args['workoutMode'] as String,
          );
        },
        '/chooseMode': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return ChooseModeScreen(
            workoutMode: args['workoutMode'] as String,
            userDeviceId: args['userDeviceId'] as String,
            isHost: args['isHost'] as bool,
          );
        },
        '/tracking': (context) => const TrackingScreen(),
        '/radialGauge': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return GaugeChart(
            userDeviceId: args['userDeviceId'],
            isOnline: args['isOnline'] as bool,
            isHost: args['isHost'] as bool,
            workoutMode: args['workoutMode'] as String,
            isSoloWorkout: (args['isSoloWorkout'] as bool?) ?? false,
          );
        },
        '/profile': (context) => const ProfileScreen(),
        '/maxHR': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return MaxHRInputScreen(workoutMode: args['workoutMode'] as String);
        },
        '/trackingResult': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return TrackingResultScreen(
            elapsedTime: args['elapsed'] as Duration,
            sameZoneTime: args['sameZone'] as Duration,
            workoutMode: args['workoutMode'] as String,
            workoutModeIcon: args['workoutModeIcon'] as IconData,
            maxHeartRate: args['maxHR'] as int,
            avgHeartRate: (args['avgHR'] as num).toDouble(),
            calories: (args['calories'] as num).toDouble(),
            series: args['series'] as List<int>,
            topZone: args['topZone'] as String,
            isSolo: args['isSolo'] as bool, //changed this
            theoreticalMaxHr: args['theoreticalMaxHr'] as int,
          );
        },
      },
    );
  }
}
