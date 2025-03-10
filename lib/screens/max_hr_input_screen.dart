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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Max Heart Rate')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _maxHRController,
                decoration: const InputDecoration(
                  labelText: 'Max Heart Rate',
                  hintText: 'Enter your max HR',
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
                    // Pass maxHR (and any other necessary arguments) to TrackingScreen.
                    Navigator.pushNamed(
                      context,
                      '/tracking',
                      arguments: {'maxHR': maxHR},
                    );
                  }
                },
                child: const Text('Start Tracking'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
