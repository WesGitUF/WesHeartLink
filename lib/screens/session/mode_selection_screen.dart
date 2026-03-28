import 'package:flutter/material.dart';
import 'package:heart_link_app/app/theme/app_theme.dart';
import 'package:heart_link_app/screens/session/widgets/session_action_card.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({
    super.key,
    required this.userDeviceId,
    required this.isHost,
    required this.workoutMode,
  });

  final String userDeviceId;
  final bool isHost;
  final String workoutMode;

  void _openSession(BuildContext context, {required bool isOnline}) {
    Navigator.pushNamed(
      context,
      '/radialGauge',
      arguments: {
        'userDeviceId': userDeviceId,
        'isOnline': isOnline,
        'isHost': isHost,
        'workoutMode': workoutMode,
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
            children: [
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
                        colors: [
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
                  children: [
                    SizedBox(
                      height: 83,
                      child: Row(
                        children: [
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
                    SessionActionCard(
                      theme: theme,
                      svgAsset: 'assets/icons/createsessionicon.svg',
                      blurColor: const Color(0x26FF6467),
                      iconBackground: const Color(0x1AFF6467),
                      title: 'Use without Internet',
                      subtitle:
                          'Choose this option if you are together (same location)',
                      onTap: () => _openSession(context, isOnline: false),
                    ),
                    const SizedBox(height: 14),
                    SessionActionCard(
                      theme: theme,
                      svgAsset: 'assets/icons/joinsessionicon.svg',
                      blurColor: const Color(0x262B7FFF),
                      iconBackground: const Color(0x1A2B7FFF),
                      title: 'Use with Internet',
                      subtitle:
                          'Choose this option if you are apart. (different locations)',
                      onTap: () => _openSession(context, isOnline: true),
                    ),
                    const SizedBox(height: 12),
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
