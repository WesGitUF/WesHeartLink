import 'package:flutter/material.dart';
import 'package:heart_link_app/services/workout_service.dart';
import 'package:heart_link_app/shell/app_shell.dart';

class TrackingResultScreen extends StatelessWidget {
  final Duration elapsedTime;
  final Duration sameZoneTime;
  final String workoutMode;
  final IconData workoutModeIcon;
  final int maxHeartRate;
  final double avgHeartRate;
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
    required this.series,
    required this.topZone,
    required this.isSolo,
    required this.theoreticalMaxHr,
    });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60), // height of your appbar
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: AppBar(
            backgroundColor: Colors.redAccent,
            centerTitle: true,
            title: Image.asset(
              'assets/images/logo.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
             Align(
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text('Great Job!', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  Text('Workout Statistics:', style: TextStyle(fontSize: 36), textAlign: TextAlign.center),
                ],
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 80),
                child: _StatsBox(
                  elapsedTime: elapsedTime, 
                  sameZoneTime: sameZoneTime, 
                  workoutMode: workoutMode, 
                  workoutModeIcon: workoutModeIcon,
                  maxHeartRate: maxHeartRate,
                  avgHeartRate: avgHeartRate,
                  series: series,
                  topZone: topZone,
                  isSolo: isSolo,
                    theoreticalMaxHr: theoreticalMaxHr),
              ),
            ),
          ],
        ),
      )
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.redAccent, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.workoutModeIcon, size: 50),
          Text('Workout Type: ${widget.workoutMode}', style: const TextStyle(fontSize: 24), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Text('Elapsed Time: ${_formatDuration(widget.elapsedTime)}', style: const TextStyle(fontSize: 24), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          if (!widget.isSolo) ...[
            Text('Time in Same Zone: ${_formatDuration(widget.sameZoneTime)}', style: const TextStyle(fontSize: 24), textAlign: TextAlign.center),
            const SizedBox(height: 24),
          ],
          Text('Max Heart Rate: ${widget.maxHeartRate}', style: const TextStyle(fontSize: 24), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Text('Average Heart Rate: ${widget.avgHeartRate.round()}', style: const TextStyle(fontSize: 24), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Text('Peak Heart Rate Zone: ${widget.topZone}', style: const TextStyle(fontSize: 24), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _pressed ? null : () {
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
                MaterialPageRoute(builder: (context) => const AppShell()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              textStyle: const TextStyle(fontSize: 24),
            ),
            child: const Text('Return Home', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
