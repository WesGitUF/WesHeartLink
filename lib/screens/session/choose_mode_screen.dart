import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:heart_link_app/app/theme/app_theme.dart';

class ChooseModeScreen extends StatelessWidget {
  const ChooseModeScreen({
    super.key,
    required this.workoutMode,
    required this.userDeviceId,
    required this.isHost,
  });

  final String workoutMode;
  final String userDeviceId;
  final bool isHost;

  void _openWorkout(BuildContext context, {required bool isOnline}) {
    Navigator.pushNamed(
      context,
      '/radialGauge',
      arguments: <String, dynamic>{
        'userDeviceId': userDeviceId,
        'isOnline': isOnline,
        'isHost': isHost,
        'workoutMode': workoutMode,
        'isSoloWorkout': false,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.pageBackground),
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              Positioned(
                top: 160,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: <Color>[
                          AppColors.orangeStrong.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 20),
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      height: 83,
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                size: 20,
                              ),
                              color: AppColors.textPrimary,
                              splashRadius: 20,
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Choose Mode',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _ModeActionCard(
                      theme: theme,
                      svgAsset: 'assets/icons/createsessionicon.svg',
                      blurColor: const Color(0x26FF6467),
                      iconBackground: const Color(0x1AFF6467),
                      title: 'Use without Internet',
                      subtitle:
                          'Choose this option if you are together (same location)',
                      onTap: () => _openWorkout(context, isOnline: false),
                    ),
                    const SizedBox(height: 18),
                    _ModeActionCard(
                      theme: theme,
                      svgAsset: 'assets/icons/joinsessionicon.svg',
                      blurColor: const Color(0x262B7FFF),
                      iconBackground: const Color(0x1A2B7FFF),
                      title: 'Use with Internet',
                      subtitle:
                          'Choose this option if you are apart. (different locations)',
                      onTap: () => _openWorkout(context, isOnline: true),
                    ),
                    const Spacer(),
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

class _ModeActionCard extends StatelessWidget {
  const _ModeActionCard({
    required this.theme,
    required this.svgAsset,
    required this.blurColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final ThemeData theme;
  final String svgAsset;
  final Color blurColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 108,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardOverlaySoft.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.strokeSoft),
                  boxShadow: AppShadows.cardShadow,
                ),
              ),
            ),
            Positioned(
              left: 6,
              top: 10,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: blurColor,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: iconBackground,
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: SvgPicture.asset(svgAsset),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
