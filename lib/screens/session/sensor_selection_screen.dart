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
    
    // For testing: add a dummy device with a valid Bluetooth address format.
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
      // Add device if it is not already in the list.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Sensors')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Select Your Sensor'),
            ),
            DropdownButton<DiscoveredDevice>(
              hint: const Text('Select Device'),
              value: _selectedUserDevice,
              items: _devicesList.map((device) {
                return DropdownMenuItem<DiscoveredDevice>(
                  value: device,
                  child: Text(device.name.isNotEmpty ? device.name : device.id),
                );
              }).toList(),
              onChanged: (device) {
                setState(() {
                  _selectedUserDevice = device;
                });
              },
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Select Partner’s Sensor'),
            ),
            DropdownButton<DiscoveredDevice>(
              hint: const Text('Select Device'),
              value: _selectedPartnerDevice,
              items: _devicesList.map((device) {
                return DropdownMenuItem<DiscoveredDevice>(
                  value: device,
                  child: Text(device.name.isNotEmpty ? device.name : device.id),
                );
              }).toList(),
              onChanged: (device) {
                setState(() {
                  _selectedPartnerDevice = device;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: (_selectedUserDevice == null || _selectedPartnerDevice == null)
                  ? null
                  : () {
                      Navigator.pushNamed(context, '/tracking', arguments: {
                        'userDeviceId': _selectedUserDevice!.id,
                        'partnerDeviceId': _selectedPartnerDevice!.id,
                      });
                    },
              child: const Text('Start Tracking'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _devicesList.clear();
                  _selectedUserDevice = null;
                  _selectedPartnerDevice = null;
                });
                _startScan();
              },
              child: const Text('Refresh Devices'),
            ),
          ],
        ),
      ),
    );
  }
}
