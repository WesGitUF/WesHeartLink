import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:heart_link_app/screens/history/history_screen.dart' show Workout;
import 'package:heart_link_app/screens/heartratedial/hr.state.dart';
import 'package:heart_link_app/app/theme/app_theme.dart';
import 'package:heart_link_app/screens/session/tracking_result_screen.dart';

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

    // Count readings per zone for the Time in Zone chart
    final zoneCounts = List<int>.filled(5, 0);
    if (series.isNotEmpty && theoreticalMaxHr > 0) {
      for (final bpm in series) {
        final p = bpm / theoreticalMaxHr;
        if (p <= 0.65)      zoneCounts[0]++;
        else if (p <= 0.80) zoneCounts[1]++;
        else if (p <= 0.89) zoneCounts[2]++;
        else if (p <= 0.95) zoneCounts[3]++;
        else                zoneCounts[4]++;
      }
    }
    final zonePercents = [
      for (final c in zoneCounts) series.isNotEmpty ? c / series.length : 0.0,
    ];

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
                    child: CustomPaint(
                      painter: _HrCurvePainter(
                        series: series,
                        theoreticalMaxHr: theoreticalMaxHr,
                        yAxisMax: sessionMaxHr,
                        tickCount: 4,
                        startLabel: '0:00',
                        endLabel: _formatDuration(workout.duration),
                      ),
                      size: Size.infinite,
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
              child: _ZoneBarChart(zonePercents: zonePercents),
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
                    label: 'Duration',
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

class _ZoneBarChart extends StatelessWidget{
  final List<double> zonePercents;

  static const List<Color> _colors = [
  Color(0xFF666A70), // Z1 — 40–65%                                     
  Color(0xFF2F6BDA), // Z2 — 66–80%                                     
  Color(0xFF66B35B), // Z3 — 81–89%                                     
  Color(0xFFF3A43B), // Z4 — 90–95%                                     
  Color(0xFFE25353), // Z5 — 95–100%
  ];

  const _ZoneBarChart({required this.zonePercents});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < 5; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i < 4 ? 10 : 0),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    'Z${i + 1}',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          // Track
                          Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              border: Border.all(color: AppColors.strokeSoft),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          // Filled bar
                          if (zonePercents[i] > 0)
                            Container(
                              height: 14,
                              width: constraints.maxWidth * zonePercents[i],
                              decoration: BoxDecoration(
                                color: _colors[i],
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${(zonePercents[i] * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
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

  // Zone boundaries as % of theoretical max HR — matches the legend labels
  static const double _greyUpperBound   = 0.65; // 40–65%
  static const double _blueUpperBound   = 0.80; // 66–80%
  static const double _greenUpperBound  = 0.89; // 81–89%
  static const double _yellowUpperBound = 0.95; // 90–95%
                                                 // above 95% → red

  static const Color _grey   = Color(0xFF666A70);
  static const Color _blue   = Color(0xFF2F6BDA);
  static const Color _green  = Color(0xFF66B35B);
  static const Color _yellow = Color(0xFFF3A43B);
  static const Color _red    = Color(0xFFE25353);

  _HrCurvePainter({
    required this.series,
    required this.theoreticalMaxHr,
    required this.yAxisMax,
    required this.tickCount,
    required this.startLabel,
    required this.endLabel,
  });

  Color _zoneColor(int bpm) {
    if (theoreticalMaxHr <= 0) return _grey;
    final percent = bpm / theoreticalMaxHr;
    if (percent <= _greyUpperBound)   return _grey;
    if (percent <= _blueUpperBound)   return _blue;
    if (percent <= _greenUpperBound)  return _green;
    if (percent <= _yellowUpperBound) return _yellow;
    return _red;
  }

  ({double min, double max, List<int> ticks}) _buildAxis() {
    int low  = series.reduce((a, b) => a < b ? a : b);
    int high = series.reduce((a, b) => a > b ? a : b);

    if (high < yAxisMax) high = yAxisMax;
    if (low == high) { low -= 5; high += 5; }

    // Add 8% padding around the range
    low  -= ((high - low) * 0.08).round();
    high += ((high - low) * 0.08).round();

    // Snap to nearest 10
    low  = (low  / 10).floor() * 10;
    high = (high / 10).ceil()  * 10;

    if (low < 40) low = 40;
    if (high <= low) high = low + 10;

    final count = tickCount.clamp(3, 8);
    final step  = ((high - low) / (count - 1)).round();
    final ticks = List<int>.generate(count, (i) => low + step * i);

    return (min: low.toDouble(), max: (low + step * (count - 1)).toDouble(), ticks: ticks);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;

    const double paddingLeft   = 44;
    const double paddingRight  = 16;
    const double paddingTop    = 8;
    const double paddingBottom = 26;

    final chartArea = Rect.fromLTWH(
      paddingLeft,
      paddingTop,
      size.width  - paddingLeft  - paddingRight,
      size.height - paddingTop   - paddingBottom,
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

      canvas.drawLine(Offset(chartArea.left, y), Offset(chartArea.right, y), gridPaint);

      final leftLabel = TextPainter(
        text: TextSpan(text: '$tick', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      leftLabel.paint(canvas, Offset(chartArea.left - 4 - leftLabel.width, y - leftLabel.height / 2));
    }

    // X-axis baseline
    canvas.drawLine(
      Offset(chartArea.left,  chartArea.bottom),
      Offset(chartArea.right, chartArea.bottom),
      Paint()
        ..color = AppColors.strokeSoft
        ..strokeWidth = 2,
    );
    _drawText(canvas, Offset(chartArea.left,  chartArea.bottom + 14), startLabel,
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
      final p0  = points[i];
      final p1  = points[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);

      final avgBpm = ((series[i] + series[i + 1]) / 2).round();
      curvePaint.color = _zoneColor(avgBpm);

      canvas.drawPath(
        Path()
          ..moveTo(p0.dx, p0.dy)
          ..quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy)
          ..quadraticBezierTo(p1.dx, p1.dy, p1.dx, p1.dy),
        curvePaint,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    Offset position,
    String text, {
    TextAlign align = TextAlign.left,
    double fontSize = 12,
    Color color = Colors.white,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout();
    final adjustedPosition = align == TextAlign.right
        ? position - Offset(painter.width, 0)
        : position;
    painter.paint(canvas, adjustedPosition);
  }

  @override
  bool shouldRepaint(covariant _HrCurvePainter old) {
    return series           != old.series           ||
           theoreticalMaxHr != old.theoreticalMaxHr ||
           yAxisMax         != old.yAxisMax         ||
           tickCount        != old.tickCount        ||
           startLabel       != old.startLabel       ||
           endLabel         != old.endLabel;
  }
}
