import 'dart:math' as math;
import 'package:flutter/material.dart';

// heart rate zone segment for dial (visual 0..1)
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


class _SemiDialState extends State<SemiDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _beat;
  late Animation<double> _scale;

  // Physical zone breakpoints (40–65–80–89–95–100%)
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

  // full-color band color by index
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

  /// Map real % (0.40–1.0) into visual 0–1 along the dial
  double _toVisual(double physFraction) {
    const double pMin = 0.40;
    const double range = 1.0 - pMin;
    final double v = (physFraction - pMin) / range;
    return v.clamp(0.0, 1.0);
  }

  /// Same zone segmentation as Tongshan, but used for Maria-style arcs
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
    _beat = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _beat.repeat(reverse: true);

    final Tween<double> scaleTween = Tween<double>(
      begin: 0.95,
      end: 1.10,
    );

    final CurveTween curveTween = CurveTween(
      curve: Curves.easeInOut,
    );

    final Animatable<double> combinedTween = scaleTween.chain(curveTween);
    _scale = combinedTween.animate(_beat);
  }

  @override
  void didUpdateWidget(covariant SemiDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    // keep same 40% baseline animation logic
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

  // Accurate percentage → zone index
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
        // slightly smaller dial so it doesn’t overflow
        final size = math.min(c.maxWidth, c.maxHeight) * 0.95;

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
                // move content up a bit like your original design
                padding: EdgeInsets.only(top: size * 0.08),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // heart-beat scaling emoji
                    ScaleTransition(
                      scale: _scale,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: Text(
                          face.emoji,
                          key: ValueKey(zoneIndex),
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
                    SizedBox(height: size * 0.03),
                    Text(
                      '${widget.bpm} BPM',
                      style: TextStyle(
                        fontSize: size * 0.13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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

// Maria-style painter but using Tongshan’s mapping + zones
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
    final double w = size.width;
    final double h = size.height;

    // Center + radius close to your original dial
    final center = Offset(w / 2, h * 0.52);
    final radius = math.min(w, h) * 0.95;

    // Slightly more than a half-circle, like your first design
    const startAngle = math.pi + (math.pi / 10);      // ~198°
    const sweepTotal = 11 * math.pi / 10;             // ~198°

    final Rect arcRect =
        Rect.fromCircle(center: center, radius: radius / 2);

    // Background arc (thin grey outline behind colors)
    final Paint bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackWidth
      ..color = Colors.white10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, startAngle, sweepTotal, false, bg);

    // Colored zone bands (grey → blue → green → yellow → red)
    final Paint zonePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackWidth
      ..strokeCap = StrokeCap.butt;

    for (final z in zones) {
      final double s = startAngle + sweepTotal * z.start;
      final double sw = sweepTotal * (z.end - z.start);
      if (sw <= 0) continue;
      zonePaint.color = z.color;
      canvas.drawArc(arcRect, s, sw, false, zonePaint);
    }

    // Simple white needle (like your original)
    final double needleAngle = startAngle + sweepTotal * visualPct;
    final double needleLen = radius / 2 + 40;

    final Paint needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final Offset needleEnd = center +
        Offset(math.cos(needleAngle), math.sin(needleAngle)) * needleLen;

    canvas.drawLine(center, needleEnd, needlePaint);
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

