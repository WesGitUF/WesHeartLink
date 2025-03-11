import 'package:flutter/material.dart';

class MaxHRInputScreen extends StatefulWidget {
  const MaxHRInputScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MaxHRInputScreenState createState() => _MaxHRInputScreenState();
}

class _MaxHRInputScreenState extends State<MaxHRInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _maxHRController = TextEditingController();

  // Declare variables to hold device IDs passed from SensorSelectionScreen.
  String? userDeviceId;
  String? partnerDeviceId;

  @override
  void initState() {
    super.initState();
    // Retrieve the sensor selection arguments.
    Future.delayed(Duration.zero, () {
      final args = ModalRoute.of(context)!.settings.arguments as Map?;
      if (args != null) {
        userDeviceId = args['userDeviceId'] as String?;
        partnerDeviceId = args['partnerDeviceId'] as String?;
      }
      // For debugging, print the received arguments:
      print("MaxHRInputScreen received: userDeviceId = $userDeviceId, partnerDeviceId = $partnerDeviceId");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Your Max Heart Rate')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _maxHRController,
                style: const TextStyle(fontSize: 24, color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'Enter Your Estimated Max Heart Rate',
                  labelStyle: TextStyle(fontSize: 24),
                  hintText: 'Enter your max HR',
                  hintStyle: TextStyle(fontSize: 24),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a value';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    final maxHR = int.parse(_maxHRController.text);
                    // Pass all required arguments to TrackingScreen.
                    Navigator.pushNamed(
                      context,
                      '/tracking',
                      arguments: {
                        'userDeviceId': userDeviceId,
                        'partnerDeviceId': partnerDeviceId,
                        'maxHR': maxHR,
                      },
                    );
                  }
                },
                style: ElevatedButton.styleFrom(),
                child: const Text(
                  'Start Tracking',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
