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
  final TextEditingController _partnerMaxHRController = TextEditingController(); 

  // Declare variables to hold device IDs passed from SensorSelectionScreen.
  String? userDeviceId;
  String? partnerDeviceId;

  @override
  void initState() {
    super.initState();
    _maxHRController.addListener(() {
    setState(() {});
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 400.0;
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Your Max Heart Rate'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, '/sensorSelection');
          }
        },
      ),),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Step 4 of 4",
                  style: TextStyle(
                    fontSize: 20 * scale, // Dynamically scales with screen width
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(width: 8 * scale),
                Tooltip(
                  message: "Estimate your max HR using the formula: Max HR = 208 - (0.7 * age).",
                  child: const Icon(
                    Icons.info_outline,
                    color: Color.fromARGB(255, 248, 0, 0), // set icon color as desired
                  ),
                ),
              ],
            ),
            SizedBox(height: 80 * scale),       
      Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _maxHRController,
                cursorColor: Colors.green,
                style: TextStyle(fontSize: 24* scale, color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Enter primary (host) Max HR',
                  labelStyle: TextStyle(fontSize: 24* scale),
                  floatingLabelStyle: const TextStyle(color: Colors.green),
                  hintText: 'Max HR = 208 - (0.7 * age)',
                  hintStyle: TextStyle(fontSize: 24* scale),
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green, width: 2.0),
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
              ),
              SizedBox(height: 20 * scale),
              TextFormField(
                controller: _partnerMaxHRController,
                cursorColor: Colors.green,
                style: TextStyle(fontSize: 24 * scale, color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Enter secondary (peer) Max HR',
                  labelStyle: TextStyle(fontSize: 24 * scale),
                  floatingLabelStyle: const TextStyle(color: Colors.green),
                  hintText: 'Max HR = 208 - (0.7 * age)',
                  hintStyle: TextStyle(fontSize: 24 * scale),
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green, width: 2.0),
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
              ),

              SizedBox(height: 20 * scale),
              // ElevatedButton(
              //   onPressed: () {
              //     if (_formKey.currentState?.validate() ?? false) {
              //       final maxHR = int.parse(_maxHRController.text);
              //       // Pass all required arguments to TrackingScreen.
              //       Navigator.pushNamed(
              //         context,
              //         '/tracking',
              //         arguments: {
              //           'userDeviceId': userDeviceId,
              //           'partnerDeviceId': partnerDeviceId,
              //           'maxHR': maxHR,
              //         },
              //       );
              //     }
              //   },
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.green,
              //     foregroundColor: Colors.white,
              //     padding: const EdgeInsets.symmetric(vertical: 20),
              //     minimumSize: const Size(0, 60),
              //     textStyle: const TextStyle(fontSize: 24),
              //   ),
              //   child: const Text(
              //     'Start Tracking',
              //     style: TextStyle(fontSize: 24),
              //   ),
              // ),
              SizedBox(
                width: double.infinity,
                height: 80 * scale, // Fixed height for a larger button
                child: ElevatedButton(
                  onPressed: (_maxHRController.text.isEmpty || _partnerMaxHRController.text.isEmpty)
                      ? null
                      : () {
                          if (_formKey.currentState?.validate() ?? false) {
                            final maxHR = int.parse(_maxHRController.text);
                            final partnerMaxHR = int.parse(_partnerMaxHRController.text);
                            Navigator.pushNamed(
                              context,
                              '/tracking',
                              arguments: {
                                'userDeviceId': userDeviceId,
                                'partnerDeviceId': partnerDeviceId,
                                'maxHR': maxHR,
                                'partnerMaxHR': partnerMaxHR,
                              },
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_maxHRController.text.isEmpty || _partnerMaxHRController.text.isEmpty) ? Colors.grey : Colors.green,
                    foregroundColor: Colors.white,
                    textStyle: TextStyle(fontSize: 24 * scale),
                  ),
                  child: const Text('Start Tracking'),
                ),
              ),

            ],
          ),
        ),
          ]
        )
      ),
    );
  }
}
