import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:heart_link_app/screens/heartratedial/semi_dial.dart';
import 'package:heart_link_app/screens/heartratedial/hr.state.dart';
import 'package:heart_link_app/screens/history/workoutdetail_screen.dart';
import 'package:heart_link_app/screens/history/history_screen.dart' show Workout;
import 'package:heart_link_app/screens/history/history_repo.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:heart_link_app/services/userinfo_service.dart';

class HeartratedialScreen extends StatefulWidget {
  const HeartratedialScreen({super.key});
  @override
  State<HeartratedialScreen> createState() => _DialPageState();
}

class _DialPageState extends State<HeartratedialScreen> {
  // cal the initial hr (40%maxhr)
  late int sliderBpm;
  late int liveBpm;
  bool useBle = false;
  bool isConnecting = false;
  bool isConnected = false;
  String? _connectedDeviceId;

  final UserInfoService _userInfoService = UserInfoService();
  int? userAge;
  double? userWeight;
  String? userGender;

  // session type
  String _activity = 'Running';

  // session start time and state
  DateTime _sessionStart = DateTime.now();
  bool _hasStarted = false;
  // store all bpm readings for the session
  final List<int> _bpmLog = <int>[];

  int _sessionMaxHr = 0;
  int _sumHr = 0;
  int _timesHr = 0;
  // average heart rate live
  int get _avgHrLive => _timesHr == 0 ? 0 : (_sumHr / _timesHr).round();

  // user profile(user infomation)
  Future<void> _loadUserInfo() async {
  final userInfo = await _userInfoService.loadCurrentUserProfile();
  if (!mounted) return;

  if (userInfo != null) {
    setState(() {
      userAge    = (userInfo['age'] as num?)?.toInt();
      userWeight = (userInfo['weight'] as num?)?.toDouble();
      userGender = userInfo['gender'] as String?;
    });

    debugPrint('Loaded user info: age=$userAge weight=$userWeight gender=$userGender');
  } else {
    debugPrint('No user profile found in Firestore');
  }
}

  // ingest a new heart rate reading
  void _ingestReading(int bpm) {
    if (bpm <= 0) return;
    if (!_hasStarted) {
      _hasStarted = true;
      _sessionStart = DateTime.now();
    }
    _sumHr += bpm;
    _timesHr++;
    if (bpm > _sessionMaxHr) _sessionMaxHr = bpm;
  }

  // refresh UI timer
  Timer? _uiTicker;
  // format duration
  String _fmtHms(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  // BLE handling
  final FlutterReactiveBle _ble = FlutterReactiveBle(); // BLE instance
  StreamSubscription<ConnectionStateUpdate>? _conn; // connection subscription state
  StreamSubscription<List<int>>? _hrSub; // heart rate data subscription

  // parse heart rate from data
  int _parseHeartRate(List<int> data) {
    if (data.isEmpty) return 0;
    final flags = data[0];
    final isUint16 = (flags & 0x01) != 0;
    if (isUint16) {
      if (data.length < 3) return 0;
      return data[1] | (data[2] << 8);
    } else {
      if (data.length < 2) return 0;
      return data[1];
    }
  }

  // connect to device and subscribe to heart rate
  Future<void> _connectAndSubscribe(String deviceId) async {
    setState(() {
      isConnecting = true;
      _connectedDeviceId = deviceId;
    });

    // connect to device
    _conn = _ble
        .connectToDevice(id: deviceId, connectionTimeout: const Duration(seconds: 12))
        .listen((u) {
      if (u.connectionState == DeviceConnectionState.connected) {
        setState(() {
          isConnected = true;
          isConnecting = false;
        });

        // heart rate service 
        final ch = QualifiedCharacteristic(
          deviceId: deviceId,
          serviceId: Uuid.parse("180D"),
          characteristicId: Uuid.parse("2A37"),
        );

        // subscribe to heart rate measurement
        _hrSub?.cancel();
        _hrSub = _ble.subscribeToCharacteristic(ch).listen((data) {
          final hr = _parseHeartRate(data);
          if (hr > 0) {
            setState(() {
              liveBpm = hr;
              useBle = true;
              _ingestReading(hr); // ingest new reading
            });
            _bpmLog.add(hr); // log bpm reading
          }
        }, onError: (e) => debugPrint('HR notify error: $e'));

        // disconnection handling
      } else if (u.connectionState == DeviceConnectionState.disconnected) {
        setState(() {
          isConnected = false;
          useBle = false;
        });
      }
    }, onError: (e) {
      setState(() => isConnecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('BLE connect error: $e')),
      );
    });
  }

  // init state
  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    // keep the screen lighting always
    WakelockPlus.enable();
    
    // initial to 40%maxhr 
    final maxHr = hrState.maxHr;                 
    final baseline = (maxHr * 0.40).round();     
    sliderBpm = baseline;                      
    liveBpm = baseline;

    // get arguments from last route
    Future.microtask(() {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final deviceId = args?['deviceId'] as String?;
      final deviceName = args?['deviceName'] as String?;
      final activityArg = args?['activity'] as String?;

      // store activity type
      if (activityArg != null && activityArg.isNotEmpty) {
        _activity = activityArg; 
      }

      // connect if deviceId provided
      if (deviceId != null) {
        _connectedDeviceId = deviceName ?? deviceId;
        _connectAndSubscribe(deviceId);
      }
    });

    // UI refresh timer
    _uiTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  // dispose
  @override
  void dispose() {
    WakelockPlus.disable();
    _hrSub?.cancel();
    _conn?.cancel();
    _uiTicker?.cancel();
    super.dispose();
  }

  int _zoneIndexFor(double pct) {
    if (pct < 0.65) return 0;
    if (pct < 0.80) return 1;
    if (pct < 0.89) return 2;
    if (pct < 0.95) return 3;
    return 4;
  }
  
  Color _zoneColor(int idx) {
  switch (idx) {
    case 0: return const Color(0xFF666A70); 
    case 1: return const Color(0xFF2F6BDA);
    case 2: return const Color(0xFF66B35B); 
    case 3: return const Color(0xFFF3A43B); 
    default: return const Color(0xFFE25353); 
  }
}

  String _zoneMessage(int idx) {
    switch (idx) {
      case 0: return "Light and easy";
      case 1: return "Endurance pace";
      case 2: return "Moderate";
      case 3: return "Challenging";
      default: return "Max effort";
    }
  }

  // calories cal
  int _Caloriescal({
    required int agvHr,
    required int age,
    required double weight,
    required String gender,
    required Duration duration,
  }) {
    // accurate use second to convert
    final minutesworkout = duration.inSeconds / 60.0;
    double calPerMinutes;
    if (gender == 'female') {
      calPerMinutes = ((0.4472 * agvHr - 0.1263 * weight + 0.074 * age - 20.4022) / 4.184);
    } else {
      calPerMinutes = ((0.6309 * agvHr - 0.1988 * weight + 0.2017 * age - 55.0969) / 4.184);
    }
    return (calPerMinutes * minutesworkout).round();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: hrState,
      builder: (context, _) {
        final int maxHrTheoretical = hrState.maxHr;
        final int minBpm = (maxHrTheoretical * 0.40).round();
        final int safeSliderBpm = sliderBpm.clamp(minBpm, maxHrTheoretical);
        final displayBpmRaw = useBle ? (liveBpm > 0 ? liveBpm : sliderBpm) : sliderBpm;
        final displayBpm = displayBpmRaw < minBpm ? minBpm : displayBpmRaw;
        // max hr zone color
        final pctMax = (_sessionMaxHr / maxHrTheoretical).clamp(0, 1).toDouble();
        final zoneIndexMax = _zoneIndexFor(pctMax);
        final zoneColorMax = _zoneColor(zoneIndexMax);

        // avg hr zone color
        final pctAvg = (_avgHrLive / maxHrTheoretical).clamp(0, 1).toDouble();
        final zoneIndexAvg = _zoneIndexFor(pctAvg);
        final zoneColorAvg = _zoneColor(zoneIndexAvg);
        
        // message 
        final pct = (displayBpm / maxHrTheoretical).clamp(0, 1).toDouble();
        final zoneIndex = _zoneIndexFor(pct);
        final msg = _zoneMessage(zoneIndex);
        final zoneColor = _zoneColor(zoneIndex);

        final elapsed = _hasStarted
            ? DateTime.now().difference(_sessionStart)
            : Duration.zero;
        final elapsedText = _fmtHms(elapsed);

        return Scaffold(
          appBar: AppBar(
            title: Text(isConnected
                ? 'Heart Rate (Connected)'
                : (isConnecting ? 'Connecting…' : 'Heart Rate')),
            actions: [
              if (_connectedDeviceId != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Center(
                    child: Text(
                      _connectedDeviceId!,
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 1.2,
                  child: SemiDial(
                    bpm: displayBpm,
                    maxHr: maxHrTheoretical,
                  ),
                ),

                const SizedBox(height: 0),
                Text(
                  elapsedText, 
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: zoneColor, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    msg,
                    textAlign: TextAlign.center,
                    // text size
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(child: _InfoCard(title: 'Max HR', value: '$_sessionMaxHr bpm', color: zoneColorMax,)),
                    const SizedBox(width: 12),
                    Expanded(child: _InfoCard(title: 'Avg HR', value: '${_avgHrLive} bpm', color: zoneColorAvg,)),
                  ],
                ),
                const SizedBox(height: 30),

                // end session button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color.fromARGB(255, 175, 82, 82),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                    try {
                      final elapsed = _hasStarted
                          ? DateTime.now().difference(_sessionStart)
                          : Duration.zero;

                      final avg = _avgHrLive;
                      final kcal = _Caloriescal(
                        agvHr: avg,
                        age: userAge ?? 0,
                        weight: userWeight ?? 0.0,
                        gender: userGender ?? 'female',
                        duration: elapsed,
                      );

                      _hrSub?.cancel();
                      _conn?.cancel();

                      final workout = Workout(
                        type: _activity,
                        start: _sessionStart,
                        duration: elapsed,
                        avgHr: avg,
                        calories: kcal,
                      );

                      // write to local and Firestore
                      await HistoryRepo.instance.add(workout, _bpmLog);

                      if (!mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => WorkoutDetailScreen(
                            workout: workout,
                            series: List<int>.from(_bpmLog),
                          ),
                        ),
                      );
                    } catch (e, st) {
                      debugPrint('End session error: $e\n$st');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save workout: $e')),
                      );
                    }
                  },
                    child: const Text(
                      'End Session',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // bpm slider
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'BPM: $displayBpm',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      value: safeSliderBpm.toDouble(), 
                      min: minBpm.toDouble(),
                      max: maxHrTheoretical.toDouble(),
                      divisions: (maxHrTheoretical - minBpm) > 0
                          ? (maxHrTheoretical - minBpm)
                          : null,
                      label: '$sliderBpm',
                      onChanged: useBle
                          ? null
                          : (v) => setState(() {
                              sliderBpm = v.round();
                              _bpmLog.add(sliderBpm);
                              _ingestReading(sliderBpm);
                            }),
                    ),
                    if (useBle)
                      const Text(
                        'Using BLE live data — slider disabled',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),            
        border: Border.all(color: color, width: 2), 
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,                         
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,                   
            ),
          ),
        ],
      ),
    );
  }
}