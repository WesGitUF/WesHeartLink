import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:heart_link_app/screens/history/history_screen.dart' show Workout;
import 'package:heart_link_app/screens/heartratedial/hr.state.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final Workout workout;

  // heart rate series for the session
  final List<int> series;
  const WorkoutDetailScreen({
    super.key,
    required this.workout,
    required this.series,
  });

  // format duration 
  String _fmtDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(d.inHours);
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return '$h:$m:$s';
  }

  String _displayName(User? u) {
    if (u == null) return 'User';
    if ((u.displayName ?? '').isNotEmpty) return u.displayName!;
    final email = u.email;
    if (email != null && email.isNotEmpty) return email.split('@').first;
    return 'User';
  }

  String _hhmm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _timeRange(DateTime start, DateTime end) {
    String two(int n) => n.toString().padLeft(2, '0');
    final y = start.year, m = start.month, d = start.day;
    final sh = two(start.hour), sm = two(start.minute);
    final eh = two(end.hour), em = two(end.minute);
    return '$y/${two(m)}/${two(d)} $sh:$sm – $eh:$em';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    final start = workout.start;
    final end = start.add(workout.duration);

    print(series);

    // session max heart rate
    final int sessionMax = series.isEmpty
        ? workout.avgHr
        : series.reduce((a, b) => a > b ? a : b);

    // max heart rate from hrState
    final int theoreticalMaxHr = hrState.maxHr; 

    return Scaffold(
      appBar: AppBar(title: Text(workout.type)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // user info
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF424242),
                backgroundImage: (user?.photoURL?.isNotEmpty == true)
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: (user?.photoURL?.isNotEmpty == true)
                    ? null
                    : const Icon(Icons.person, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_displayName(user),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(_timeRange(start, end),
                        style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // avg heart rate display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Icon(Icons.favorite, size: 22, color: Color(0xFFE53935)),
                    SizedBox(width: 8),
                    Text('Average Heart Rate',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${workout.avgHr}',
                      style: const TextStyle(
                        fontSize: 70,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text('bpm',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // heart rate trend curve
          if (series.isNotEmpty) ...[
            const Text('Heart Rate Trend',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            SizedBox(
              height: 260,
              child: _HrCurve(
                series: series,
                theoreticalMaxHr: theoreticalMaxHr,
                yAxisMaxForRange: sessionMax,
                leftLegendCount: 4,
                // time duration
                startLabel: '0:00',
                endLabel: _fmtDuration(workout.duration),

              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: const [
                _ZoneDot(color: Color(0xFF666A70), label: '40–65%'),
                _ZoneDot(color: Color(0xFF2F6BDA), label: '66–80%'),
                _ZoneDot(color: Color(0xFF66B35B), label: '81–89%'),
                _ZoneDot(color: Color(0xFFF3A43B), label: '90–95%'),
                _ZoneDot(color: Color(0xFFE25353), label: '95–100%'),
              ],
            ),
            const SizedBox(height: 25),
          ],

          // Workout Data
          const Text('Workout Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _miniStat('Duration', _fmtDuration(workout.duration)),
                _miniStat('Calories', '${workout.calories} kcal'),
                _miniStat('Max HR', '$sessionMax bpm'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String title, String value) {
    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

// zone dot 
class _ZoneDot extends StatelessWidget {
  final Color color;
  final String label;
  const _ZoneDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: Colors.white70)),
    ]);
  }
}

// curve painter
class _HrCurve extends StatelessWidget {
  final List<int> series;

  // max heart rate for color zone calculation
  final int theoreticalMaxHr;
  final int yAxisMaxForRange;
  final int leftLegendCount;
  final String startLabel;
  final String endLabel;

  const _HrCurve({
    super.key,
    required this.series,
    required this.theoreticalMaxHr,
    required this.yAxisMaxForRange,
    this.leftLegendCount = 6,
    required this.startLabel,
    required this.endLabel,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HrCurvePainter(
        series: series,
        theoreticalMaxHr: theoreticalMaxHr,
        yAxisMaxForRange: yAxisMaxForRange,
        tickCount: leftLegendCount,
        startLabel: startLabel,
        endLabel: endLabel,
      ),
      size: Size.infinite,
    );
  }
}

class _HrCurvePainter extends CustomPainter {
  final List<int> series;
  final int theoreticalMaxHr;
  final int yAxisMaxForRange;
  final int tickCount;
  final String startLabel;
  final String endLabel;

  _HrCurvePainter({
    required this.series,
    required this.theoreticalMaxHr,
    required this.yAxisMaxForRange,
    required this.tickCount,
    required this.startLabel,
    required this.endLabel,
  });

  // zone colors
  static const _grey   = Color(0xFF666A70); 
  static const _blue   = Color(0xFF2F6BDA); 
  static const _green  = Color(0xFF66B35B); 
  static const _yellow = Color(0xFFF3A43B); 
  static const _red    = Color(0xFFE25353); 

  Color _zoneColorByTheoryMax(int bpm) {
    if (theoreticalMaxHr <= 0) return _grey;
    final p = bpm / theoreticalMaxHr;
    if (p < 0.60) return _grey;
    if (p < 0.70) return _blue;
    if (p < 0.80) return _green;
    if (p < 0.90) return _yellow;
    return _red;
  }

  ({double min, double max, List<int> ticks}) _makeNiceAxis() {
    int lo = series.reduce((a, b) => a < b ? a : b);
    int hi = series.reduce((a, b) => a > b ? a : b);

    hi = (hi > yAxisMaxForRange) ? hi : yAxisMaxForRange;

    if (lo == hi) {
      lo -= 5;
      hi += 5;
    }
    lo -= ((hi - lo) * 0.08).round();
    hi += ((hi - lo) * 0.08).round();
    lo = (lo / 10).floor() * 10;
    hi = (hi / 10).ceil() * 10;
    if (lo < 40) lo = 40;
    if (hi <= lo) hi = lo + 10;

    final n = tickCount.clamp(3, 8);
    final step = ((hi - lo) / (n - 1)).round();
    final ticks = List<int>.generate(n, (i) => lo + step * i);

    return (min: lo.toDouble(), max: (lo + step * (n - 1)).toDouble(), ticks: ticks);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;

    const padL = 44.0, padR = 44.0, padT = 8.0, padB = 26.0;
    final chart = Rect.fromLTWH(
      padL,
      padT,
      size.width - padL - padR,
      size.height - padT - padB,
    );

    final axis = _makeNiceAxis();
    final yMin = axis.min, yMax = axis.max;

    double xAt(int i) {
      if (series.length == 1) return chart.left + chart.width / 2;
      return chart.left + chart.width * (i / (series.length - 1));
    }

    double yAt(double v) {
      final t = ((v - yMin) / (yMax - yMin)).clamp(0.0, 1.0);
      return chart.bottom - chart.height * t;
    }

    // y axis grid + labels
    final grid = Paint()
      ..color = const Color.fromARGB(45, 255, 255, 255)
      ..strokeWidth = 1;

    for (final t in axis.ticks) {
      final yy = yAt(t.toDouble());
      canvas.drawLine(Offset(chart.left, yy), Offset(chart.right, yy), grid);

      final tpR = TextPainter(
        text: const TextSpan(style: TextStyle(fontSize: 11, color: Colors.white70)),
        textDirection: TextDirection.ltr,
      );
      tpR.text = TextSpan(text: '$t', style: const TextStyle(fontSize: 11, color: Colors.white70));
      tpR.layout();
      tpR.paint(canvas, Offset(chart.right + 4, yy - tpR.height / 2));

      final tpL = TextPainter(
        text: TextSpan(text: '$t', style: const TextStyle(fontSize: 11, color: Colors.white70)),
        textDirection: TextDirection.ltr,
      )..layout();
      tpL.paint(canvas, Offset(chart.left - 4 - tpL.width, yy - tpL.height / 2));
    }

    // x axis
    canvas.drawLine(
      Offset(chart.left, chart.bottom),
      Offset(chart.right, chart.bottom),
      Paint()..color = Colors.black26..strokeWidth = 2,
    );
    _text(canvas, Offset(chart.left, chart.bottom + 14), startLabel,
        size: 11, color: Colors.white70);
    _text(canvas, Offset(chart.right, chart.bottom + 14), endLabel,
        size: 11, color: Colors.white70, align: TextAlign.right);

    // plot curve
    final pts = <Offset>[];
    for (int i = 0; i < series.length; i++) {
      pts.add(Offset(xAt(i), yAt(series[i].toDouble())));
    }

    // draw segments
    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = pts[i];
      final p1 = pts[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      final segHr = ((series[i] + series[i + 1]) / 2).round();
      final segColor = _zoneColorByTheoryMax(segHr);

      final path = Path()
        ..moveTo(p0.dx, p0.dy)
        ..quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy)
        ..quadraticBezierTo(p1.dx, p1.dy, p1.dx, p1.dy);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = segColor;

      canvas.drawPath(path, paint);
    }
  }

  void _text(Canvas canvas, Offset pos, String text,
      {TextAlign align = TextAlign.left, double size = 12, Color color = Colors.white}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size)),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout();
    var p = pos;
    if (align == TextAlign.right) p = p - Offset(tp.width, 0);
    tp.paint(canvas, p);
  }

  @override
  bool shouldRepaint(covariant _HrCurvePainter old) {
    return series != old.series ||
        theoreticalMaxHr != old.theoreticalMaxHr ||
        yAxisMaxForRange != old.yAxisMaxForRange ||
        tickCount != old.tickCount ||
        startLabel != old.startLabel ||
        endLabel != old.endLabel;
  }
}