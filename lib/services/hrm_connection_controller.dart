import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

enum HrmConnectionState { disconnected, connecting, connected }

/// Manages a BLE connection to a single HRM device.
/// Reusable in any screen — call [connect], listen to [stateStream],
/// and call [dispose] when done.
class HrmConnectionController {
  final FlutterReactiveBle _ble;
  StreamSubscription<ConnectionStateUpdate>? _connectionSub;

  final _stateController =
      StreamController<HrmConnectionState>.broadcast();

  HrmConnectionState _state = HrmConnectionState.disconnected;
  String? _connectedDeviceId;

  HrmConnectionController(this._ble);

  HrmConnectionState get state => _state;
  String? get connectedDeviceId => _connectedDeviceId;
  Stream<HrmConnectionState> get stateStream => _stateController.stream;

  /// Immediately marks as connected without BLE. For fake devices only.
  void connectFake(String deviceId) {
    _cancelAll();
    _connectedDeviceId = deviceId;
    _emit(HrmConnectionState.connected);
  }

  /// Connects to [deviceId] via BLE.
  void connect(String deviceId) {
    _cancelAll();
    _connectedDeviceId = deviceId;
    _emit(HrmConnectionState.connecting);

    _connectionSub = _ble
        .connectToDevice(
          id: deviceId,
          connectionTimeout: const Duration(seconds: 10),
        )
        .listen(
          (update) {
            switch (update.connectionState) {
              case DeviceConnectionState.connected:
                _emit(HrmConnectionState.connected);
                break;
              case DeviceConnectionState.disconnected:
                _cancelAll();
                _emit(HrmConnectionState.disconnected);
                break;
              default:
                break;
            }
          },
          onError: (_) {
            _cancelAll();
            _emit(HrmConnectionState.disconnected);
          },
        );
  }

  void disconnect() {
    _cancelAll();
    _connectedDeviceId = null;
    _emit(HrmConnectionState.disconnected);
  }

  void _cancelAll() {
    _connectionSub?.cancel();
    _connectionSub = null;
  }

  void _emit(HrmConnectionState state) {
    _state = state;
    if (!_stateController.isClosed) _stateController.add(state);
  }

  void dispose() {
    _cancelAll();
    _stateController.close();
  }
}
