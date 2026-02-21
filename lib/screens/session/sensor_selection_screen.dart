import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:heart_link_app/services/battery_optimization.dart';
import 'package:permission_handler/permission_handler.dart';

class SensorSelectionScreen extends StatefulWidget {
  final String workoutMode;

  const SensorSelectionScreen({
    Key? key,
    required this.workoutMode,
  }) : super(key: key);

  @override
  _SensorSelectionScreenState createState() => _SensorSelectionScreenState();
}

class _SensorSelectionScreenState extends State<SensorSelectionScreen> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final List<DiscoveredDevice> _devicesList = [];
  DiscoveredDevice? _selectedUserDevice;
  StreamSubscription<DiscoveredDevice>? _scanSubscription;

  IconData? _workoutModeIcon;

  late String _workoutMode;

  @override
  void initState() {
    super.initState();
    _workoutMode = widget.workoutMode;
    pickIcon();
    // Dummy device for testing
    setState(() {
      _devicesList.add(DiscoveredDevice(
        id: '00:11:22:33:44:55', // Valid Bluetooth address format.
        name: 'Fake HRM Device',
        serviceData: {},
        manufacturerData: Uint8List(0),
        rssi: -50,
        serviceUuids: [],
      ));
    });

    // Request permissions then start scanning for real devices.
    requestPermissions().then((granted) {
      if (granted) {
        _startScan();
      } else {
        print("Permissions not granted.");
      }
    });
  }

  void pickIcon() {
    if (_workoutMode == "Running") { _workoutModeIcon = Icons.directions_run; }
    else if (_workoutMode == "Cycling") { _workoutModeIcon = Icons.directions_bike; }
    else if (_workoutMode == "HIIT") { _workoutModeIcon = Icons.fitness_center; }
    else if (_workoutMode == "Walking") { _workoutModeIcon = Icons.directions_walk; }
    else if (_workoutMode == "Swimming") { _workoutModeIcon = Icons.pool; }
  }

  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    return statuses.values.every((status) => status.isGranted);
  }

  void _startScan() {
    // Filter for the Heart Rate Service (UUID: 180D).
    final serviceUuid = Uuid.parse("180D");
    _scanSubscription = _ble.scanForDevices(
      withServices: [serviceUuid],
      scanMode: ScanMode.lowLatency,
    ).listen((DiscoveredDevice device) {
      print("Discovered device: ${device.name.isNotEmpty ? device.name : device.id}, RSSI: ${device.rssi}");
      if (!_devicesList.any((d) => d.id == device.id)) {
        setState(() {
          _devicesList.add(device);
        });
      }
    }, onError: (error) {
      print("Scan error: $error");
    });
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  Future<void> _showDeviceSelectionMenu(bool forUser) async {
    final selected = await showModalBottomSheet<DiscoveredDevice>(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: _devicesList.length,
          itemBuilder: (context, index) {
            final device = _devicesList[index];
            return ListTile(
              leading: const Icon(Icons.bluetooth),
              title: Text(device.name.isNotEmpty ? device.name : device.id),
              onTap: () {
                Navigator.pop(context, device);
              },
            );
          },
        );
      },
    );
    if (selected != null) {
      setState(() {
        if (forUser) {
          _selectedUserDevice = selected;
        }
      });
    }
  }

  Widget _buildSensorSelectButton({required DiscoveredDevice? device, required bool forUser}) {
    return GestureDetector(
      onTap: () {
        _showDeviceSelectionMenu(forUser);
      },
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black26, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.favorite, size: 110, color: Colors.red),
            if (device == null)
              Positioned(
                right: 8,
                bottom: 8,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.redAccent,
                  child: const Icon(Icons.add, size: 30, color: Colors.white),
                ),
              ),
            if (device != null)
              Positioned(
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    device.name.isNotEmpty ? device.name : device.id,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              }, 
              icon: const Icon(Icons.arrow_back, color: Colors.white,),
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
      body: Column(
        children: [
          // Top half: Your sensor selection.
          const SizedBox(height: 20),
          Text(
            "Set Up New Session",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold
            ),
            textAlign: TextAlign.center,
          ),
          const Divider(
            color: Colors.grey,
            thickness: 1,     
            indent: 16,        
            endIndent: 16,     
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Your Sensor", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildSensorSelectButton(device: _selectedUserDevice, forUser: true),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                //Create Session Button
                ElevatedButton(
                  onPressed: (_selectedUserDevice == null)
                      ? null
                      : () async{
                          final result = await showDialog<String>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Choose Mode'),
                                content: const Text('Would you like to start in Online or Offline mode (Not Supported on iPhone)?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, 'offline'),
                                    child: const Text('Offline'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, 'online'),
                                    child: const Text('Online'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (result == null) return;

                          bool isOnline = result == 'online' ? true : false;

                          await BatteryOptimization.maybePromptOnce(context);
                          if (!context.mounted) return;

                          if (context.mounted) {
                            Navigator.pushNamed(
                              context,
                              '/radialGauge',
                              arguments: {
                                'userDeviceId': _selectedUserDevice!.id,
                                'isOnline': isOnline,
                                'isHost': true,       
                                'workoutMode': _workoutMode,
                              },
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_selectedUserDevice == null)
                        ? Colors.grey
                        : Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                    textStyle: const TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  child: Text(
                    'Create New Session',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: (_selectedUserDevice == null)
                        ? Colors.black
                        : Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Join Session Button
                ElevatedButton(
                  onPressed: (_selectedUserDevice == null)
                      ? null
                      : () async {
                        final result = await showDialog<String>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Choose Mode'),
                              content: const Text('Would you like to start in Online or Offline mode?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, 'offline'),
                                  child: const Text('Offline'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, 'online'),
                                  child: const Text('Online'),
                                ),
                              ],
                            );
                          },
                        );

                        if (result == null) return;

                        bool isOnline = result == 'online' ? true : false;

                        await BatteryOptimization.maybePromptOnce(context);
                        if (!context.mounted) return;

                          Navigator.pushNamed(
                            context,
                            '/radialGauge',
                            arguments: {
                              'userDeviceId': _selectedUserDevice!.id,
                              'isOnline': isOnline,
                              'isHost': false,    
                              'workoutMode': _workoutMode,
                            },
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                  child: Text(
                    'Join Session',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: (_selectedUserDevice == null)
                        ? Colors.black
                        : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
