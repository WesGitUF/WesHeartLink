import 'package:flutter/material.dart';
import 'package:heart_link_app/app/theme/app_theme.dart';
import 'package:heart_link_app/services/workout_service.dart';
import 'package:heart_link_app/shell/app_shell.dart';

class TrackingResultScreen extends StatelessWidget {
  final Duration elapsedTime;
  final Duration sameZoneTime;
  final String workoutMode;
  final IconData workoutModeIcon;
  final int maxHeartRate;
  final double avgHeartRate;
  final double calories;
  final List<int> series;
  final String topZone;
  final bool isSolo;
  final int theoreticalMaxHr; // use for history graph screen to show accurate
  // max HR for that session

  const TrackingResultScreen({
    super.key,
    required this.elapsedTime,
    required this.sameZoneTime,
    required this.workoutMode,
    required this.workoutModeIcon,
    required this.maxHeartRate,
    required this.avgHeartRate,
    required this.calories,
    required this.series,
    required this.topZone,
    required this.isSolo,
    required this.theoreticalMaxHr,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.pageBackground),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _StatsBox(
                      elapsedTime: elapsedTime,
                      sameZoneTime: sameZoneTime,
                      workoutMode: workoutMode,
                      workoutModeIcon: workoutModeIcon,
                      maxHeartRate: maxHeartRate,
                      avgHeartRate: avgHeartRate,
                      calories: calories,
                      series: series,
                      topZone: topZone,
                      isSolo: isSolo,
                      theoreticalMaxHr: theoreticalMaxHr,
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsBox extends StatefulWidget {
  final Duration elapsedTime;
  final Duration sameZoneTime;
  final String workoutMode;
  final IconData workoutModeIcon;
  final int maxHeartRate;
  final double avgHeartRate;
  final double calories;
  final List<int> series;
  final String topZone;
  final bool isSolo;
  final int theoreticalMaxHr;
  const _StatsBox({
    required this.elapsedTime,
    required this.sameZoneTime,
    required this.workoutMode,
    required this.workoutModeIcon,
    required this.maxHeartRate,
    required this.avgHeartRate,
    required this.calories,
    required this.series,
    required this.topZone,
    required this.isSolo,
    required this.theoreticalMaxHr,
  });

  @override
  State<_StatsBox> createState() => _StatsBoxState();
}

class _StatsBoxState extends State<_StatsBox> {
  bool _pressed = false;

  String get _workoutEmoji {
    switch (widget.workoutMode.trim().toLowerCase()) {
      case 'running':
        return '🏃';
      case 'cycling':
        return '🚴';
      case 'hiit':
        return '⚡';
      case 'walking':
        return '🚶';
      case 'swimming':
        return '🏊';
      default:
        return '💪';
    }
  }

  Color get _workoutAccent {
    switch (widget.workoutMode.trim().toLowerCase()) {
      case 'running':
        return AppColors.green;
      case 'cycling':
        return AppColors.blue;
      case 'hiit':
        return AppColors.orange;
      case 'walking':
        return AppColors.purple;
      case 'swimming':
        return AppColors.blue;
      default:
        return AppColors.white;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppGradients.cardSurface,
        border: Border.all(color: AppColors.strokeSoft),
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _workoutAccent.withValues(alpha: 0.16),
              border: Border.all(
                color: _workoutAccent.withValues(alpha: 0.34),
              ),
            ),
            child: Center(
              child: Text(
                _workoutEmoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.workoutMode,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Workout summary',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _StatTile(
            label: 'Elapsed Time',
            value: _formatDuration(widget.elapsedTime),
            icon: Icons.schedule_rounded,
            accent: AppColors.blue,
          ),
          const SizedBox(height: 12),
          if (!widget.isSolo) ...[
            _StatTile(
              label: 'Time in Same Zone',
              value: _formatDuration(widget.sameZoneTime),
              icon: Icons.favorite_rounded,
              accent: AppColors.pink,
            ),
            const SizedBox(height: 12),
          ],
          _StatTile(
            label: 'Max Heart Rate',
            value: '${widget.maxHeartRate} bpm',
            icon: Icons.monitor_heart_rounded,
            accent: AppColors.green,
          ),
          const SizedBox(height: 12),
          _StatTile(
            label: 'Average Heart Rate',
            value: '${widget.avgHeartRate.round()} bpm',
            icon: Icons.favorite_border_rounded,
            accent: AppColors.orange,
          ),
          const SizedBox(height: 12),
          _StatTile(
            label: 'Calories Burned',
            value: '${widget.calories.round()} kcal',
            icon: Icons.local_fire_department_rounded,
            accent: AppColors.purple,
          ),
          const SizedBox(height: 12),
          _StatTile(
            label: 'Peak Heart Rate Zone',
            value: widget.topZone,
            icon: Icons.bolt_rounded,
            accent: AppColors.blue,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow:
                    !_pressed
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
                  onPressed:
                      _pressed
                          ? null
                          : () {
                            setState(() => _pressed = true);
                            WorkoutService().saveEntry(
                              avgHr: widget.avgHeartRate,
                              bpmSeries: widget.series,
                              elapsed: widget.elapsedTime,
                              workoutMode: widget.workoutMode,
                              maxSessionHr: widget.maxHeartRate,
                              topZone: widget.topZone,
                              theoreticalMaxHr: widget.theoreticalMaxHr,
                            );
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AppShell(),
                              ),
                              (_) => false,
                            );
                          },
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
                          !_pressed
                              ? const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  Color(0xFFFF6467),
                                  AppColors.redStrong,
                                ],
                              )
                              : const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  Color(0xFF3C3F44),
                                  Color(0xFF2A2C30),
                                ],
                              ),
                    ),
                    child: Center(
                      child: Text(
                        _pressed ? 'Saving...' : 'Return Home',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: !_pressed
                              ? AppColors.white
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.strokeSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.16),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
