import 'dart:math';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:heart_link_app/app/theme/app_theme.dart';
import 'package:heart_link_app/screens/history/workoutdetail_screen.dart';
import 'package:heart_link_app/services/weather_service.dart';
import 'package:heart_link_app/services/workout_service.dart';
import 'package:heart_link_app/screens/history/history_repo.dart';
import 'package:heart_link_app/screens/heartratedial/hr.state.dart';
import 'package:heart_link_app/screens/history/history_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onTabVisible});
  final ValueNotifier<int> onTabVisible;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _UpcomingWorkoutCardData _upcomingWorkout =
      _UpcomingWorkoutCardData(
        title: 'HIIT Training',
        subtitle: 'High intensity interval workout',
        scheduledText: 'Today at 6:00 PM',
        durationText: '30 min',
        difficultyText: 'Hard',
        estimatedCaloriesText: '450',
      );

  // services
  final WeatherService _weatherService = WeatherService();
  final WorkoutService _workoutService = WorkoutService();

  // weather
  WeatherData? _weatherData;
  bool _isLoadingWeather = true;

  // workout
  List<HistoryEntry> _entries = [];
  bool _isLoadingWorkout = true;

  Map<String, dynamic>? _userData;
  bool _isLoadingUser = true;

  // display name (prefer Firestore)
  String get name {
    final firestoreName = _userData?['name'];
    if (firestoreName is String && firestoreName.trim().isNotEmpty) {
      return firestoreName.trim();
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userName = user.displayName;
      if (userName != null && userName.isNotEmpty) {
        return userName;
      }
    }

    return 'User';
  }

  // capitalize in the circle
  String get capitalize {
    final capitalize = name.trim();
    if (capitalize.isEmpty) return 'N';
    return capitalize[0].toUpperCase();
  }

  // greeting words
  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  String get _headerDateText {
    final now = DateTime.now();
    const weekdays = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final weekday = weekdays[now.weekday - 1];
    final month = months[now.month - 1];
    return '$weekday, $month ${now.day}';
  }

  String get _headerLocationText => 'Gainesville, FL';

  String get _headerTemperatureText {
    if (_isLoadingWeather) {
      return '--°F';
    }
    return '${_weatherData?.temperatureF ?? '--'}°F';
  }

  // only take the date
  DateTime _onlyDate(DateTime day) => DateTime(day.year, day.month, day.day);

  /// all entries from today
  List<HistoryEntry> get _todayEntries {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _entries.where((e) {
      final time = e.workout.start;
      return time.isAfter(start) && time.isBefore(end);
    }).toList();
  }

  // all entries from last 7 days
  List<HistoryEntry> get _weekEntries {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 6));
    return _entries.where((e) {
      final day = _onlyDate(e.workout.start);
      return !day.isBefore(start) && !day.isAfter(today);
    }).toList();
  }

  // Today's data (times, calories, average hr)
  String get todayTimeText {
    final totalSec = _todayEntries.fold<int>(
      0,
      (sum, e) => sum + e.workout.duration.inSeconds,
    );
    return _fmt(Duration(seconds: totalSec));
  }

  int get todayCalories =>
      _todayEntries.fold<int>(0, (sum, e) => sum + e.workout.calories);

  int get todayAvgHr {
    if (_todayEntries.isEmpty) return 0;
    final totalHr = _todayEntries.fold<int>(
      0,
      (sum, e) => sum + e.workout.avgHr,
    );
    return (totalHr / _todayEntries.length).round();
  }

  // Weekly Summary (workout times, average hr, total calories, total duration)
  int get weeklySessions => _weekEntries.length;

  int get weeklyCalories =>
      _weekEntries.fold<int>(0, (sum, e) => sum + e.workout.calories);

  Duration get weeklyDuration {
    final sec = _weekEntries.fold<int>(
      0,
      (sum, e) => sum + e.workout.duration.inSeconds,
    );
    return Duration(seconds: sec);
  }

  int get weeklyAvgHr {
    if (_weekEntries.isEmpty) return 0;
    final totalHr = _weekEntries.fold<int>(
      0,
      (sum, e) => sum + e.workout.avgHr,
    );
    return (totalHr / _weekEntries.length).round();
  }

  HistoryEntry? get _lastWorkoutEntry {
    if (_entries.isEmpty) return null;
    return _entries.first;
  }

  // weekly chart
  List<Map<String, dynamic>> get weeklyChartData {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<Map<String, dynamic>> out = [];

    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));

      final dayEntries = _entries.where((e) {
        return _onlyDate(e.workout.start) == day;
      }).toList();

      final minutes = dayEntries.fold<int>(
        0,
        (sum, e) => sum + e.workout.duration.inMinutes,
      );
      final avgHr = dayEntries.isEmpty
          ? 0
          : (dayEntries.fold<int>(0, (sum, e) => sum + e.workout.avgHr) /
                  dayEntries.length)
              .round();
      out.add({'minutes': minutes, 'avgHr': avgHr});
    }
    return out;
  }

  // average hr
  int get chartMaxHr {
    return hrState.maxHr;
  }

  // form the duration to hour and minute
  String _fmt(Duration d) {
    final hour = d.inHours;
    final minute = d.inMinutes.remainder(60);
    return '${hour}h ${minute}m';
  }

  String _formatCardDuration(Duration duration) {
    final totalMinutes = duration.inMinutes;
    if (totalMinutes >= 60 && totalMinutes % 60 == 0) {
      return '${totalMinutes ~/ 60} hr';
    }
    return '$totalMinutes min';
  }

  String _formatCompletedAgo(DateTime start) {
    final diff = DateTime.now().difference(start);
    if (diff.inMinutes < 1) {
      return 'Completed just now';
    }
    if (diff.inHours < 1) {
      final minutes = diff.inMinutes;
      return 'Completed $minutes min ago';
    }
    if (diff.inDays < 1) {
      final hours = diff.inHours;
      return 'Completed $hours hour${hours == 1 ? '' : 's'} ago';
    }
    final days = diff.inDays;
    return 'Completed $days day${days == 1 ? '' : 's'} ago';
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadWeather();
    _loadWorkouts();
    widget.onTabVisible.addListener(_onTabVisible);
  }

  @override
  void dispose() {
    widget.onTabVisible.removeListener(_onTabVisible);
    super.dispose();
  }

  void _onTabVisible() {
    if (HistoryRepo.instance.hasDeletions) {
      HistoryRepo.instance.clearDeletions();
      _loadWorkouts();
    }
  }

  // load weather
  Future<void> _loadWeather() async {
    try {
      final data = await _weatherService.fetchCurrent();
      if (!mounted) return;
      setState(() {
        _weatherData = data;
        _isLoadingWeather = false;
      });
    } catch (e) {
      debugPrint('Weather load error: $e');
      if (!mounted) return;
      setState(() {
        _weatherData = null;
        _isLoadingWeather = false;
      });
    }
  }

  Future<void> _loadWorkouts() async {
    try {
      final entries = await _workoutService.loadEntriesForCurrentUser();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _isLoadingWorkout = false;
      });
    } catch (e) {
      debugPrint('load workouts error: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingWorkout = false;
      });
    }
  }

  // load Firestore user document
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoadingUser = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      setState(() {
        _userData = doc.data();
        _isLoadingUser = false;
      });
    } catch (e) {
      debugPrint('User load error: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  // weather with icon
  IconData _mapConditionToIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.beach_access;
      case 'snow':
        return Icons.ac_unit;
      case 'thunderstorm':
        return Icons.flash_on;
      default:
        return Icons.wb_cloudy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.pageBackground),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 23, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HomeHeader(
                  greeting: '$_greeting, $name!',
                  dateText: _headerDateText,
                  locationText: _headerLocationText,
                  temperatureText: _headerTemperatureText,
                ),
                const SizedBox(height: 18),
                _LastWorkoutCard(
                  entry: _lastWorkoutEntry,
                  onTap:
                      _lastWorkoutEntry == null
                          ? null
                          : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (_) => WorkoutDetailScreen(
                                      workout: _lastWorkoutEntry!.workout,
                                      series: _lastWorkoutEntry!.series,
                                    ),
                              ),
                            );
                          },
                  durationText:
                      _lastWorkoutEntry == null
                          ? '-- min'
                          : _formatCardDuration(
                            _lastWorkoutEntry!.workout.duration,
                          ),
                  caloriesText:
                      _lastWorkoutEntry == null
                          ? '-- cal'
                          : '${_lastWorkoutEntry!.workout.calories} cal',
                  averageHeartRateText:
                      _lastWorkoutEntry == null
                          ? '-- bpm'
                          : '${_lastWorkoutEntry!.workout.avgHr} bpm',
                  completedText:
                      _lastWorkoutEntry == null
                          ? 'No workouts yet'
                          : _formatCompletedAgo(
                            _lastWorkoutEntry!.workout.start,
                          ),
                ),
                const SizedBox(height: 24),
                const _QuickActionsSection(),
                const SizedBox(height: 24),
                const _UpcomingWorkoutCard(data: _upcomingWorkout),
                const SizedBox(height: 24),
                _ExerciseRecord(
                  data: _isLoadingWorkout ? [] : weeklyChartData,
                  maxHr: chartMaxHr,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.greeting,
    required this.dateText,
    required this.locationText,
    required this.temperatureText,
  });

  final String greeting;
  final String dateText;
  final String locationText;
  final String temperatureText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    height: 2.0,
                    letterSpacing: 0.383,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0x80FFFFFF),
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    letterSpacing: -0.234,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 116.859,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  locationText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xB3FFFFFF),
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    letterSpacing: -0.15,
                  ),
                ),
                Text(
                  temperatureText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xB3FFFFFF),
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    height: 1.5,
                    letterSpacing: -0.449,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LastWorkoutCard extends StatelessWidget {
  const _LastWorkoutCard({
    required this.entry,
    required this.onTap,
    required this.durationText,
    required this.caloriesText,
    required this.averageHeartRateText,
    required this.completedText,
  });

  final HistoryEntry? entry;
  final VoidCallback? onTap;
  final String durationText;
  final String caloriesText;
  final String averageHeartRateText;
  final String completedText;

  @override
  Widget build(BuildContext context) {
    final workoutName = entry?.workout.type ?? 'Morning Run';

    return SizedBox(
      height: 176,
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0x0DFFFFFF)),
                    gradient: const LinearGradient(
                      begin: Alignment(-1.0, -0.1),
                      end: Alignment(1.0, 0.1),
                      colors: <Color>[Color(0x6617191C), Color(0x4D17191C)],
                      stops: <double>[0.0, 0.9766],
                    ),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x4D000000),
                        blurRadius: 32,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 40,
                top: 1.25,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
                  child: Container(
                    width: 38,
                    height: 128,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16777200),
                      color: const Color(0x332B7FFF),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: SizedBox(
                  width: 327,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 327,
                        child: Text(
                          'LAST WORKOUT',
                          style: TextStyle(
                            color: Color(0x99FFFFFF),
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            letterSpacing: 0.249,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 327,
                        height: 58,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 150.977,
                              height: 58,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 19.977),
                                    child: Text(
                                      workoutName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontFamily: 'Inter',
                                        fontSize: 22,
                                        fontWeight: FontWeight.w500,
                                        height: 1.5,
                                        letterSpacing: -0.258,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    completedText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0x80FFFFFF),
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      height: 1.5,
                                      letterSpacing: -0.15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: const Color(0x1A2B7FFF),
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: SvgPicture.asset(
                                    'assets/icons/blueicon.svg',
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.blue,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 327,
                        height: 21,
                        child: Row(
                          children: [
                            _WorkoutStat(
                              width: 68.516,
                              svgAsset: 'assets/icons/clockicon.svg',
                              iconColor: const Color(0x66FFFFFF),
                              value: durationText,
                            ),
                            const SizedBox(width: 24),
                            _WorkoutStat(
                              width: 72.227,
                              svgAsset: 'assets/icons/fireicon.svg',
                              iconColor: const Color(0xB3FF8904),
                              value: caloriesText,
                            ),
                            const SizedBox(width: 24),
                            _WorkoutStat(
                              width: 67.328,
                              icon: Icons.favorite_outline,
                              iconColor: Colors.redAccent,
                              value: averageHeartRateText,
                            ),
                          ],
                        ),
                      ),
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

class _WorkoutStat extends StatelessWidget {
  const _WorkoutStat({
    required this.width,
    required this.iconColor,
    required this.value,
    this.icon,
    this.svgAsset,
  });

  final double width;
  final IconData? icon;
  final Color iconColor;
  final String value;
  final String? svgAsset;

  @override
  Widget build(BuildContext context) {
    final leading =
        svgAsset != null
            ? SvgPicture.asset(
              svgAsset!,
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            )
            : Icon(icon, size: 16, color: iconColor);

    return SizedBox(
      width: width,
      height: 21,
      child: Row(
        children: [
          leading,
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                color: Color(0xB3FFFFFF),
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
                letterSpacing: -0.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    void showComingSoon(String label) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('WIP'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK ACTIONS',
          style: TextStyle(
            color: Color(0x99FFFFFF),
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.5,
            letterSpacing: 0.249,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: Row(
            children: [
              Expanded(
                child: _QuickActionTile(
                  label: 'Progress',
                  svgAsset: 'assets/icons/progressicon.svg',
                  iconColor: AppColors.greenStrong,
                  iconBackground: const Color(0x1A00C950),
                  onTap: () => showComingSoon('Progress'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _QuickActionTile(
                  label: 'Plan',
                  svgAsset: 'assets/icons/planicon.svg',
                  iconColor: AppColors.blue,
                  iconBackground: AppColors.blueSoft,
                  onTap: () => showComingSoon('Plan'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _QuickActionTile(
                  label: 'Calendar',
                  svgAsset: 'assets/icons/calendaricon.svg',
                  iconColor: AppColors.purpleStrong,
                  iconBackground: const Color(0x1AAD46FF),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const WorkoutCalendarScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.label,
    required this.svgAsset,
    required this.iconColor,
    required this.iconBackground,
    required this.onTap,
  });

  final String label;
  final String svgAsset;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.strokeSoft),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0x5217191C), Color(0x3D17191C)],
          stops: <double>[0.0266, 0.9709],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: SvgPicture.asset(
                        svgAsset,
                        colorFilter: ColorFilter.mode(
                          iconColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xB3FFFFFF),
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    letterSpacing: -0.076,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpcomingWorkoutCardData {
  const _UpcomingWorkoutCardData({
    required this.title,
    required this.subtitle,
    required this.scheduledText,
    required this.durationText,
    required this.difficultyText,
    required this.estimatedCaloriesText,
  });

  final String title;
  final String subtitle;
  final String scheduledText;
  final String durationText;
  final String difficultyText;
  final String estimatedCaloriesText;
}

class _UpcomingWorkoutCard extends StatelessWidget {
  const _UpcomingWorkoutCard({required this.data});

  final _UpcomingWorkoutCardData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 239,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.strokeSoft),
                gradient: const LinearGradient(
                  begin: Alignment(-0.9, -0.5),
                  end: Alignment(1.0, 0.9),
                  colors: <Color>[Color(0x6617191C), Color(0x4D17191C)],
                  stops: <double>[0.036, 1.0],
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x4D000000),
                    blurRadius: 32,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 90.5,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16777200),
                  color: const Color(0x26FF6467),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TODAY'S UPCOMING WORKOUT",
                  style: TextStyle(
                    color: Color(0x99FFFFFF),
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    letterSpacing: 0.249,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontFamily: 'Inter',
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                              letterSpacing: -0.258,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0x80FFFFFF),
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                              letterSpacing: -0.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            Color(0x33FF6900),
                            Color(0x33FB2C36),
                          ],
                        ),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: SvgPicture.asset(
                            'assets/icons/orangeicon.svg',
                            colorFilter: const ColorFilter.mode(
                              AppColors.orange,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Color(0xB3FFFFFF),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      data.scheduledText,
                      style: const TextStyle(
                        color: Color(0xB3FFFFFF),
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        letterSpacing: -0.15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.05),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Expanded(
                      child: _UpcomingWorkoutMetric(
                        label: 'DURATION',
                        value: data.durationText,
                      ),
                    ),
                    const _MetricDivider(),
                    Expanded(
                      child: _UpcomingWorkoutMetric(
                        label: 'DIFFICULTY',
                        value: data.difficultyText,
                        valueColor: AppColors.orange,
                      ),
                    ),
                    const _MetricDivider(),
                    Expanded(
                      child: _UpcomingWorkoutMetric(
                        label: 'EST. CAL',
                        value: data.estimatedCaloriesText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingWorkoutMetric extends StatelessWidget {
  const _UpcomingWorkoutMetric({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0x66FFFFFF),
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w400,
            height: 1.5,
            letterSpacing: 0.34,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: valueColor,
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.5,
            letterSpacing: -0.234,
          ),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white.withOpacity(0.1),
    );
  }
}

// Weather card
class _WeatherNow extends StatelessWidget {
  final IconData icon;
  final int temperatureF;
  final String condition;

  const _WeatherNow({
    super.key,
    required this.icon,
    required this.temperatureF,
    required this.condition,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: const Color.fromARGB(255, 245, 106, 26)),
          const SizedBox(height: 8),
          Text(
            '$temperatureF°F',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(condition, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// today's data
class _TodayData extends StatelessWidget {
  final String label;
  final String value;
  const _TodayData({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// weekly summary card
class _WeeklySummaryCard extends StatelessWidget {
  final int sessions;
  final int avgHr;
  final int kcal;
  final String durationText;

  const _WeeklySummaryCard({
    super.key,
    required this.sessions,
    required this.avgHr,
    required this.kcal,
    required this.durationText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 24,
              runSpacing: 10,
              children: [
                _SummaryChip(title: 'Workouts', value: '$sessions'),
                _SummaryChip(title: 'Average HR', value: '$avgHr bpm'),
                _SummaryChip(title: 'Total Calories', value: '$kcal kcal'),
                _SummaryChip(title: 'Total Duration', value: durationText),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// summary chip widget
class _SummaryChip extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryChip({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color.fromARGB(137, 236, 227, 227),
            ),
          ),
        ],
      ),
    );
  }
}

// exercise record chart widget
class _ExerciseRecord extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final int maxHr;

  const _ExerciseRecord({super.key, required this.data, required this.maxHr});

  // zone colors
  static const Color _grey = Color(0xFF666A70);
  static const Color _blue = Color(0xFF2F6BDA);
  static const Color _green = Color(0xFF66B35B);
  static const Color _orange = Color(0xFFF3A43B);
  static const Color _red = Color(0xFFE25353);

  Color _zoneColor(int bpm) {
    if (maxHr <= 0) return _grey;
    final p = bpm / maxHr;
    if (p < 0.65) return _grey;
    if (p < 0.80) return _blue;
    if (p < 0.89) return _green;
    if (p < 0.95) return _orange;
    return _red;
  }

  // generate past 7 days labels
  List<String> _pastNDaysLabels(int count) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<String> labels = [];
    for (int i = count - 1; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      labels.add('${months[d.month - 1]} ${d.day}');
    }
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    final minutes = data.map((e) => (e['minutes'] as int?) ?? 0).toList();
    final avgHrs = data.map((e) => (e['avgHr'] as int?) ?? 0).toList();
    // calculate Y axis max minutes (rounded up to nearest 30)
    final int maxMin = minutes.fold<int>(0, (m, v) => v > m ? v : m);
    int yMax = ((maxMin + 29) ~/ 30) * 30;
    if (yMax < 60) yMax = 60;

    // generate Y axis ticks
    final ticks = List<int>.generate(yMax ~/ 30 + 1, (i) => i * 30);

    // generate X axis labels (past N days)
    final xLabels = _pastNDaysLabels(data.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Exercise Record',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // y axis labels
              SizedBox(
                width: 48,
                child: LayoutBuilder(
                  builder: (context, c) {
                    final chartHeight = c.maxHeight - 30;
                    return Stack(
                      children: [
                        ...List.generate(ticks.length, (i) {
                          final t = yMax == 0 ? 0.0 : ticks[i] / yMax;
                          final y = (1 - t) * chartHeight;

                          final dy = (ticks[i] == 0) ? -8.0 : 0.0;

                          return Positioned(
                            top: (y + dy).clamp(0.0, chartHeight),
                            left: 0,
                            right: 0,
                            child: Text(
                              '${ticks[i]}min',
                              textAlign: TextAlign.right,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color.fromARGB(185, 236, 227, 227),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),

              // chart area
              Expanded(
                child: _ExerciseAreaChart(
                  data: data,
                  yMaxMinutes: yMax,
                  xLabels: xLabels,
                  avgHrs: avgHrs,
                  zoneColorOf: _zoneColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// exercise area chart painter
class _ExerciseAreaChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final int yMaxMinutes;
  final List<String> xLabels;
  final List<int> avgHrs;
  final Color Function(int bpm) zoneColorOf;

  const _ExerciseAreaChart({
    super.key,
    required this.data,
    required this.yMaxMinutes,
    required this.xLabels,
    required this.avgHrs,
    required this.zoneColorOf,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = data.map((e) => (e['minutes'] as int?) ?? 0).toList();

    return LayoutBuilder(
      builder: (context, c) {
        const chartL = 6.0, chartR = 10.0, chartT = 8.0, chartB = 34.0;
        final w = (c.maxWidth - chartL - chartR).clamp(1.0, 10000.0);
        final h = (c.maxHeight - chartT - chartB).clamp(1.0, 10000.0);

        double xFor(int i) {
          final n = data.length;
          if (n <= 1) return chartL + w / 2;
          return chartL + (w * (i / (n - 1)));
        }

        double yForMinutes(int m) {
          if (yMaxMinutes <= 0) return chartT + h;
          final t = (m / yMaxMinutes).clamp(0.0, 1.0);
          return chartT + (1 - t) * h;
        }

        final pts = <Offset>[];
        for (int i = 0; i < data.length; i++) {
          pts.add(Offset(xFor(i), yForMinutes(minutes[i])));
        }

        final gridYs = <double>[];
        for (int mm = 0; mm <= yMaxMinutes; mm += 30) {
          gridYs.add(yForMinutes(mm));
        }

        return CustomPaint(
          painter: _AreaStrokePainter(
            points: pts,
            avgHrs: avgHrs,
            zoneColorOf: zoneColorOf,
            left: chartL,
            right: chartL + w,
            top: chartT,
            bottom: chartT + h,
            xLabels: xLabels,
          ),
        );
      },
    );
  }
}

// Calendar Screen Widget
class WorkoutCalendarScreen extends StatefulWidget {
  const WorkoutCalendarScreen({super.key});

  @override
  State<WorkoutCalendarScreen> createState() => _WorkoutCalendarScreenState();
}

class _WorkoutCalendarScreenState extends State<WorkoutCalendarScreen> {
  bool _loading = true;
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Set<DateTime> _workoutDays = {};

  @override
  void initState() {
    super.initState();
    _loadWorkoutDays();
  }

  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _loadWorkoutDays() async {
    try {
      await HistoryRepo.instance.loadFromCloud();
      final entries = HistoryRepo.instance.entries;

      final days = entries.map((e) => _onlyDate(e.workout.start)).toSet();

      if (!mounted) return;
      setState(() {
        _workoutDays = days;
        _loading = false;
      });
    } catch (e) {
      debugPrint('calendar load error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  bool _hasWorkout(DateTime day) {
    return _workoutDays.contains(_onlyDate(day));
  }

  void _goToPreviousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  void _openDayHistory(DateTime day) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistoryScreen(filterDate: day),
      ),
    );
  }

  String _monthLabel(DateTime month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[month.month - 1]} ${month.year}';
  }

  List<DateTime> _buildCalendarDays(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    final startOffset = firstDayOfMonth.weekday % 7; // Sunday = 0
    final firstGridDay = firstDayOfMonth.subtract(Duration(days: startOffset));

    final totalDays =
    ((startOffset + lastDayOfMonth.day) <= 35) ? 35 : 42;

    return List.generate(
      totalDays,
          (index) => firstGridDay.add(Duration(days: index)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _buildCalendarDays(_focusedMonth);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Workout Calendar'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.pageBackground,
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.strokeSoft),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0x5217191C),
                      Color(0x3D17191C),
                    ],
                    stops: <double>[0.0266, 0.9709],
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _goToPreviousMonth,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        _monthLabel(_focusedMonth),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _goToNextMonth,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: const [
                  Expanded(child: Center(child: Text('Sun', style: TextStyle(color: Colors.white54)))),
                  Expanded(child: Center(child: Text('Mon', style: TextStyle(color: Colors.white54)))),
                  Expanded(child: Center(child: Text('Tue', style: TextStyle(color: Colors.white54)))),
                  Expanded(child: Center(child: Text('Wed', style: TextStyle(color: Colors.white54)))),
                  Expanded(child: Center(child: Text('Thu', style: TextStyle(color: Colors.white54)))),
                  Expanded(child: Center(child: Text('Fri', style: TextStyle(color: Colors.white54)))),
                  Expanded(child: Center(child: Text('Sat', style: TextStyle(color: Colors.white54)))),
                ],
              ),

              const SizedBox(height: 10),

              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: days.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final isCurrentMonth =
                        day.month == _focusedMonth.month;
                    final isToday = day == todayOnly;
                    final hasWorkout = _hasWorkout(day);

                    return GestureDetector(
                      onTap: () => _openDayHistory(day),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isToday
                                ? AppColors.redStrong
                                : AppColors.strokeSoft,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isCurrentMonth
                                ? const [
                              Color(0x5217191C),
                              Color(0x3D17191C),
                            ]
                                : const [
                              Color(0x2217191C),
                              Color(0x1817191C),
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 8,
                              left: 10,
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: isCurrentMonth
                                      ? AppColors.textSecondary
                                      : AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (hasWorkout)
                              const Positioned(
                                bottom: 8,
                                right: 8,
                                child: Icon(
                                  Icons.favorite,
                                  color: Colors.redAccent,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.favorite, color: Colors.redAccent, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Workout completed on this day',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AreaStrokePainter extends CustomPainter {
  final List<Offset> points;
  final List<int> avgHrs;
  final List<String> xLabels;
  final double left, right, top, bottom;
  final Color Function(int bpm) zoneColorOf;

  _AreaStrokePainter({
    required this.points,
    required this.avgHrs,
    required this.xLabels,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.zoneColorOf,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // x axis baseline
    canvas.drawLine(
      Offset(left, bottom),
      Offset(right, bottom),
      Paint()
        ..color = Colors.black.withValues()
        ..strokeWidth = 2,
    );

    if (points.length >= 2) {
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);

        final segColor = zoneColorOf(avgHrs[i]);

        final path = Path()
          ..moveTo(p0.dx, p0.dy)
          ..quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy)
          ..quadraticBezierTo(p1.dx, p1.dy, p1.dx, p1.dy);

        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3
          ..color = segColor;

        canvas.drawPath(path, paint);
      }
    }

    // plot dots with avgHr labels
    final dotPaint = Paint()..color = const Color.fromARGB(221, 92, 82, 82);
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      canvas.drawCircle(p, 3.5, dotPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: '${avgHrs[i]}',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            shadows: [Shadow(blurRadius: 2, color: Colors.black26)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - tp.height - 6));
    }

    // x axis labels
    final n = xLabels.length;
    if (n > 0) {
      final step = (right - left) / (n - 1 == 0 ? 1 : (n - 1));
      for (int i = 0; i < n; i++) {
        final label = xLabels[i];
        final x = n == 1 ? (left + right) / 2 : left + i * step;
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 12,
              color: Color.fromARGB(180, 236, 227, 227),
              fontWeight: FontWeight.w600,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, bottom + 18));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AreaStrokePainter old) {
    return points != old.points ||
        avgHrs != old.avgHrs ||
        xLabels != old.xLabels ||
        left != old.left ||
        right != old.right ||
        top != old.top ||
        bottom != old.bottom ||
        zoneColorOf != old.zoneColorOf;
  }
}
