import 'dart:async';
import 'dart:ui';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:heart_link_app/app/theme/app_theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:heart_link_app/services/hrm_connection_controller.dart';

class SensorSelectionScreen extends StatefulWidget {
  final String workoutMode;

  const SensorSelectionScreen({Key? key, required this.workoutMode})
    : super(key: key);

  @override
  _SensorSelectionScreenState createState() => _SensorSelectionScreenState();
}

class _SensorSelectionScreenState extends State<SensorSelectionScreen>
    with TickerProviderStateMixin {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final List<DiscoveredDevice> _devicesList = [];
  DiscoveredDevice? _selectedUserDevice;
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  late final HrmConnectionController _hrmController;
  StreamSubscription<HrmConnectionState>? _hrmStateSub;
  HrmConnectionState _hrmState = HrmConnectionState.disconnected;
  late final AnimationController _glowController;
  late final Animation<double> _glowOpacity;
  late final Animation<double> _glowScale;
  late final AnimationController _beatController;
  late final Animation<double> _beatScale;

  static const String _fakeDeviceId = '00:11:22:33:44:55';
  late String _workoutMode;

  @override
  void initState() {
    super.initState();
    _workoutMode = widget.workoutMode;
    _hrmController = HrmConnectionController(_ble);
    _hrmStateSub = _hrmController.stateStream.listen((state) {
      if (!mounted) return;
      setState(() => _hrmState = state);
      if (state == HrmConnectionState.connected) {
        _beatController.repeat();
      } else {
        _beatController.stop();
        _beatController.reset();
      }
    });
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _glowOpacity = Tween<double>(begin: 0.45, end: 0.85).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowScale = Tween<double>(begin: 0.94, end: 1.05).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _beatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _beatScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.22), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.22, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 12),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 12),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 46),
    ]).animate(_beatController);
    // Dummy device for testing
    setState(() {
      _devicesList.add(
        DiscoveredDevice(
          id: _fakeDeviceId,
          name: 'Fake HRM Device',
          serviceData: {},
          manufacturerData: Uint8List(0),
          rssi: -50,
          serviceUuids: [],
        ),
      );
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
    final statuses =
        await [
          Permission.location,
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ].request();
    return statuses.values.every((status) => status.isGranted);
  }

  void _startScan() {
    // Filter for the Heart Rate Service (UUID: 180D).
    final serviceUuid = Uuid.parse("180D");
    _scanSubscription = _ble
        .scanForDevices(
          withServices: [serviceUuid],
          scanMode: ScanMode.lowLatency,
        )
        .listen(
          (DiscoveredDevice device) {
            print(
              "Discovered device: ${device.name.isNotEmpty ? device.name : device.id}, RSSI: ${device.rssi}",
            );
            if (!_devicesList.any((d) => d.id == device.id)) {
              setState(() {
                _devicesList.add(device);
              });
            }
          },
          onError: (error) {
            print("Scan error: $error");
          },
        );
  }

  bool get _hasSelectedDevice => _selectedUserDevice != null;

  String get _selectedDeviceLabel {
    final device = _selectedUserDevice;
    if (device == null) return 'No sensor connected';

    final name = device.name.trim();
    return name.isNotEmpty ? name : device.id;
  }

  bool get _isConnected => _hrmState == HrmConnectionState.connected;

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _hrmStateSub?.cancel();
    _hrmController.dispose();
    _glowController.dispose();
    _beatController.dispose();
    super.dispose();
  }

  Future<void> _showDeviceSelectionMenu(bool forUser) async {
    final selected = await showModalBottomSheet<DiscoveredDevice>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        final devices = List<DiscoveredDevice>.unmodifiable(_devicesList);

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.surfacePrimary,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.strokeSoft),
              boxShadow: AppShadows.cardShadow,
            ),
            child:
                devices.isEmpty
                    ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bluetooth_searching_rounded,
                            color: AppColors.textSecondary,
                            size: 28,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Searching for heart rate monitors...',
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                    : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.textMuted,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select sensor',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: devices.length,
                            separatorBuilder:
                                (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final device = devices[index];
                              final title =
                                  device.name.trim().isNotEmpty
                                      ? device.name
                                      : device.id;

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.06),
                                    border: Border.all(
                                      color: AppColors.strokeSoft,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.favorite_border_rounded,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                title: Text(
                                  title,
                                  style: theme.textTheme.bodyLarge,
                                ),
                                subtitle: Text(
                                  'RSSI ${device.rssi}',
                                  style: theme.textTheme.labelMedium,
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textSecondary,
                                ),
                                onTap: () => Navigator.pop(context, device),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
          ),
        );
      },
    );
    if (selected != null) {
      setState(() {
        if (forUser) {
          _selectedUserDevice = selected;
        }
      });
      if (selected.id == _fakeDeviceId) {
        _hrmController.connectFake(selected.id);
      } else {
        _hrmController.connect(selected.id);
      }
    }
  }

  Future<void> _openChooseMode({required bool isHost}) async {
    if (!_hasSelectedDevice) return;
    _hrmController.disconnect();

    Navigator.pushNamed(
      context,
      '/chooseMode',
      arguments: <String, dynamic>{
        'userDeviceId': _selectedUserDevice!.id,
        'isHost': isHost,
        'workoutMode': _workoutMode,
      },
    );
  }

  void _startSoloWorkout() {
    if (!_hasSelectedDevice) return;
    _hrmController.disconnect();

    Navigator.pushNamed(
      context,
      '/radialGauge',
      arguments: <String, dynamic>{
        'userDeviceId': _selectedUserDevice!.id,
        'isOnline': false,
        'isHost': true,
        'workoutMode': _workoutMode,
        'isSoloWorkout': true,
      },
    );
  }

  Widget _buildSensorHero(ThemeData theme) {
    return Column(
      children: [
        Text(
          'YOUR SENSOR',
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.75),
            letterSpacing: 1.4,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _showDeviceSelectionMenu(true),
          child: SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (_hasSelectedDevice)
                  Positioned(
                    top: 22,
                    child: AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _glowScale.value,
                          child: Opacity(
                            opacity: _glowOpacity.value,
                            child: child,
                          ),
                        );
                      },
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
                        child: Container(
                          width: 196,
                          height: 196,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0x26FF6467),
                          ),
                        ),
                      ),
                    ),
                  ),
                Container(
                  width: 196,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                      width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: _isConnected
                        ? ScaleTransition(
                            scale: _beatScale,
                            child: SizedBox(
                              width: 64,
                              height: 64,
                              child: SvgPicture.asset(
                                'assets/icons/hearticon.svg',
                                colorFilter: const ColorFilter.mode(
                                  AppColors.red,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          )
                        : SizedBox(
                            width: 64,
                            height: 64,
                            child: SvgPicture.asset(
                              'assets/icons/hearticon.svg',
                              colorFilter: const ColorFilter.mode(
                                AppColors.red,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                  ),
                ),
                if (!_hasSelectedDevice)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: GestureDetector(
                      onTap: () => _showDeviceSelectionMenu(true),
                      child: Container(
                        width: 72,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.10),
                              Colors.white.withValues(alpha: 0.05),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: AppColors.white.withValues(alpha: 0.75),
                          size: 28,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child:
              _hasSelectedDevice
                  ? Column(
                    key: const ValueKey('connected'),
                    children: [
                      Text(
                        _selectedDeviceLabel,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary.withValues(alpha: 0.86),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Connected',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.green.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  )
                  : Text(
                    _selectedDeviceLabel,
                    key: const ValueKey('disconnected'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.red.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildSessionActionCard({
    required ThemeData theme,
    String? svgAsset,
    IconData? icon,
    required Color blurColor,
    required Color iconBackground,
    Color iconColor = AppColors.textPrimary,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;

    return Opacity(
      opacity: isEnabled ? 1 : 0.21,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 88,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardOverlaySoft.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.strokeSoft),
                    boxShadow: AppShadows.cardShadow,
                  ),
                ),
              ),
              Positioned(
                left: 6,
                top: 8,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: blurColor,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: Center(
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: iconBackground,
                          ),
                          child: Center(
                            child:
                                icon != null
                                    ? Icon(icon, color: iconColor, size: 24)
                                    : SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: SvgPicture.asset(svgAsset!),
                                    ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.pageBackground),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 160,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.orangeStrong.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 20),
                child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      height: 83,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                size: 20,
                              ),
                              color: AppColors.textPrimary,
                              splashRadius: 20,
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'New Session',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSensorHero(theme),
                    const SizedBox(height: 32),
                    _buildSessionActionCard(
                      theme: theme,
                      icon: Icons.person_outline_rounded,
                      blurColor: const Color(0x26FFD34D),
                      iconBackground: const Color(0x26FFD34D),
                      iconColor: const Color(0xFFFFE082),
                      title: 'Solo Session',
                      subtitle: 'Start your workout on your own',
                      onTap: _hasSelectedDevice ? _startSoloWorkout : null,
                    ),
                    const SizedBox(height: 10),
                    _buildSessionActionCard(
                      theme: theme,
                      svgAsset: 'assets/icons/createsessionicon.svg',
                      blurColor: const Color(0x26FF6467),
                      iconBackground: const Color(0x1AFF6467),
                      title: 'Create Paired Session',
                      subtitle: 'Start a workout and invite someone',
                      onTap:
                          _hasSelectedDevice
                              ? () => _openChooseMode(isHost: true)
                              : null,
                    ),
                    const SizedBox(height: 10),
                    _buildSessionActionCard(
                      theme: theme,
                      svgAsset: 'assets/icons/joinsessionicon.svg',
                      blurColor: const Color(0x262B7FFF),
                      iconBackground: const Color(0x1A2B7FFF),
                      title: 'Join Paired Session',
                      subtitle: 'Connect to a session someone else created',
                      onTap:
                          _hasSelectedDevice
                              ? () => _openChooseMode(isHost: false)
                              : null,
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                  ],
                ),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
