import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:heart_link_app/models/heart_rate_zone.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});
  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  // Instead of BluetoothDevice, we'll use device IDs (Strings)
  String? userDeviceId;
  String? partnerDeviceId;

  int _userHR = 0;
  int _partnerHR = 0;

  // Keep track of connection and subscription streams
  StreamSubscription<ConnectionStateUpdate>? _userConnection;
  StreamSubscription<ConnectionStateUpdate>? _partnerConnection;
  StreamSubscription<List<int>>? _userSubscription;
  StreamSubscription<List<int>>? _partnerSubscription;

  @override
  void initState() {
    super.initState();
    // Expecting the previous screen to pass device IDs as arguments
    Future.delayed(Duration.zero, () {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      userDeviceId = args['userDeviceId'] as String;
      partnerDeviceId = args['partnerDeviceId'] as String;
      _connectToDevices();
    });
  }

  void _connectToDevices() {
    if (userDeviceId != null) {
      _userConnection = _ble.connectToDevice(
        id: userDeviceId!,
        connectionTimeout: const Duration(seconds: 10),
      ).listen((connectionState) {
        if (connectionState.connectionState == DeviceConnectionState.connected) {
          _subscribeToCharacteristic(userDeviceId!, isUser: true);
        }
      });
    }
    if (partnerDeviceId != null) {
      _partnerConnection = _ble.connectToDevice(
        id: partnerDeviceId!,
        connectionTimeout: const Duration(seconds: 10),
      ).listen((connectionState) {
        if (connectionState.connectionState == DeviceConnectionState.connected) {
          _subscribeToCharacteristic(partnerDeviceId!, isUser: false);
        }
      });
    }
  }

  void _subscribeToCharacteristic(String deviceId, {required bool isUser}) {
    // Define the qualified characteristic for the Heart Rate Measurement (UUID 2A37 in service 180D)
    final characteristic = QualifiedCharacteristic(
      deviceId: deviceId,
      serviceId: Uuid.parse("180D"),
      characteristicId: Uuid.parse("2A37"),
    );

    final subscription = _ble.subscribeToCharacteristic(characteristic).listen(
      (data) {
        // Data is a List<int>; for a typical heart rate monitor, the value is often at index 1.
        int hrValue = data.length > 1 ? data[1] : 0;
        setState(() {
          if (isUser) {
            _userHR = hrValue;
          } else {
            _partnerHR = hrValue;
          }
        });
      },
      onError: (error) {
        // Handle error (e.g., show a message or log the error)
        print("Error on device $deviceId: $error");
      },
    );

    if (isUser) {
      _userSubscription = subscription;
    } else {
      _partnerSubscription = subscription;
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _partnerSubscription?.cancel();
    _userConnection?.cancel();
    _partnerConnection?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    HeartRateZone userZone = getZoneForHR(_userHR);
    HeartRateZone partnerZone = getZoneForHR(_partnerHR);
    bool sameZone = userZone.name == partnerZone.name;

    return Scaffold(
      appBar: AppBar(title: const Text('Tracking Heart Rates')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: Color(userZone.colorValue).withOpacity(0.2),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('You', style: TextStyle(fontSize: 24)),
                      Text('$_userHR bpm', style: const TextStyle(fontSize: 48)),
                      Text('Zone: ${userZone.name}', style: const TextStyle(fontSize: 20)),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: Color(partnerZone.colorValue).withOpacity(0.2),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Partner', style: TextStyle(fontSize: 24)),
                      Text('$_partnerHR bpm', style: const TextStyle(fontSize: 48)),
                      Text('Zone: ${partnerZone.name}', style: const TextStyle(fontSize: 20)),
                    ],
                  ),
                ),
              ),
            ),
            sameZone
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Great job! You’re both in the same zone ❤️',
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
