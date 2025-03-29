import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Device Role')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Are you the primary device or the secondary device?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // If Primary, go to SensorSelectionScreen
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/sensorSelection', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                  textStyle: const TextStyle(fontSize: 24),
                ),
                child: const Text('Primary'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // If Secondary navigate to a screen for connecting to the primary phone
                  Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/tracking',
                      (route) => false,
                      arguments: {
                        'role': 'secondary',  
                      },
                    );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                  textStyle: const TextStyle(fontSize: 24),
                ),
                child: const Text('Secondary'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
