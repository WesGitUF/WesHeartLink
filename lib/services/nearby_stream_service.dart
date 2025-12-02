import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

final flutterReactiveBle = FlutterReactiveBle();
final nearbyService = NearbyService();

class NearbyService {
  static final NearbyService _instance = NearbyService._internal();
  factory NearbyService() => _instance;
  NearbyService._internal();

  final Strategy strategy = Strategy.P2P_STAR;
  //package name in androidmanifest.xml
  final String serviceId = "com.example.heart_link_app";
  final ValueNotifier<bool> guestConnectedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> partnerHeartRate = ValueNotifier<int>(0);
  final Map<String, ConnectionInfo> _connectedPeers = {};

  void stopAll() async {
    await Nearby().stopAllEndpoints();
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
  }

  Future<void> initializeNearby({required String role, required String userName, String? sessionCode}) async {
    stopAll();

    if (role == "host") {
      await Nearby().startAdvertising(
        "$sessionCode",
        strategy,
        onConnectionInitiated: (id, info) {
          _connectedPeers[id] = info;
          Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (endpointId, payload) {
              final data = utf8.decode(payload.bytes!);
              final json = jsonDecode(data);
              if (json["hr"] != null) {
                partnerHeartRate.value = json["hr"];
              }
            },
            onPayloadTransferUpdate: (_, __) {},
          );

          guestConnectedNotifier.value = true;
        },
        onConnectionResult: (_, __) {},
        onDisconnected: (id) => _connectedPeers.remove(id),
        serviceId: serviceId,
      );
    } else if (role == "peer") {
      await Nearby().startDiscovery(
        userName,
        strategy,
        onEndpointFound: (id, name, serviceId) {
          if (name.contains("$sessionCode")) {
            Nearby().requestConnection(
              userName,
              id,
              onConnectionInitiated: (id, info) {
                _connectedPeers[id] = info;
                Nearby().acceptConnection(
                  id,
                  onPayLoadRecieved: (endpointId, payload) {
                    final data = utf8.decode(payload.bytes!);
                    final json = jsonDecode(data);
                    if (json["hr"] != null) {
                      partnerHeartRate.value = json["hr"];
                    }
                  },
                  onPayloadTransferUpdate: (_, __) {},
                );
              },
              onConnectionResult: (_, __) {},
              onDisconnected: (id) => _connectedPeers.remove(id),
            );
          }
          else {
            print("Skipping $name, does not contain match");
          }
        },
        onEndpointLost: (_) {},
        serviceId: serviceId,
      );
    }
  }

  void sendHeartRate(int heartRate) {
    final payload = utf8.encode(jsonEncode({"hr": heartRate}));
    for (var id in _connectedPeers.keys) {
      Nearby().sendBytesPayload(id, Uint8List.fromList(payload));
    }
  }
}

class HeartRateSyncScreen extends StatefulWidget {
  final String deviceId;
  final int maxHR;
  final String role;
  final String userName;

  const HeartRateSyncScreen({
    super.key,
    required this.deviceId,
    required this.maxHR,
    required this.role,
    required this.userName,
  });

  @override
  State<HeartRateSyncScreen> createState() => _HeartRateSyncScreenState();
}

class _HeartRateSyncScreenState extends State<HeartRateSyncScreen> {
  StreamSubscription<List<int>>? _hrSubscription;
  int myHeartRate = 0;

  @override
  void initState() {
    super.initState();
    _startBLE();
    nearbyService.initializeNearby(role: widget.role, userName: widget.userName);
  }

  void _startBLE() {
    final serviceUuid = Uuid.parse("180D"); // Heart Rate Service
    final charUuid = Uuid.parse("2A37"); // Heart Rate Measurement
    final deviceId = widget.deviceId;

    final characteristic = QualifiedCharacteristic(
      serviceId: serviceUuid,
      characteristicId: charUuid,
      deviceId: deviceId,
    );

    _hrSubscription = flutterReactiveBle.subscribeToCharacteristic(characteristic).listen((data) {
      final hr = _parseHeartRate(data);
      if (hr != null) {
        setState(() => myHeartRate = hr);
        nearbyService.sendHeartRate(hr);
      }
    });
  }

  int? _parseHeartRate(List<int> data) {
    if (data.isEmpty) return null;
    final flags = data[0];
    final is16Bit = (flags & 0x01) != 0;
    return is16Bit
        ? (data.length >= 3 ? data[1] + (data[2] << 8) : null)
        : data.length >= 2
            ? data[1]
            : null;
  }

  @override
  void dispose() {
    _hrSubscription?.cancel();
    nearbyService.stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Real-time HR Sync")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("My HR: $myHeartRate", style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 40),
            const Text("Partner HR:", style: TextStyle(fontSize: 24)),
            const SizedBox(height: 10),
            ValueListenableBuilder<int>(
              valueListenable: nearbyService.partnerHeartRate,
              builder: (_, partnerHR, __) => Text(
                "$partnerHR",
                style: const TextStyle(fontSize: 32, color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
