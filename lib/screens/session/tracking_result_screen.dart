import 'package:flutter/material.dart';

class TrackingResultScreen extends StatelessWidget {
  final Duration elapsedTime;
  const TrackingResultScreen({super.key, required this.elapsedTime});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tracking Result')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Elapsed Time: ${_formatDuration(elapsedTime)}',
              style: const TextStyle(fontSize: 32),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24), 
            ElevatedButton(
              onPressed: () {
                // Navigate to HomeScreen and clear the navigation stack.
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                textStyle: const TextStyle(fontSize: 24),
              ),
              child: const Text("Return Home"),
            ),
          ],
        ),
      ),

    );
  }
}
