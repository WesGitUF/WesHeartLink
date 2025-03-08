import 'package:flutter/material.dart';

// PulseHeart Widget 
class PulseHeart extends StatefulWidget {
  final double size;
  final Color color;
  const PulseHeart({Key? key, required this.size, required this.color}) : super(key: key);
  
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

//HeartRateMeter Widget 
class HeartRateMeter extends StatelessWidget {
  final int heartRate; 
  final double barHeight;
  final double barWidth;
  
  const HeartRateMeter({
    Key? key,
    required this.heartRate,
    this.barHeight = 200,
    this.barWidth = 50,
  }) : super(key: key);
  
  // Returns the fill color based on the heart rate.
  Color _getFillColor() {
    if (heartRate <= 120) return Colors.blue;
    if (heartRate <= 140) return Colors.green;
    if (heartRate <= 160) return Colors.yellow;
    if (heartRate <= 180) return Colors.orange;
    return Colors.red;
  }
  
  @override
  Widget build(BuildContext context) {
    // Calculate fill height as a proportion of the bar.
    double fillHeight = (heartRate.clamp(0, 200) / 200) * barHeight;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // The meter bar with an animated fill.
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
        // Column with zone labels.
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Zone 1: 0-120', style: TextStyle(fontSize: 12, color: Colors.blue)),
            Text('Zone 2: 121-140', style: TextStyle(fontSize: 12, color: Colors.green)),
            Text('Zone 3: 141-160', style: TextStyle(fontSize: 12, color: Colors.yellow[700])),
            Text('Zone 4: 161-180', style: TextStyle(fontSize: 12, color: Colors.orange)),
            Text('Zone 5: 181-200', style: const TextStyle(fontSize: 12, color: Colors.red)),
          ],
        ),
      ],
    );
  }
}
