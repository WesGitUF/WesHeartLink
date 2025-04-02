import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 400.0;
    return Scaffold(
      appBar: AppBar(title: const Text('Select Device Role'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, '/session');
          }
        },
      ),),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Step 2 of 4",
                  style: TextStyle(fontSize: 20 * scale, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                SizedBox(width: 8 * scale),
                Tooltip(
                  message: "Primary device: connects with all HRMs\n"
                      "Secondary device: receives all HRs shared from the primary device\n"
                      "Make sure your phones have internet access.",
                  child: IconButton(
                    icon: const Icon(Icons.info_outline),
                    color: const Color.fromARGB(255, 248, 1, 1), 
                    onPressed: () {
                      
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Instruction Text
                  Text(
                    'Are you the primary (host) device or the secondary (peer) device?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20 * scale),
                  ),
                  SizedBox(height: 32 * scale),
                  // Primary Button with consistent styling
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final args = ModalRoute.of(context)!.settings.arguments as Map?;
                        final String? sport = args?['sport'] as String?;
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/sensorSelection',
                          (route) => false,
                          arguments: {
                            'sport': sport,
                          }
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        minimumSize: const Size(0, 60), 
                        textStyle: TextStyle(fontSize: 24 * scale),
                      ),
                      child: const Text('Primary (Host)'),
                    ),
                  ),
                  SizedBox(height: 16 * scale),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final args = ModalRoute.of(context)!.settings.arguments as Map?;
                        final String? sport = args?['sport'] as String?;

                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/tracking',
                          (route) => false,
                          arguments: {'role': 'secondary', 'sport': sport},
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        minimumSize: const Size(0, 60), 
                        textStyle: TextStyle(fontSize: 24 * scale),
                      ),
                      child: const Text('Secondary (Peer)'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
