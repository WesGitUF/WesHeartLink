import 'package:flutter/material.dart';

class TrackingResultScreen extends StatelessWidget {
  final Duration elapsedTime;
  final Duration sameZoneTime;
  final double avgHR;
  final double avgUserHR;
  final double avgPartnerHR;

  const TrackingResultScreen({super.key, required this.elapsedTime, required this.sameZoneTime, required this.avgUserHR, required this.avgPartnerHR, required this.avgHR});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 400.0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Result'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: DataTable(
                columnSpacing: 20,
                columns: [
                  DataColumn(
                      label: Text(
                    "Metric",
                    style: TextStyle(
                        fontSize: 18 * scale, fontWeight: FontWeight.bold),
                  )),
                  DataColumn(
                      label: Text(
                    "Value",
                    style: TextStyle(
                        fontSize: 18 * scale, fontWeight: FontWeight.bold),
                  )),
                ],
                rows: [
                  DataRow(cells: [
                    DataCell(Text("Elapsed Time",
                        style: TextStyle(fontSize: 16 * scale))),
                    DataCell(Text(_formatDuration(elapsedTime),
                        style: TextStyle(fontSize: 16 * scale))),
                  ]),
                  DataRow(cells: [
                    DataCell(Text("Time in Same Zone",
                        style: TextStyle(fontSize: 16 * scale))),
                    DataCell(Text(_formatDuration(sameZoneTime),
                        style: TextStyle(fontSize: 16 * scale))),
                  ]),
                  DataRow(cells: [
                    DataCell(Text("Primary User's Avg HR",
                        style: TextStyle(fontSize: 16 * scale))),
                    DataCell(Text("${avgUserHR.toStringAsFixed(1)} bpm",
                        style: TextStyle(fontSize: 16 * scale))),
                  ]),
                  DataRow(cells: [
                    DataCell(Text("Secondary User's Avg HR",
                        style: TextStyle(fontSize: 16 * scale))),
                    DataCell(Text("${avgPartnerHR.toStringAsFixed(1)} bpm",
                        style: TextStyle(fontSize: 16 * scale))),
                  ]),
                
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (Route<dynamic> route) => false,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
            textStyle: TextStyle(fontSize: 24 * scale),
          ),
          child: const Text("Return Home"),
        ),
      ),
    );
  }
}
