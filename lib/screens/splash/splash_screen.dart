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
  late Animation<double> _heartIntroScale;
  late Animation<double> _heartOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _expandProgress;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _heartOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
      ),
    );

    // Heart pops in during first 35%
    _heartIntroScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.35, curve: Curves.elasticOut),
      ),
    );

    // Text fades in during middle
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.35, 0.6, curve: Curves.easeIn),
      ),
    );

    // Heart expands to fill screen in the final phase
    _expandProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.72, 1.0, curve: Curves.easeInCubic),
      ),
    );

    _ctrl.addStatusListener(_onAnimationStatus);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.forward();
    });
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _navigate();
    }
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => widget.nextScreen,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.removeStatusListener(_onAnimationStatus);
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
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final size = MediaQuery.of(context).size;
              // Scale the 100px heart to fully cover the screen from its center
              final maxScale = (size.longestSide * 2.5) / 100.0;
              final expandScale =
                  1.0 + _expandProgress.value * (maxScale - 1.0);
              final totalScale = _heartIntroScale.value * expandScale;
              final textAlpha =
                  (_textOpacity.value * (1.0 - _expandProgress.value * 1.5))
                      .clamp(0.0, 1.0);

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: _heartOpacity.value,
                    child: Transform.scale(
                      scale: totalScale,
                      child: const Icon(
                        Icons.favorite,
                        size: 100,
                        color: AppColors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Opacity(
                    opacity: textAlpha,
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.8,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
