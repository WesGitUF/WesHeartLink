import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:heart_link_app/screens/heartratedial/heartratedial_screen.dart';

class SensorSelectionScreen extends StatefulWidget {
  const SensorSelectionScreen({super.key});
  @override
  _SensorSelectionScreenState createState() => _SensorSelectionScreenState();
}

class _SensorSelectionScreenState extends State<SensorSelectionScreen> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final List<DiscoveredDevice> _devicesList = [];
  DiscoveredDevice? _selectedUserDevice;
  StreamSubscription<DiscoveredDevice>? _scanSubscription;

  // connection subscription
  StreamSubscription<ConnectionStateUpdate>? _connectSubscription;
  bool _connecting = false;
  bool _navigated = false;
  String _activity = '';
  @override
  void initState() {
    super.initState();
     WidgetsBinding.instance.addPostFrameCallback((_) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final act = args?['activity'] as String?;
    if (act != null && act.isNotEmpty) {
      setState(() => _activity = act);
    }
  });
    // For testing, add a dummy device (this is optional and can be removed later).
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
    _connectSubscription?.cancel(); //remove connection subscription
    super.dispose();
  }

  // connect ble device and skip to dial screen
  Future<void> _connectAndGo(DiscoveredDevice device) async {
    // cancel any ongoing scan
    await _scanSubscription?.cancel();

    setState(() => _connecting = true);

    // show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    _connectSubscription = _ble
        .connectToDevice(
          id: device.id,
          connectionTimeout: const Duration(seconds: 12),
        )
        .listen((update) async {
      if (_navigated) return;

      if (update.connectionState == DeviceConnectionState.connected) {
        _navigated = true;
        // close loading dialog
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _connecting = false);

        // navigate to dial screen
        Navigator.pushReplacementNamed(
          context,
          '/dial',
          arguments: {
            'deviceId': device.id,
            'deviceName': device.name.isNotEmpty ? device.name : device.id,
            'activity': _activity,
          },
        );

        await _connectSubscription?.cancel();
      } else if (update.connectionState ==
              DeviceConnectionState.disconnected &&
          !_navigated) {
        // close loading dialog
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _connecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect. Please try again.')),
        );
        _startScan();
      }
    }, onError: (e) {
      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _connecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connect error: $e')),
      );
      _startScan();
    });
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
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
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
            Icon(Icons.favorite, size: 80, color: Colors.red),
            if (device == null)
              Positioned(
                right: 8,
                bottom: 8,
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.add, size: 20, color: Colors.white),
                ),
              ),
            if (device != null)
              Positioned(
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.yellowAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    device.name.isNotEmpty ? device.name : device.id,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
      appBar: AppBar(title: const Text('Select Sensors')),
      body: Column(
        children: [
          const Divider(thickness: 2, color: Colors.grey),
          // Top half: Your sensor selection.
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Tap to select your Sensor", style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 10),
                  _buildSensorSelectButton(device: _selectedUserDevice, forUser: true),
                ],
              ),
            ),
          ),
          const Divider(thickness: 2, color: Colors.grey),
          // Navigation button: Go to Max HR Input Screen.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedUserDevice == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HeartratedialScreen(),
                            settings: RouteSettings(
                              arguments: {
                                'deviceId': _selectedUserDevice!.id,
                                'deviceName': _selectedUserDevice!.name.isNotEmpty
                                    ? _selectedUserDevice!.name
                                    : _selectedUserDevice!.id,
                                'activity': _activity,
                              },
                            ),
                          ),
                        );
                      },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_selectedUserDevice == null)
                          ? Colors.grey
                          : Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: const TextStyle(fontSize: 24),
                    ),
                    child: const Text('Let''s get started!',
                    style: TextStyle(color: Colors.white),)
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 32, color: Colors.blue),
                  onPressed: () {
                    setState(() {
                      _devicesList.clear();
                      _selectedUserDevice = null;
                    }
                    );
                    
                    _startScan();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
