import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heart_link_app/app/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _heartScale;
  late Animation<double> _heartOpacity;
  late Animation<double> _textOpacity;

  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Heart pops in during first 50% of timeline
    _heartScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
      ),
    );

    _heartOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
      ),
    );

    // Text fades in during second half
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.forward();
      _navTimer = Timer(const Duration(milliseconds: 2800), _navigate);
    });
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => widget.nextScreen,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppGradients.pageBackground,
        ),
        child: RepaintBoundary(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // FadeTransition + ScaleTransition listen to the animation
              // directly at the render layer — no AnimatedBuilder needed
              FadeTransition(
                opacity: _heartOpacity,
                child: ScaleTransition(
                  scale: _heartScale,
                  child: const Icon(
                    Icons.favorite,
                    size: 100,
                    color: AppColors.red,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              FadeTransition(
                opacity: _textOpacity,
                child: Column(
                  children: [
                    Text(
                      'HeartLink',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Every Beat Counts',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 0.8,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
