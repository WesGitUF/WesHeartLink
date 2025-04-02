import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class SensorSelectionScreen extends StatefulWidget {
  const SensorSelectionScreen({super.key});
  @override
  _SensorSelectionScreenState createState() => _SensorSelectionScreenState();
}

class _SensorSelectionScreenState extends State<SensorSelectionScreen> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final List<DiscoveredDevice> _devicesList = [];
  DiscoveredDevice? _selectedUserDevice;
  DiscoveredDevice? _selectedPartnerDevice;
  StreamSubscription<DiscoveredDevice>? _scanSubscription;

  @override
  void initState() {
    super.initState();
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
        } else {
          _selectedPartnerDevice = selected;
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
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 400.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Sensors'),
        leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, '/roleSelection');
          }
        },
      ),
      ),
      body: Column(
        children: [
          // const Text(
          //         "Step 3 of 4",
          //         style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          //         textAlign: TextAlign.center,
          //       ),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Step 3 of 4",
                  style: TextStyle(fontSize: 20 * scale, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: "Device not visible? Please hit the refresh button and try again!",
                  child: const Icon(
                    Icons.info_outline,
                    color: Color.fromARGB(255, 248, 0, 0),
                  ),
                ),
              ],
            ),      
          const Divider(thickness: 2, color: Colors.grey),
          // Top half: Your sensor selection.
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Add your HRM", style: TextStyle(fontSize: 20 * scale)),
                  SizedBox(height: 10 * scale),
                  _buildSensorSelectButton(device: _selectedUserDevice, forUser: true),
                ],
              ),
            ),
          ),
          const Divider(thickness: 2, color: Colors.grey),
          // Bottom half: Partner sensor selection.
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Add you partner's HRM", style: TextStyle(fontSize: 20 * scale)),
                  SizedBox(height: 10 * scale),
                  _buildSensorSelectButton(device: _selectedPartnerDevice, forUser: false),
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
                    onPressed: (_selectedUserDevice == null || _selectedPartnerDevice == null)
                        ? null
                        : () {
                            Navigator.pushNamed(
                              context,
                              '/maxHR',
                              arguments: {
                                'userDeviceId': _selectedUserDevice!.id,
                                'partnerDeviceId': _selectedPartnerDevice!.id,
                              },
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_selectedUserDevice == null || _selectedPartnerDevice == null)
                          ? Colors.grey
                          : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: TextStyle(fontSize: 24 * scale),
                    ),
                    child: const Text('Enter Max HR'),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 32, color: Colors.blue),
                  onPressed: () {
                    setState(() {
                      // _devicesList.clear();
                      _selectedUserDevice = null;
                      _selectedPartnerDevice = null;
                    });
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
