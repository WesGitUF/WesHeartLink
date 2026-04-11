import 'package:flutter/material.dart';
import 'package:heart_link_app/app/theme/app_theme.dart';
import 'package:heart_link_app/screens/session/session_flow_widgets.dart';

class SessionTypeScreen extends StatefulWidget {
  const SessionTypeScreen({super.key, required this.workoutMode});

  final String workoutMode;

  @override
  State<SessionTypeScreen> createState() => _SessionTypeScreenState();
}

class _SessionTypeScreenState extends State<SessionTypeScreen> {
  static const List<_SessionTypeOption> _options = <_SessionTypeOption>[
    _SessionTypeOption(
      id: 'solo',
      title: 'Solo',
      subtitle: 'Track your workout on your own.',
      icon: Icons.person_rounded,
      accent: AppColors.orange,
      accentBackground: Color(0x26FF8904),
    ),
    _SessionTypeOption(
      id: 'create',
      title: 'Create Session',
      subtitle: 'Start a workout and invite someone else.',
      icon: Icons.add_circle_outline_rounded,
      accent: AppColors.redStrong,
      accentBackground: Color(0x26FB2C36),
    ),
    _SessionTypeOption(
      id: 'join',
      title: 'Paired Workout',
      subtitle: 'Join a session someone else already created.',
      icon: Icons.people_alt_outlined,
      accent: AppColors.blue,
      accentBackground: Color(0x2651A2FF),
    ),
  ];

  String? _selectedType;

  void _handleContinue() {
    final String? selectedType = _selectedType;
    if (selectedType == null) return;

    Navigator.pushNamed(
      context,
      '/sensorSelection',
      arguments: <String, dynamic>{
        'workoutMode': widget.workoutMode,
        'sessionType': selectedType,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasSelection = _selectedType != null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.pageBackground),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: <Widget>[
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: <Widget>[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 6, 24, 140),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(<Widget>[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SessionFlowBackButton(
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Center(
                          child: Icon(
                            Icons.favorite_rounded,
                            size: 56,
                            color: AppColors.redStrong,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Choose Session Type',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'How do you want to start this workout?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 34),
                        ..._options.map((option) {
                          final bool isSelected = _selectedType == option.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _SessionTypeCard(
                              option: option,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedType = isSelected ? null : option.id;
                                });
                              },
                            ),
                          );
                        }),
                      ]),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 34,
                child: SessionFlowContinueButton(
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

class _SessionTypeCard extends StatelessWidget {
  const _SessionTypeCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _SessionTypeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const BorderRadius cardRadius = BorderRadius.all(Radius.circular(24));

    return Material(
      color: Colors.transparent,
      borderRadius: cardRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: cardRadius,
        child: Ink(
          height: 102,
          decoration: BoxDecoration(
            borderRadius: cardRadius,
            border: Border.all(
              color:
                  isSelected
                      ? option.accent.withValues(alpha: 0.65)
                      : AppColors.strokeSoft,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color:
                    isSelected
                        ? option.accent.withValues(alpha: 0.18)
                        : const Color(0x33000000),
                blurRadius: isSelected ? 24 : 18,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
            ],
            gradient:
                isSelected
                    ? LinearGradient(
                      begin: const Alignment(-0.95, -0.35),
                      end: const Alignment(1, 0.65),
                      colors: <Color>[
                        option.accent.withValues(alpha: 0.24),
                        const Color(0xCC17191C),
                      ],
                    )
                    : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0x6617191C), Color(0x4D17191C)],
                    ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: option.accentBackground,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(option.icon, color: option.accent, size: 28),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        option.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option.subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  opacity: isSelected ? 1 : 0,
                  duration: const Duration(milliseconds: 140),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: option.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 18,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionTypeOption {
  const _SessionTypeOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.accentBackground,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color accentBackground;
}
