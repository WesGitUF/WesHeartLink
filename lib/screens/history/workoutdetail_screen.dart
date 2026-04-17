import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:heart_link_app/screens/history/history_screen.dart' show Workout;
import 'package:heart_link_app/screens/heartratedial/hr.state.dart';
import 'package:heart_link_app/app/theme/app_theme.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final Workout workout;
  final List<int> series;

  const WorkoutDetailScreen({
    super.key,
    required this.workout,
    required this.series,
  });

  String _computePeakZone(int sessionMaxHr, int theoreticalMaxHr) {
    if (theoreticalMaxHr <= 0) return 'Unknown';

    final p = sessionMaxHr / theoreticalMaxHr;

    if (p <= 0.65) return 'Zone 1';
    if (p <= 0.80) return 'Zone 2';
    if (p <= 0.89) return 'Zone 3';
    if (p <= 0.95) return 'Zone 4';
    return 'Zone 5';
  }

  String _formatDuration(Duration d) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(d.inHours)}:${pad(d.inMinutes.remainder(60))}:${pad(d.inSeconds.remainder(60))}';
  }

  String _displayName(User? user) {
    if (user == null) return 'User';
    if ((user.displayName ?? '').isNotEmpty) return user.displayName!;
    final email = user.email;
    if (email != null && email.isNotEmpty) return email.split('@').first;
    return 'User';
  }

  String _timeRange(BuildContext context, DateTime start, DateTime end) {
    final mq = MediaQuery.of(context);
    final startTime = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(start),
      alwaysUse24HourFormat: mq.alwaysUse24HourFormat,
    );
    final endTime = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(end),
      alwaysUse24HourFormat: mq.alwaysUse24HourFormat,
    );
    final date =
        '${start.month}/${start.day}/${start.year.toString().substring(2)} ';
    return '$date $startTime – $endTime';
  }

  Widget _statCell(String label, String value) {
    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user  = FirebaseAuth.instance.currentUser;

    final start = workout.start;
    final end   = start.add(workout.duration);

    final int sessionMaxHr = series.isEmpty
        ? (workout.maxSessionHr ?? workout.avgHr)
        : series.reduce((a, b) => a > b ? a : b);

    final int theoreticalMaxHr = workout.theoreticalMaxHr ?? hrState.maxHr;

    final String peakZone = _computePeakZone(sessionMaxHr, theoreticalMaxHr);


    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          workout.type,
          style: theme.textTheme.titleMedium,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.pageBackground,
        ),
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // User info row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surfacePrimary,
                backgroundImage: (user?.photoURL?.isNotEmpty == true)
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: (user?.photoURL?.isNotEmpty == true)
                    ? null
                    : const Icon(Icons.person_outline, size: 18, color:AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName(user),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeRange(context, start, end),
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Average heart rate card
          _GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.favorite_border_rounded,
                            size: 22,
                            color: AppColors.redStrong,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Average Heart Rate',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${workout.avgHr}',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontSize: 64,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'bpm',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // Heart rate trend graph
          if (series.isNotEmpty) ...[
            Text(
              'Heart Rate Trend',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _GlassCard(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 260,
                    child: _InteractiveHrChart(
                      series: series,
                      theoreticalMaxHr: theoreticalMaxHr,
                      yAxisMax: sessionMaxHr,
                      workoutDuration: workout.duration,
                      startLabel: '0:00',
                      endLabel: _formatDuration(workout.duration),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: const Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        _ZoneDot(color: Color(0xFF666A70), label: '40–65%'),
                        _ZoneDot(color: Color(0xFF2F6BDA), label: '66–80%'),
                        _ZoneDot(color: Color(0xFF66B35B), label: '81–89%'),
                        _ZoneDot(color: Color(0xFFF3A43B), label: '90–95%'),
                        _ZoneDot(color: Color(0xFFE25353), label: '95–100%'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Time in Zone
          if (series.isNotEmpty) ...[
            Text(
              'Time in Zone',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _GlassCard(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: _TimeInZoneCard(
                series: series,
                theoreticalMaxHr: theoreticalMaxHr,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Workout stats
          if (series.isNotEmpty) ...[
            Text(
              'Workout Data',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: [
                  _WorkoutStatCard(
                    label: 'Elapsed Time',
                    value: _formatDuration(workout.duration),
                    icon: Icons.schedule_outlined,
                    accent: AppColors.blue,
                  ),
                  _WorkoutStatCard(
                    label: 'Calories',
                    value: '${workout.calories} kcal',
                    icon: Icons.local_fire_department_outlined,
                    accent: AppColors.orange,
                  ),
                  _WorkoutStatCard(
                    label: 'Max HR',
                    value: '$sessionMaxHr bpm',
                    icon: Icons.favorite_border_rounded,
                    accent: AppColors.redStrong,
                  ),
                  _WorkoutStatCard(
                    label: 'Peak Zone',
                    value: peakZone,
                    icon: Icons.monitor_heart_outlined,
                    accent: AppColors.purple
                  ),
                ],
              ),
            ],
           ],
          ),
        ),
    );
  }
}

class _WorkoutStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _WorkoutStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.strokeSoft),
          boxShadow: AppShadows.cardShadow,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0x6617191C),
              Color(0x4D17191C),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: accent,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.strokeSoft),
          boxShadow: AppShadows.cardShadow,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0x6617191C),
              Color(0x4D17191C),
            ],
          ),
        ),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class _ZoneDot extends StatelessWidget {
  final Color color;
  final String label;

  const _ZoneDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TimeInZoneCard extends StatelessWidget {
  final List<int> series;
  final int theoreticalMaxHr;

  static const _zoneColors = [
    Color(0xFF666A70),
    Color(0xFF2F6BDA),
    Color(0xFF66B35B),
    Color(0xFFF3A43B),
    Color(0xFFE25353),
  ];

  static const _zoneLabels = [
    'Warm up / Recovery',
    'Endurance',
    'Aerobic',
    'Threshold',
    'Maximum',
  ];

  const _TimeInZoneCard({
    required this.series,
    required this.theoreticalMaxHr,
  });

  List<int> _zoneCounts() {
    final counts = List<int>.filled(5, 0);
    if (series.isEmpty || theoreticalMaxHr <= 0) return counts;
    for (final bpm in series) {
      final p = bpm / theoreticalMaxHr;
      if (p <= 0.65) { counts[0]++; }
      else if (p <= 0.80) { counts[1]++; }
      else if (p <= 0.89) { counts[2]++; }
      else if (p <= 0.95) { counts[3]++; }
      else { counts[4]++; }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final counts = _zoneCounts();
    final total = series.length;

    final z1Max = (theoreticalMaxHr * 0.65).round();
    final z2Max = (theoreticalMaxHr * 0.80).round();
    final z3Max = (theoreticalMaxHr * 0.89).round();
    final z4Max = (theoreticalMaxHr * 0.95).round();

    final hrRanges = [
      '0–$z1Max',
      '${z1Max + 1}–$z2Max',
      '${z2Max + 1}–$z3Max',
      '${z3Max + 1}–$z4Max',
      '${z4Max + 1}–$theoreticalMaxHr',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < 5; i++) ...[
          _ZoneRow(
            zoneNumber: i + 1,
            hrRange: hrRanges[i],
            label: _zoneLabels[i],
            color: _zoneColors[i],
            seconds: counts[i],
            totalSeconds: total,
          ),
          if (i < 4) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _ZoneRow extends StatelessWidget {
  final int zoneNumber;
  final String hrRange;
  final String label;
  final Color color;
  final int seconds;
  final int totalSeconds;

  const _ZoneRow({
    required this.zoneNumber,
    required this.hrRange,
    required this.label,
    required this.color,
    required this.seconds,
    required this.totalSeconds,
  });

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = totalSeconds > 0 ? seconds / totalSeconds : 0.0;
    final pct = (fraction * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Zone $zoneNumber ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    TextSpan(
                      text: '($hrRange) ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    TextSpan(
                      text: '• $label',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTime(seconds),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 30,
              child: Text(
                '$pct%',
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.strokeSoft),
                ),
              ),
              if (fraction > 0)
                Container(
                  height: 8,
                  width: constraints.maxWidth * fraction,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HrCurvePainter extends CustomPainter {
  final List<int> series;
  final int theoreticalMaxHr;
  final int yAxisMax;
  final int tickCount;
  final String startLabel;
  final String endLabel;
  final int? selectedIndex;
  final String? tooltipTime;

  // Zone boundaries as % of theoretical max HR — matches the legend labels
  static const double _greyUpperBound = 0.65; // 40–65%
  static const double _blueUpperBound = 0.80; // 66–80%
  static const double _greenUpperBound = 0.89; // 81–89%
  static const double _yellowUpperBound = 0.95; // 90–95%
  // above 95% → red

  static const Color _grey = Color(0xFF666A70);
  static const Color _blue = Color(0xFF2F6BDA);
  static const Color _green = Color(0xFF66B35B);
  static const Color _yellow = Color(0xFFF3A43B);
  static const Color _red = Color(0xFFE25353);

  _HrCurvePainter({
    required this.series,
    required this.theoreticalMaxHr,
    required this.yAxisMax,
    required this.tickCount,
    required this.startLabel,
    required this.endLabel,
    this.selectedIndex,
    this.tooltipTime,
  });

  Color _zoneColor(int bpm) {
    if (theoreticalMaxHr <= 0) return _grey;
    final percent = bpm / theoreticalMaxHr;
    if (percent <= _greyUpperBound) return _grey;
    if (percent <= _blueUpperBound) return _blue;
    if (percent <= _greenUpperBound) return _green;
    if (percent <= _yellowUpperBound) return _yellow;
    return _red;
  }

  ({double min, double max, List<int> ticks}) _buildAxis() {
    int low = series.reduce((a, b) => a < b ? a : b);
    int high = series.reduce((a, b) => a > b ? a : b);

    if (high < yAxisMax) high = yAxisMax;
    if (low == high) {
      low -= 5;
      high += 5;
    }

    // Add 8% padding around the range
    low -= ((high - low) * 0.08).round();
    high += ((high - low) * 0.08).round();

    // Snap to nearest 10
    low = (low / 10).floor() * 10;
    high = (high / 10).ceil() * 10;

    if (low < 40) low = 40;
    if (high <= low) high = low + 10;

    final count = tickCount.clamp(3, 8);
    final step = ((high - low) / (count - 1)).round();
    final ticks = List<int>.generate(count, (i) => low + step * i);

    return (min: low.toDouble(), max: (low + step * (count - 1))
        .toDouble(), ticks: ticks);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;

    const double paddingLeft = 44;
    const double paddingRight = 16;
    const double paddingTop = 40;
    const double paddingBottom = 26;

    final chartArea = Rect.fromLTWH(
      paddingLeft,
      paddingTop,
      size.width - paddingLeft - paddingRight,
      size.height - paddingTop - paddingBottom,
    );

    final axis = _buildAxis();
    final yMin = axis.min;
    final yMax = axis.max;

    double xForIndex(int index) {
      if (series.length == 1) return chartArea.left + chartArea.width / 2;
      return chartArea.left + chartArea.width * (index / (series.length - 1));
    }

    double yForValue(double value) {
      final t = ((value - yMin) / (yMax - yMin)).clamp(0.0, 1.0);
      return chartArea.bottom - chartArea.height * t;
    }

    // Grid lines and Y-axis labels
    final gridPaint = Paint()
      ..color = const Color.fromARGB(45, 255, 255, 255)
      ..strokeWidth = 1;

    const labelStyle = TextStyle(fontSize: 11, color: Colors.white70);

    for (final tick in axis.ticks) {
      final y = yForValue(tick.toDouble());

      canvas.drawLine(
          Offset(chartArea.left, y), Offset(chartArea.right, y), gridPaint);

      final leftLabel = TextPainter(
        text: TextSpan(text: '$tick', style: labelStyle),
        textDirection: TextDirection.ltr,
      )
        ..layout();
      leftLabel.paint(canvas, Offset(
          chartArea.left - 4 - leftLabel.width, y - leftLabel.height / 2));
    }

    // X-axis baseline
    canvas.drawLine(
      Offset(chartArea.left, chartArea.bottom),
      Offset(chartArea.right, chartArea.bottom),
      Paint()
        ..color = AppColors.strokeSoft
        ..strokeWidth = 2,
    );
    _drawText(canvas, Offset(chartArea.left, chartArea.bottom + 14), startLabel,
        fontSize: 11, color: Colors.white70);
    _drawText(canvas, Offset(chartArea.right, chartArea.bottom + 14), endLabel,
        fontSize: 11, color: Colors.white70, align: TextAlign.right);

    // Build point list
    final points = [
      for (int i = 0; i < series.length; i++)
        Offset(xForIndex(i), yForValue(series[i].toDouble())),
    ];

    // Draw colored curve segments
    final curvePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);

      final avgBpm = ((series[i] + series[i + 1]) / 2).round();
      curvePaint.color = _zoneColor(avgBpm);

      canvas.drawPath(
        Path()
          ..moveTo(p0.dx, p0.dy)
          ..quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy)..quadraticBezierTo(
            p1.dx, p1.dy, p1.dx, p1.dy),
        curvePaint,
      );
    }
    // Draw selection line + tooltip
    if (selectedIndex != null && selectedIndex! >= 0 && selectedIndex! < points.length) {
      final selPoint = points[selectedIndex!];
      final bpm = series[selectedIndex!];

      // Vertical line
      canvas.drawLine(
        Offset(selPoint.dx, chartArea.top),
        Offset(selPoint.dx, chartArea.bottom),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2,
      );

      // Dot at intersection
      canvas.drawCircle(
        selPoint,
        5,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        selPoint,
        3,
        Paint()..color = Colors.black,
      );

      // Tooltip bubble
      final tooltipText = '$bpm bpm';
      final timeText = tooltipTime ?? '';

      final bpmPainter = TextPainter(
        text: TextSpan(
          text: tooltipText,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final timePainter = TextPainter(
        text: TextSpan(
          text: timeText,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final bubbleWidth = (bpmPainter.width > timePainter.width ? bpmPainter.width : timePainter.width) + 20;
      final bubbleHeight = bpmPainter.height + timePainter.height + 10;

      double bubbleX = selPoint.dx - bubbleWidth / 2;
      if (bubbleX < chartArea.left) bubbleX = chartArea.left;
      if (bubbleX + bubbleWidth > chartArea.right) bubbleX = chartArea.right - bubbleWidth;

      final bubbleRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bubbleX, chartArea.top - bubbleHeight - 8, bubbleWidth, bubbleHeight),
        const Radius.circular(12),
      );

      canvas.drawRRect(
        bubbleRect,
        Paint()..color = _red,
      );

      final bubbleTop = chartArea.top - bubbleHeight - 8;
      final textBlockHeight = bpmPainter.height + timePainter.height;
      final textStartY = bubbleTop + (bubbleHeight - textBlockHeight) / 2;

      bpmPainter.paint(
        canvas,
        Offset(bubbleX + (bubbleWidth - bpmPainter.width) / 2, textStartY),
      );
      timePainter.paint(
        canvas,
        Offset(bubbleX + (bubbleWidth - timePainter.width) / 2, textStartY + bpmPainter.height),
      );
    }
  }

  void _drawText(Canvas canvas,
      Offset position,
      String text, {
        TextAlign align = TextAlign.left,
        double fontSize = 12,
        Color color = Colors.white,
      }) {
    final painter = TextPainter(
      text: TextSpan(
          text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )
      ..layout();
    final adjustedPosition = align == TextAlign.right
        ? position - Offset(painter.width, 0)
        : position;
    painter.paint(canvas, adjustedPosition);
  }

  @override
  bool shouldRepaint(covariant _HrCurvePainter old) {
    return series != old.series ||
        theoreticalMaxHr != old.theoreticalMaxHr ||
        yAxisMax != old.yAxisMax ||
        tickCount != old.tickCount ||
        startLabel != old.startLabel ||
        endLabel != old.endLabel ||
        selectedIndex != old.selectedIndex ||
        tooltipTime != old.tooltipTime;
  }
}

class _InteractiveHrChart extends StatefulWidget {
  final List<int> series;
  final int theoreticalMaxHr;
  final int yAxisMax;
  final Duration workoutDuration;
  final String startLabel;
  final String endLabel;

  const _InteractiveHrChart({
    required this.series,
    required this.theoreticalMaxHr,
    required this.yAxisMax,
    required this.workoutDuration,
    required this.startLabel,
    required this.endLabel,
  });

  @override
  State<_InteractiveHrChart> createState() => _InteractiveHrChartState();
}

class _InteractiveHrChartState extends State<_InteractiveHrChart> {
  int? _selectedIndex;

  String _formatTimeAtIndex(int index) {
    if (widget.series.length <= 1) return '0:00';
    final fraction = index / (widget.series.length - 1);
    final seconds = (widget.workoutDuration.inSeconds * fraction).round();
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _handleTouch(Offset localPosition, Size size) {
    const double paddingLeft = 44;
    const double paddingRight = 16;
    final chartWidth = size.width - paddingLeft - paddingRight;
    final x = (localPosition.dx - paddingLeft).clamp(0.0, chartWidth);
    final fraction = chartWidth == 0 ? 0.0 : x / chartWidth;
    final index = (fraction * (widget.series.length - 1)).round().clamp(0, widget.series.length - 1);
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _handleTouch(d.localPosition, size),
          onPanStart: (d) => _handleTouch(d.localPosition, size),
          onPanUpdate: (d) => _handleTouch(d.localPosition, size),
          child: CustomPaint(
            painter: _HrCurvePainter(
              series: widget.series,
              theoreticalMaxHr: widget.theoreticalMaxHr,
              yAxisMax: widget.yAxisMax,
              tickCount: 4,
              startLabel: widget.startLabel,
              endLabel: widget.endLabel,
              selectedIndex: _selectedIndex,
              tooltipTime: _selectedIndex != null ? _formatTimeAtIndex(_selectedIndex!) : null,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}