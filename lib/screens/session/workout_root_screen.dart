import 'package:flutter/material.dart';
import 'package:heart_link_app/app/theme/app_theme.dart';
import 'package:heart_link_app/screens/session/active_workout_screen.dart';
import 'package:heart_link_app/screens/heartratedial/hr.state.dart';

class WorkoutRootScreen extends StatelessWidget {
  const WorkoutRootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: hrState,
      builder: (context, _) {
        final activeConfig = hrState.activeWorkout;

        if (activeConfig != null) {
          return ActiveWorkoutScreen(config: activeConfig);
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.pageBackground,
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.favorite_border_rounded,
                        size: 58,
                        color: AppColors.redStrong,
                      ),
                      SizedBox(height: 18),
                      Text(
                        'No workout in progress',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Press + to start a workout and track your progress.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}