import 'dart:math';
import 'package:flutter/material.dart';

class ZoneDial extends StatelessWidget {
  final int bpm;
  final int maxHr;

  const ZoneDial({
    super.key,
    required this.bpm,
    required this.maxHr,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialHeight = screenWidth * 0.85;

    final minBpm = 40;
    final clampedBpm = bpm.clamp(minBpm, maxHr);
    final zoneInfo = _zoneForBpm(clampedBpm, maxHr);
    final zone = zoneInfo['zone'] as _Zone;
    final zonePct = zoneInfo['zonePct'] as int;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: dialHeight,
          width: screenWidth,
          child: TweenAnimationBuilder<int>(
            tween: IntTween(begin: clampedBpm, end: clampedBpm),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, animBpm, __) {
              final animZoneInfo = _zoneForBpm(animBpm, maxHr);
              final animZone = animZoneInfo['zone'] as _Zone;
              final animZonePct = animZoneInfo['zonePct'] as int;
              final pct = (animBpm - minBpm) / (maxHr - minBpm);

              return CustomPaint(
                painter: _DialPainter(pct, animZone.emoji, minBpm, maxHr),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 115), // ⬇ moved BPM lower from emoji
                    Text(
                      '${animBpm.toString()} BPM',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$animZonePct%',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
        _ZoneChip(zone: zone),
      ],
    );
  }

  Map<String, dynamic> _zoneForBpm(int bpm, int maxHr) {
    final zone1 = (maxHr * 0.60).round();
    final zone2 = (maxHr * 0.70).round();
    final zone3 = (maxHr * 0.80).round();
    final zone4 = (maxHr * 0.90).round();

    _Zone zone;
    int zoneStart, zoneEnd;

    if (bpm < zone1) {
      zone = _Zone('Grey', 'Light and easy', '😊', Colors.grey.shade400);
      zoneStart = 40;
      zoneEnd = zone1;
    } else if (bpm < zone2) {
      zone = _Zone('Blue', 'Endurance pace', '😐', const Color(0xFF3B82F6));
      zoneStart = zone1;
      zoneEnd = zone2;
    } else if (bpm < zone3) {
      zone = _Zone('Green', 'Moderate', '😩', const Color(0xFF10B981));
      zoneStart = zone2;
      zoneEnd = zone3;
    } else if (bpm < zone4) {
      zone = _Zone('Yellow', 'Challenging', '🥵', const Color(0xFFF59E0B));
      zoneStart = zone3;
      zoneEnd = zone4;
    } else {
      zone = _Zone('Red', 'Max effort', '🤮', const Color(0xFFEF4444));
      zoneStart = zone4;
      zoneEnd = maxHr;
    }

    final zoneRange = zoneEnd - zoneStart;
    final progressInZone = (bpm - zoneStart) / zoneRange;
    final zonePct = (progressInZone * 100).clamp(0, 100).round();

    return {'zone': zone, 'zonePct': zonePct};
  }
}

class _Zone {
  final String name;
  final String label;
  final String emoji;
  final Color color;
  const _Zone(this.name, this.label, this.emoji, this.color);
}

class _ZoneChip extends StatelessWidget {
  final _Zone zone;
  const _ZoneChip({required this.zone});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: zone.color.withOpacity(.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: zone.color.withOpacity(.5), width: 1.2),
      ),
      child: Text(
        '${zone.emoji}  ${zone.name} • ${zone.label}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double pct;
  final String emoji;
  final int minBpm;
  final int maxHr;
  _DialPainter(this.pct, this.emoji, this.minBpm, this.maxHr);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final center = Offset(w / 2, h * 0.46);
    final radius = min(w, h) * 0.9;
    const strokeThickness = 50.0;

    final startAngle = pi + (pi / 10);
    final sweep = 11 * pi / 10;

    final zone1 = (maxHr * 0.60 - minBpm) / (maxHr - minBpm);
    final zone2 = (maxHr * 0.70 - minBpm) / (maxHr - minBpm);
    final zone3 = (maxHr * 0.80 - minBpm) / (maxHr - minBpm);
    final zone4 = (maxHr * 0.90 - minBpm) / (maxHr - minBpm);

    final zoneCuts = [0.0, zone1, zone2, zone3, zone4, 1.0];
    final colors = [
      Colors.grey.shade700,
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];

    final rect = Rect.fromCircle(center: center, radius: radius / 2);

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeThickness
      ..color = Colors.white10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweep, false, bg);

    for (int i = 0; i < 5; i++) {
      final segStart = startAngle + sweep * zoneCuts[i];
      final segSweep = sweep * (zoneCuts[i + 1] - zoneCuts[i]);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeThickness
        ..strokeCap = StrokeCap.butt
        ..color = colors[i].withOpacity(0.9);
      canvas.drawArc(rect, segStart, segSweep, false, paint);
    }

    // Draw needle
    final needleAngle = startAngle + sweep * pct;
    final needleLen = radius / 2 + 45;
    final needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final needleEnd =
        center + Offset(cos(needleAngle), sin(needleAngle)) * needleLen;
    canvas.drawLine(center, needleEnd, needlePaint);

    // Emoji now drawn at the NEEDLE BASE (center)
    final emojiPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: const TextStyle(fontSize: 30),
      ),
      textDirection: TextDirection.ltr,
    );
    emojiPainter.layout();
    emojiPainter.paint(
      canvas,
      center - Offset(emojiPainter.width / 2, emojiPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) =>
      oldDelegate.pct != pct || oldDelegate.emoji != emoji;
}
