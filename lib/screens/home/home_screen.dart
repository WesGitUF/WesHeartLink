import 'dart:math';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:heart_link_app/app/theme/app_theme.dart';
import 'package:heart_link_app/services/weather_service.dart';
import 'package:heart_link_app/services/workout_service.dart';
import 'package:heart_link_app/screens/history/history_screen.dart';
import 'package:heart_link_app/screens/history/history_repo.dart';
import 'package:heart_link_app/screens/heartratedial/hr.state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onTabVisible});
  final ValueNotifier<int> onTabVisible;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
                const SizedBox(height: 14),
                _WeekCalender(
                  onDayTapped: (selectedDate) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HistoryScreen(filterDate: selectedDate),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _TodayDateLine(),
                const SizedBox(height: 18),
                _WeeklySummaryCard(
                  sessions: weeklySessions,
                  avgHr: weeklyAvgHr,
                  kcal: weeklyCalories,
                  durationText: _fmt(weeklyDuration),
                ),
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

// exercise record
class _TodayDateLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const listweekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const listmonths = [
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
    final weekday = listweekDays[(now.weekday - 1).clamp(0, 6)];
    final month = listmonths[now.month - 1];
    final day = now.day;

    return Text(
      '$weekday, $month $day',
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: const Color.fromARGB(137, 229, 220, 220),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _WeekCalender extends StatelessWidget {
  const _WeekCalender({super.key, required this.onDayTapped});

  // Called when a day is tapped
  final void Function(DateTime date) onDayTapped;
  final List<String> _weekLetters = const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // DateTime.weekday
    final weekIndexToday = today.weekday % 7;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_weekLetters.length, (i) {
        final isToday = (weekIndexToday == i);
        final deltaDays = i - weekIndexToday;
        final dayDate = today.add(Duration(days: deltaDays));

        return GestureDetector(
          onTap: () => onDayTapped(dayDate),
          child: Column(
            children: [
              Text(
                _weekLetters[i],
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isToday
                      ? const Color.fromARGB(255, 55, 49, 45)
                      : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isToday
                        ? const Color.fromARGB(255, 107, 99, 121)
                        : Colors.black54,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday
                          ? const Color.fromARGB(255, 115, 196, 209)
                          : Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
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