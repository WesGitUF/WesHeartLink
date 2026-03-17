import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:heart_link_app/app/theme/app_theme.dart';
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

  late String _workoutMode;

  @override
  void initState() {
    super.initState();
    _workoutMode = widget.workoutMode;
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

  bool get _hasSelectedDevice => _selectedUserDevice != null;

  String get _selectedDeviceLabel {
    final device = _selectedUserDevice;
    if (device == null) return 'No sensor connected';

    final name = device.name.trim();
    return name.isNotEmpty ? name : device.id;
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
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
            child: devices.isEmpty
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
                      Text('Select sensor', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: devices.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final device = devices[index];
                            final title =
                                device.name.trim().isNotEmpty ? device.name : device.id;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.06),
                                  border: Border.all(color: AppColors.strokeSoft),
                                ),
                                child: const Icon(
                                  Icons.favorite_border_rounded,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              title: Text(title, style: theme.textTheme.bodyLarge),
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
    }
  }

  Future<String?> _showModeDialog() {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);

        return AlertDialog(
          backgroundColor: AppColors.surfacePrimary,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: AppColors.strokeSoft),
          ),
          title: Text('Choose mode', style: theme.textTheme.titleMedium),
          content: Text(
            'Would you like to start in online or offline mode? '
            'Offline mode is not supported on iPhone.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'offline'),
              child: const Text('Offline'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'online'),
              child: const Text('Online'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openSession({required bool isHost}) async {
    if (!_hasSelectedDevice) return;

    final result = await _showModeDialog();
    if (result == null || !mounted) return;

    final isOnline = result == 'online';

    Navigator.pushNamed(
      context,
      '/radialGauge',
      arguments: {
        'userDeviceId': _selectedUserDevice!.id,
        'isOnline': isOnline,
        'isHost': isHost,
        'workoutMode': _workoutMode,
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
        const SizedBox(height: 22),
        GestureDetector(
          onTap: () => _showDeviceSelectionMenu(true),
          child: SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (_hasSelectedDevice)
                  Container(
                    width: 192,
                    height: 192,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0x14FF6467),
                    ),
                  ),
                Container(
                  width: 215,
                  height: 208,
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
                    child: SizedBox(
                      width: 72,
                      height: 72,
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
                    right: 22,
                    bottom: 18,
                    child: GestureDetector(
                      onTap: () => _showDeviceSelectionMenu(true),
                      child: Container(
                        width: 80,
                        height: 78,
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
                          size: 30,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _hasSelectedDevice
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
    required String svgAsset,
    required Color iconBackground,
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
        child: Container(
          height: 96,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: AppColors.cardOverlaySoft.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.strokeSoft),
            boxShadow: AppShadows.cardShadow,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconBackground,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: SvgPicture.asset(svgAsset),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
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
                              icon: const Icon(Icons.arrow_back_rounded, size: 20),
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
                    const SizedBox(height: 56),
                    _buildSensorHero(theme),
                    const Spacer(),
                    _buildSessionActionCard(
                      theme: theme,
                      svgAsset: 'assets/icons/createsessionicon.svg',
                      iconBackground: const Color(0x1AFF6467),
                      title: 'Create Session',
                      subtitle: 'Start a new workout',
                      onTap: _hasSelectedDevice
                          ? () => _openSession(isHost: true)
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _buildSessionActionCard(
                      theme: theme,
                      svgAsset: 'assets/icons/joinsessionicon.svg',
                      iconBackground: const Color(0x1A2B7FFF),
                      title: 'Join Session',
                      subtitle: 'Connect with others',
                      onTap: _hasSelectedDevice
                          ? () => _openSession(isHost: false)
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
