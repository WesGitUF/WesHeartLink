import 'dart:math' as math;
import 'package:flutter/material.dart';

// heart rate zone segment for dial
class HrZone {
  final double start; // 0..1 on the dial
  final double end;   // 0..1 on the dial
  final Color color;
  HrZone(this.start, this.end, this.color);
}

class SemiDial extends StatefulWidget {
  final int bpm;
  final int maxHr;
  final double trackWidth;
  final double progressWidth;
  final int tickCount;

  const SemiDial({
    super.key,
    required this.bpm,
    required this.maxHr,
    this.trackWidth = 56,
    this.progressWidth = 60,
    this.tickCount = 0,
  });

  @override
  State<SemiDial> createState() => _SemiDialState();
}

// handle animation and mapping to zones
class _SemiDialState extends State<SemiDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _beat;
  late Animation<double> _scale;

  final List<double> _physStops = [0.40, 0.65, 0.80, 0.89, 0.95, 1.00];

  // face by zone index
  ({String emoji, double scale}) _emojiForZone(int idx) {
    switch (idx) {
      case 0:
        return (emoji: '😊', scale: 1.4);
      case 1:
        return (emoji: '😐', scale: 1.4);
      case 2:
        return (emoji: '😫', scale: 1.4);
      case 3:
        return (emoji: '🥵', scale: 1.4);
      default:
        return (emoji: '🤮', scale: 1.4);
    }
  }

  // active color by zone index
  Color _activeColorFor(int zoneIndex) {
    switch (zoneIndex) {
      case 0:
        return const Color(0xFF666A70);
      case 1:
        return const Color(0xFF2F6BDA);
      case 2:
        return const Color(0xFF66B35B);
      case 3:
        return const Color(0xFFF3A43B);
      default:
        return const Color(0xFFE25353);
    }
  }

  // color by index
  Color _zoneColorByIndex(int i) {
    switch (i) {
      case 0:
        return const Color(0xFF666A70); // 40–65%
      case 1:
        return const Color(0xFF2F6BDA); // 65–80%
      case 2:
        return const Color(0xFF66B35B); // 80–89%
      case 3:
        return const Color(0xFFF3A43B); // 89–95%
      default:
        return const Color(0xFFE25353); // 95–100%
    }
  }

  double _toVisual(double physFraction) {
    const double pMin = 0.40; 
    const double range = 1.0 - pMin; 
    final double v = (physFraction - pMin) / range;
    return v.clamp(0.0, 1.0);
  }

  List<HrZone> get _zonesVisual {
    final List<HrZone> out = [];
    for (int i = 0; i < _physStops.length - 1; i++) {
      final double physStart = _physStops[i];
      final double physEnd = _physStops[i + 1];

      final double visStart = _toVisual(physStart);
      final double visEnd = _toVisual(physEnd);

      out.add(HrZone(visStart, visEnd, _zoneColorByIndex(i)));
    }
    return out;
  }

  @override
  void initState() {
    super.initState();
    // 1. create AnimationController
    _beat = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    // 2. repeat the animation
    _beat.repeat(reverse: true);
    // 3. create a Tween：0.95 → 1.10
    final Tween<double> scaleTween = Tween<double>(
      begin: 0.95,
      end: 1.10,
    );
    // 4.create a CurveTween
    final CurveTween curveTween = CurveTween(
      curve: Curves.easeInOut,
    );
    // 5. chain the two curve
    final Animatable<double> combinedTween = scaleTween.chain(curveTween);
    _scale = combinedTween.animate(_beat);
  }

  @override
  void didUpdateWidget(covariant SemiDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    final minBpm = (widget.maxHr * 0.40).round();
    final bpm = widget.bpm.clamp(minBpm, widget.maxHr);
    final ms = (60000 / bpm).round();
    if (_beat.duration!.inMilliseconds != ms) {
      _beat.duration = Duration(milliseconds: ms);
      if (!_beat.isAnimating) _beat.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  // accurate percentage to zone index（用“真实百分比”判断区间）
  int _zoneIndexFromPhysPct(double p) {
    if (p < 0.65) return 0;
    if (p < 0.80) return 1;
    if (p < 0.89) return 2;
    if (p < 0.95) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final double physPct =
        (widget.maxHr > 0) ? (widget.bpm / widget.maxHr) : 0.0;
    final double physPctClamped = physPct.clamp(0.0, 1.0);
    final double visualPct = _toVisual(physPctClamped);
    final int zoneIndex = _zoneIndexFromPhysPct(physPctClamped);
    final Color active = _activeColorFor(zoneIndex);
    final face = _emojiForZone(zoneIndex);

    return LayoutBuilder(
      builder: (context, c) {
        final size = math.min(c.maxWidth, c.maxHeight);
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _SemiDialPainter(
              zones: _zonesVisual,
              visualPct: visualPct,
              physZoneIndex: zoneIndex,
              trackWidth: widget.trackWidth,
              progressWidth: widget.progressWidth,
              activeColor: active,
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(top: size * 0.06),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //heart-beat scaling emoji
                    ScaleTransition(
                      scale: _scale,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: Text(
                          face.emoji,
                          key: ValueKey(zoneIndex), // swap when zone changes
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: size * 0.16 * face.scale,
                            height: 1.0,
                            shadows: const [
                              Shadow(
                                blurRadius: 2,
                                color: Colors.black26,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          semanticsLabel: 'Effort emoji',
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '${widget.bpm} BPM',
                      style: TextStyle(
                        fontSize: size * 0.10,
                        fontWeight: FontWeight.w700,
                        color: const Color.fromARGB(255, 222, 216, 216),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// painter for the semi-dial
class _SemiDialPainter extends CustomPainter {
  final List<HrZone> zones;
  final double visualPct;
  final int physZoneIndex;
  final double trackWidth;
  final double progressWidth;
  final Color activeColor;

  _SemiDialPainter({
    required this.zones,
    required this.visualPct,
    required this.physZoneIndex,
    required this.trackWidth,
    required this.progressWidth,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.67);
    final radius = size.width * 0.40;
    const startAngle = math.pi; // left
    const sweepTotal = math.pi; // half circle

    final arcRect = Rect.fromCircle(center: center, radius: radius);

    // Draw zone tracks
    final Paint trackPaint = Paint();
    trackPaint.style = PaintingStyle.stroke;
    trackPaint.strokeCap = StrokeCap.butt;
    trackPaint.strokeWidth = trackWidth;
    const double eps = 0.006;

    for (final z in zones) {
      double a0 = startAngle + sweepTotal * z.start - eps;
      double a1 = startAngle + sweepTotal * z.end + eps;
      final minA = startAngle, maxA = startAngle + sweepTotal;
      a0 = a0.clamp(minA, maxA);
      a1 = a1.clamp(minA, maxA);
      final sweep = (a1 - a0).clamp(0.0, sweepTotal);
      if (sweep <= 0) continue;
      trackPaint.color = z.color;
      canvas.drawArc(arcRect, a0, sweep, false, trackPaint);
    }

    // Draw progress arc in activeColor
    final Paint progressPaint = Paint();
    progressPaint.style = PaintingStyle.stroke;
    progressPaint.strokeCap = StrokeCap.butt;
    progressPaint.strokeWidth = progressWidth;
    progressPaint.color = activeColor;
    final progressSweep = sweepTotal * visualPct;
    if (progressSweep > 0) {
      canvas.drawArc(arcRect, startAngle, progressSweep, false, progressPaint);
    }

    // Draw Roman numerals for zones
    const romans = ['I', 'II', 'III', 'IV', 'V'];
    final labelRadius = radius;

    for (int i = 0; i < zones.length; i++) {
      final z = zones[i];
      // middle angle of this zone
      final mid = startAngle + sweepTotal * ((z.start + z.end) / 2);
      final pos = Offset(
        center.dx + labelRadius * math.cos(mid),
        center.dy + labelRadius * math.sin(mid),
      );
      final lum = z.color.computeLuminance();
      final textColor = lum > 0.6 ? Colors.black87 : Colors.white;

      final tp = TextPainter(
        text: TextSpan(
          text: romans[i],
          style: TextStyle(
            color: textColor,
            fontSize: trackWidth * 0.35,
            fontWeight: FontWeight.w700,
            shadows: const [Shadow(blurRadius: 2, color: Colors.black26)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    // Draw outer inverted triangle pointer
    final needleAngle = startAngle + sweepTotal * visualPct;
    final outerEdgeR = radius + trackWidth * 0.5;
    const gapOut = 5.0; // distance outside the arc
    final tipR = outerEdgeR + gapOut;

    const markerW = 20.0;
    const markerH = 16.0;

    final u = Offset(math.cos(needleAngle), math.sin(needleAngle)); // radial
    final v = Offset(-math.sin(needleAngle), math.cos(needleAngle)); // tangent

    final tip = Offset(center.dx + tipR * u.dx, center.dy + tipR * u.dy);
    final baseCenter = tip + u * markerH;

    final p1 = baseCenter + v * (markerW / 2);
    final p2 = baseCenter - v * (markerW / 2);

    final Paint outline = Paint();
    outline.style = PaintingStyle.stroke;
    outline.strokeWidth = 1.5;
    outline.color = Colors.black.withOpacity(0.20);

    final Paint fill = Paint();
    fill.style = PaintingStyle.fill;
    fill.color = activeColor;

    final Path tri = Path();
    tri.moveTo(tip.dx, tip.dy);
    tri.lineTo(p1.dx, p1.dy);
    tri.lineTo(p2.dx, p2.dy);
    tri.close();

    canvas.drawPath(tri, outline);
    canvas.drawPath(tri, fill);
  }

  @override
  bool shouldRepaint(covariant _SemiDialPainter old) {
    return visualPct != old.visualPct ||
        trackWidth != old.trackWidth ||
        progressWidth != old.progressWidth ||
        activeColor != old.activeColor ||
        zones != old.zones ||
        physZoneIndex != old.physZoneIndex;
  }
}