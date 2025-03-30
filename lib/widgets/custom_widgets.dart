import 'package:flutter/material.dart';

// PulseHeart Widget
class PulseHeart extends StatefulWidget {
  final double size;
  final Color color;
  const PulseHeart({super.key, required this.size, required this.color});

  @override
  _PulseHeartState createState() => _PulseHeartState();
}

class _PulseHeartState extends State<PulseHeart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Icon(
        Icons.favorite,
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}

// HeartRateMeter Widget with dynamic zones based on max HR
class HeartRateMeter extends StatelessWidget {
  final int heartRate;
  final double barHeight;
  final double barWidth;
  final int maxHeartRate; // Used to calculate zones as percentages
  final double textScale;

  const HeartRateMeter({
    super.key,
    required this.heartRate,
    required this.maxHeartRate,
    this.barHeight = 300,
    this.barWidth = 50,
    this.textScale = 1.0,
  });

  // Returns the fill color based on the heart rate percentage.
  Color _getFillColor() {
    double percentage = (heartRate / maxHeartRate) * 100;
    if (percentage <= 60) return Colors.blue;   // Zone 1 (0-60%)
    if (percentage <= 70) return Colors.green;  // Zone 2 (61-70%)
    if (percentage <= 80) return Colors.yellow; // Zone 3 (71-80%)
    if (percentage <= 90) return Colors.orange; // Zone 4 (81-90%)
    return Colors.red;                          // Zone 5 (91-100%)
  }

  @override
  Widget build(BuildContext context) {
    double fillHeight = (heartRate.clamp(0, maxHeartRate) / maxHeartRate) * barHeight;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: barHeight,
              width: barWidth,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                color: Colors.grey[300],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: fillHeight,
              width: barWidth,
              color: _getFillColor(),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Zone 1: 0-60% Max HR', style: TextStyle(fontSize: 15 * textScale, color: Colors.blue, fontWeight: FontWeight.bold,)),
            Text('Zone 2: 61-70% Max HR', style: TextStyle(fontSize: 15 * textScale, color: Colors.green, fontWeight: FontWeight.bold,)),
            Text('Zone 3: 71-80% Max HR', style: TextStyle(fontSize: 15 * textScale, color: Colors.yellow[700], fontWeight: FontWeight.bold,)),
            Text('Zone 4: 81-90% Max HR', style: TextStyle(fontSize: 15 * textScale, color: Colors.orange, fontWeight: FontWeight.bold,)),
            Text('Zone 5: 91-100% Max HR', style: TextStyle(fontSize: 15 * textScale, color: Colors.red, fontWeight: FontWeight.bold,)),
          ],
        ),
      ],
    );
  }
}
