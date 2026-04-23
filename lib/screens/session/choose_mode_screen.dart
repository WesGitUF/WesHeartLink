import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:heart_link_app/app/theme/app_theme.dart';
import 'package:lottie/lottie.dart';

class ChooseModeScreen extends StatefulWidget {
  const ChooseModeScreen({
    super.key,
    required this.workoutMode,
    required this.userDeviceId,
    required this.isHost,
  });

  final String workoutMode;
  final String userDeviceId;
  final bool isHost;

  @override
  State<ChooseModeScreen> createState() => _ChooseModeScreenState();
}

class _ChooseModeScreenState extends State<ChooseModeScreen> {
  bool? _selectedIsOnline;
  int _onlineTapCount = 0;

  void _handleContinue() {
    final bool? isOnline = _selectedIsOnline;
    if (isOnline == null) return;

    Navigator.pushNamed(
      context,
      '/radialGauge',
      arguments: <String, dynamic>{
        'userDeviceId': widget.userDeviceId,
        'isOnline': isOnline,
        'isHost': widget.isHost,
        'workoutMode': widget.workoutMode,
        'isSoloWorkout': false,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasSelection = _selectedIsOnline != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.pageBackground),
        child: SafeArea(
          bottom: false,
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
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          AnimatedOpacity(
                            opacity: _selectedIsOnline == false ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Lottie.asset(
                              'assets/images/pair-workout-animation.json',
                            ),
                          ),
                          AnimatedOpacity(
                            opacity: _selectedIsOnline == true ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Lottie.asset(
                              key: ValueKey<int>(_onlineTapCount),
                              'assets/images/different-location-animation.json',
                              repeat: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ModeActionCard(
                      theme: theme,
                      icon: Icons.wifi_off_rounded,
                      blurColor: const Color(0x26FF6467),
                      iconBackground: const Color(0x1AFF6467),
                      iconColor: const Color(0xFFFF8DA1),
                      title: 'Use without Internet',
                      subtitle:
                          'Choose this option if you are together (same location)',
                      isSelected: _selectedIsOnline == false,
                      onTap: () {
                        setState(() {
                          _selectedIsOnline =
                              _selectedIsOnline == false ? null : false;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    _ModeActionCard(
                      theme: theme,
                      icon: Icons.wifi_rounded,
                      blurColor: const Color(0x262B7FFF),
                      iconBackground: const Color(0x1A2B7FFF),
                      iconColor: const Color(0xFF6EA8FF),
                      title: 'Use with Internet',
                      subtitle:
                          'Choose this option if you are apart. (different locations)',
                      isSelected: _selectedIsOnline == true,
                      onTap: () {
                        setState(() {
                          if (_selectedIsOnline != true) _onlineTapCount++;
                          _selectedIsOnline =
                              _selectedIsOnline == true ? null : true;
                        });
                      },
                    ),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 34 + MediaQuery.of(context).padding.bottom,
                child: _ContinueButton(
                  enabled: hasSelection,
                  label: 'Continue',
                  onPressed: _handleContinue,
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
    required this.icon,
    required this.blurColor,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final ThemeData theme;
  final IconData icon;
  final Color blurColor;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final List<BoxShadow> boxShadow =
        isSelected
            ? <BoxShadow>[
              BoxShadow(
                color: AppColors.green.withValues(alpha: 0.22),
                blurRadius: 18,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ]
            : <BoxShadow>[
              const BoxShadow(
                color: Color(0x33000000),
                blurRadius: 18,
                spreadRadius: 0,
                offset: Offset(0, 8),
              ),
            ];

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
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.strokeSoft),
                  boxShadow: boxShadow,
                  gradient:
                      isSelected
                          ? LinearGradient(
                            begin: const Alignment(-0.95, -0.35),
                            end: const Alignment(1, 0.65),
                            colors: <Color>[
                              AppColors.green.withValues(alpha: 0.30),
                              const Color(0x9917191C),
                            ],
                          )
                          : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              Color(0x6617191C),
                              Color(0x4D17191C),
                            ],
                          ),
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
                        child: Icon(icon, color: iconColor, size: 30),
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
                  if (isSelected)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 18,
                        color: AppColors.white,
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

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow:
            enabled
                ? const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x59FB2C36),
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: Offset(0, 12),
                  ),
                ]
                : const <BoxShadow>[],
      ),
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient:
                  enabled
                      ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Color(0xFFFF6467), AppColors.redStrong],
                      )
                      : const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Color(0xFF3C3F44), Color(0xFF2A2C30)],
                      ),
            ),
            child: Center(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: enabled ? AppColors.white : AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
