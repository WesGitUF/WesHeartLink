import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert'; 
// import 'package:flutter_bluetooth_serial/FlutterBluetoothSerial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:heart_link_app/models/heart_rate_zone.dart';
import 'package:heart_link_app/widgets/custom_widgets.dart'; // Contains PulseHeart & HeartRateMeter


class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});
  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {

  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();


  final FlutterReactiveBle _ble = FlutterReactiveBle();

  String? userDeviceId;
  String? partnerDeviceId;

  int _userHR = 0;
  int _partnerHR = 0;
  late int maxHeartRate;

  StreamSubscription<ConnectionStateUpdate>? _userConnection;
  StreamSubscription<ConnectionStateUpdate>? _partnerConnection;
  StreamSubscription<List<int>>? _userSubscription;
  StreamSubscription<List<int>>? _partnerSubscription;
  StreamSubscription<DiscoveredDevice>? _scanSubscription;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  Duration _sameZoneDuration = Duration.zero;

  final AdvertiseData _advertiseData = AdvertiseData(
    serviceUuid: '0000F00D-0000-1000-8000-00805F9B34FB',
    localName: 'HeartLinkPrimary',
    manufacturerId: 1234,
    manufacturerData: Uint8List.fromList([1, 2, 3, 4]),
    );

  Future<void> _startBleAdvertising() async {
    try {
      await _blePeripheral.start(advertiseData: _advertiseData);
      print('Primary phone: BLE advertising started.');
    } catch (e) {
      print('Error starting BLE advertising: $e');
    }
  }
  Future<void> _stopBleAdvertising() async {
    try {
      await _blePeripheral.stop();
      print('Stopped BLE advertising.');
    } catch (e) {
      print('Error stopping BLE advertising: $e');
    }
  }

  void _startBleScanForPrimary() {
  var targetServiceUuid = Uuid.parse("0000F00D-0000-1000-8000-00805F9B34FB");
  _scanSubscription = _ble.scanForDevices(withServices: [targetServiceUuid])
    .listen((device) {
      print("Secondary found potential primary phone: ${device.name}, id: ${device.id}");
      
      if (device.manufacturerData.isNotEmpty) {
        final mapString = utf8.decode(device.manufacturerData);
        print("Decoded advertisement data: $mapString");
      }
    },
    onError: (err) {
      print("Scan error: $err");
    }
  );
}

Future<void> _updateBleData() async {
  // convert the HR  to JSON
  final hrMap = {
    'userHR': _userHR,
    'partnerHR': _partnerHR,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  final hrBytes = utf8.encode(jsonEncode(hrMap));

  // stop old advert
  try {
    await _blePeripheral.stop();
    print('Stopped old advertisement.');
  } catch (e) {
    print('Error stopping old advertisement: $e');
  }

  // create new Advertisedata
  final newData = AdvertiseData(
    serviceUuid: '0000F00D-0000-1000-8000-00805F9B34FB',
    localName: 'HeartLinkPrimary',
    manufacturerId: 1234,
    manufacturerData: Uint8List.fromList(hrBytes), // updated with new HR
  );

  // 4) new advert
  try {
    await _blePeripheral.start(advertiseData: newData);
    print('Restarted advertisement with new data: $hrMap');
  } catch (e) {
    print('Error starting advertisement: $e');
  }
}





  // BluetoothConnection? _btConnection;

  // String? _targetAddress;

  // Future<String?> selectTargetDevice(BuildContext context) async {
  // // get a list of paired devices
  //   List<BluetoothDevice> devices = await FlutterBluetoothSerial.instance.getBondedDevices();
  //     return await showDialog<String>(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return SimpleDialog(
  //           title: const Text("Select Secondary Device"),
  //           children: devices.map((device) {
  //             return SimpleDialogOption(
  //               onPressed: () {
  //                 Navigator.pop(context, device.address);
  //               },
  //               child: Text(device.name ?? device.address),
  //             );
  //           }).toList(),
  //         );
  //       },
  //     );
  //   }
    // Future<void> ensureTargetAddress() async {
    //   _targetAddress ??= await selectTargetDevice(context);
    // }




  //bluetooth spp sending HR data
  // Future<void> sendHRData({required int userHR, required int partnerHR, required String targetAddress}) async {
  //   try {
  //     // check if the connection is null or closed and open if needed
  //     if (_btConnection == null) {
  //       _btConnection = await BluetoothConnection.toAddress(targetAddress);
  //       print('Connected to the server at $targetAddress');
  //     }
      
  //     String message = jsonEncode({
  //       'userHR': userHR,
  //       'partnerHR': partnerHR,
  //       'timestamp': DateTime.now().millisecondsSinceEpoch,
  //     });
      
  //     _btConnection!.output.add(utf8.encode(message + "\r\n"));
  //     await _btConnection!.output.allSent;
  //     print('HR data sent: $message');
      
  //   } catch (e) {
  //     print("Error while sending HR data: $e");
  //   }
  // }

// Future<void> _startBluetoothServer() async {
//   try {
//     print("Secondary: Starting Bluetooth server...");

    
//     bool isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
//     if (!isEnabled) {
//       await FlutterBluetoothSerial.instance.requestEnable();
//     }

//     final serverSocket = await FlutterBluetoothSerial.instance.createRfcommServer(name: "HeartLinkServer");  

//     print("Server socket created, waiting for connection...");
//     final socket = await serverSocket.accept();
    

//     print("Client connected from: ${socket.remoteAddress}");

//     socket.input.listen((data) {
//       final message = String.fromCharCodes(data);
//       print("Secondary received message: $message");
//       _onDataReceived(message); 
//     }, onDone: () {
//       print("Client disconnected.");
//     });

//   } catch (e) {
//     print("Error starting Bluetooth SPP server: $e");
//   }
// }

// void _onDataReceived(String message) {
//   try {
//     final map = jsonDecode(message);
//     setState(() {
//       _userHR = map['userHR'] ?? _userHR;
//       _partnerHR = map['partnerHR'] ?? _partnerHR;
//     });
//   } catch (e) {
//     print("Error parsing data: $e");
//   }
// }


  // Flag to indicate that initialization is complete.
  bool _isInitialized = false;

  void _startTimer() {
    // print("Timer starting"); THAT WAS FOR TESTING: WESLY
    _stopwatch.reset();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // print("Timer tick: ${_stopwatch.elapsed}"); THAT WAS FOR TESTING: WESLY
      setState(() {
        if (!_isSecondary) {
          // Just for testing, simulate changing HR
        _userHR = 60 + Random().nextInt(40);
        _partnerHR = 60 + Random().nextInt(40);
        }
        // Calculate zones for current HR values using maxHeartRate
          var currentUserZone = getZoneForHR(_userHR, maxHeartRate);
          var currentPartnerZone = getZoneForHR(_partnerHR, maxHeartRate);
          // If the zones are the same then add one second to _sameZoneDuration
          if (currentUserZone.name == currentPartnerZone.name) {
            _sameZoneDuration += const Duration(seconds: 1);
          }
      }); // Refresh the UI every second

      // primary updates advertisment everey second
      if (!_isSecondary){
        _updateBleData();
      }
      // //only send if spp is in primary
      // if (!_isSecondary){
      //   await ensureTargetAddress();
      //   if (_targetAddress != null) {
      //     sendHRData(
      //     userHR: _userHR, 
      //     partnerHR: _partnerHR, 
      //     targetAddress: _targetAddress!
      //   );
      //   }

      // }
    });
  }

  void _stopTimerAndNavigate() {
    _stopwatch.stop();
    _timer?.cancel();
    // _btConnection?.dispose(); // Close the persistent connection
    final elapsed = _stopwatch.elapsed;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/trackingResult',
      (Route<dynamic> route) => false,
      arguments: {
        'elapsed': elapsed,
        'sameZone': _sameZoneDuration,
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  bool _isSecondary = false;

  @override
  void initState() {
    super.initState();
    print("TrackingScreen initState called");
    Future.delayed(Duration.zero, () {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      //check for the role flag
      if (args != null && args['role'] == 'secondary') {
      print("Operating in secondary mode");
      _isSecondary = true;
      // _startBluetoothServer();
      maxHeartRate = 196;
      _startBleScanForPrimary();
    }else{
      //primary mode
      userDeviceId = args['userDeviceId'] as String?;
      partnerDeviceId = args['partnerDeviceId'] as String?;
      maxHeartRate = args['maxHR'] as int;
      print("TrackingScreen received: userDeviceId=$userDeviceId, partnerDeviceId=$partnerDeviceId, maxHR=$maxHeartRate");
      _connectToDevices();

      //start advertising
      _startBleAdvertising();
    }
      setState(() {
        _isInitialized = true;
      });
      _startTimer();
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
    // Once connections start, cancel scanning to reduce load.
    _scanSubscription?.cancel();
  }

  void _subscribeToCharacteristic(String deviceId, {required bool isUser}) {
    final characteristic = QualifiedCharacteristic(
      deviceId: deviceId,
      serviceId: Uuid.parse("180D"),
      characteristicId: Uuid.parse("2A37"),
    );

    final subscription = _ble.subscribeToCharacteristic(characteristic).listen(
      (data) {
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

    if (!_isSecondary){
      _userSubscription?.cancel();
    _partnerSubscription?.cancel();
    _userConnection?.cancel();
    _partnerConnection?.cancel();
    // _btConnection?.dispose();
    }else{
      
    }
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wait for initialization before building UI that depends on maxHeartRate.
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tracking Heart Rates')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    HeartRateZone userZone = getZoneForHR(_userHR, maxHeartRate);
    HeartRateZone partnerZone = getZoneForHR(_partnerHR, maxHeartRate);
    bool sameZone = userZone.name == partnerZone.name;

    return Scaffold(
      appBar: AppBar(title: const Text('Tracking Heart Rates')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Elapsed Time: ${_formatDuration(_stopwatch.elapsed)}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Divider(thickness: 1, color: Colors.black),
            Expanded(
              child: Container(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PulseHeart(size: 45, color: Colors.red),
                          const SizedBox(height: 2),
                          const Text('You', style: TextStyle(fontSize: 10)),
                          Text('$_userHR bpm', style: const TextStyle(fontSize: 15)),
                          Text('Zone: ${userZone.name}', style: const TextStyle(fontSize: 15)),
                        ],
                      ),
                      const SizedBox(width: 10),
                      HeartRateMeter(heartRate: _userHR, maxHeartRate: maxHeartRate),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(thickness: 1, color: Colors.black),
            Container(
              height: 45,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sameZone ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  sameZone
                      ? 'Great job! You’re both in the same zone ❤️'
                      : 'Alert: In different zones. Adjust your paces.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: Colors.black),
                ),
              ),
            ),
            const Divider(thickness: 1, color: Colors.black),
            Expanded(
              child: Container(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PulseHeart(size: 45, color: Colors.red),
                          const SizedBox(height: 2),
                          const Text('Partner:', style: TextStyle(fontSize: 10)),
                          Text('$_partnerHR bpm', style: const TextStyle(fontSize: 15)),
                          Text('Zone: ${partnerZone.name}', style: const TextStyle(fontSize: 15)),
                        ],
                      ),
                      const SizedBox(width: 10),
                      HeartRateMeter(heartRate: _partnerHR, maxHeartRate: maxHeartRate),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(thickness: 1, color: Colors.black),
            ElevatedButton(
              onPressed: () {
              _stopTimerAndNavigate();
              },
              style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              textStyle: const TextStyle(fontSize: 14),
              ),
              child: const Text("Stop Tracking"),
            ),
          ],
        ),
      ),
    );
  }
}
