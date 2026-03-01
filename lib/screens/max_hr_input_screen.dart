import 'package:flutter/material.dart';

class MaxHRInputScreen extends StatefulWidget {
  final String workoutMode;

  const MaxHRInputScreen({
    Key? key,
    required this.workoutMode,
  }) : super(key: key);

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

  late String _workoutMode;
  IconData? _workoutModeIcon;

  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _workoutMode = widget.workoutMode;
    pickIcon();
    _maxHRController.addListener(() {
      setState(() {
        _hasText = _maxHRController.text.isNotEmpty;
      });
    });
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

  void pickIcon() {
    if (_workoutMode == "Running") { _workoutModeIcon = Icons.directions_run; }
    else if (_workoutMode == "Cycling") { _workoutModeIcon = Icons.directions_bike; }
    else if (_workoutMode == "HIIT") { _workoutModeIcon = Icons.fitness_center; }
    else if (_workoutMode == "Walking") { _workoutModeIcon = Icons.directions_walk; }
    else if (_workoutMode == "Swimming") { _workoutModeIcon = Icons.pool; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: AppBar(
            backgroundColor: Colors.redAccent,
            centerTitle: true,
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              }, 
              icon: const Icon(Icons.arrow_back),
            ),
            title: Image.asset(
              'assets/images/logo.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Icon(
                  _workoutModeIcon,
                  size: 50,
                  color: Colors.black
                ),
              ),
            ],
          ),
        ),
      ),
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
                  labelText: 'Enter Your Age',
                  labelStyle: TextStyle(fontSize: 24, color: Colors.black),
                  hintText: 'Age',
                  hintStyle: TextStyle(fontSize: 24),
                  border: const OutlineInputBorder(), 
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
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
                onChanged: (val) {
                  setState(() {
                    _hasText = val.isNotEmpty;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    final maxHR = (208 - (int.parse(_maxHRController.text) * 0.7)).toInt(); //formula based on age
                    // Pass all required arguments to TrackingScreen.
                    Navigator.pushNamed(
                      context,
                      '/radialGauge',
                      arguments: {
                        'userDeviceId': userDeviceId,
                        'partnerDeviceId': partnerDeviceId,
                        'maxHR': maxHR,
                        'workoutMode': _workoutMode,
                      },
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_hasText)
                      ? Colors.redAccent
                      : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  textStyle: const TextStyle(fontSize: 24),
                ),
                child: Text(
                  'Start Tracking',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: (_hasText)
                    ? Colors.white : Colors.black
                  ),
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}
