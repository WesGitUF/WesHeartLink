import 'package:flutter/material.dart';
//import 'zone_dial.dart';
import 'package:heart_link_app/screens/heartratedial/zone_dial.dart';


class HeartrateScreen extends StatefulWidget {
  const HeartrateScreen({super.key});

  @override
  State<HeartrateScreen> createState() => _HeartrateScreenState();
}

class _HeartrateScreenState extends State<HeartrateScreen> {
  int bpm = 120;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Heart Rate'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ZoneDial(bpm: bpm, maxHr: 200),
            const SizedBox(height: 40),
            Slider(
              min: 40,
              max: 200,
              value: bpm.toDouble(),
              onChanged: (v) => setState(() => bpm = v.toInt()),
              activeColor: Colors.redAccent,
              thumbColor: Colors.white,
            ),
            Text(
              'Adjust BPM: $bpm',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
