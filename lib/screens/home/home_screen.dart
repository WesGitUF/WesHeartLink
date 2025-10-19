import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // mock weekly numbers
  int get _weeklySessions => 4;
  int get _weeklyAvgHr => 122;
  int get _weeklyKcal => 1076;
  Duration get _weeklyDur => const Duration(hours: 2, minutes: 36);

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m}m';
  }

  // mock weather
  final _todayWeather =
      (icon: Icons.wb_sunny_rounded, tempC: 24, condition: 'Sunny');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 40, 40, 41),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 23, 21, 21),
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: avatar + greeting
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black87, width: 3),
                      color: const Color.fromARGB(255, 211, 174, 174),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Good morning\nTongshan!',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Week strip + today date
              const _WeekStrip(),
              const SizedBox(height: 8),
              _TodayDateLine(),
              const SizedBox(height: 18),

              // Today section title
              Text(
                'Today',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),

              // Weather + Today's workout data
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _WeatherNow(
                    icon: _todayWeather.icon,
                    tempC: _todayWeather.tempC,
                    condition: _todayWeather.condition,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MetricLine(label: 'Times', value: '1h 15m'),
                        SizedBox(height: 10),
                        _MetricLine(label: 'Calories', value: '480 kcal'),
                        SizedBox(height: 10),
                        _MetricLine(label: 'Average HR', value: '115 bpm'),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Weekly summary card
              _WeeklySummaryCard(
                sessions: _weeklySessions,
                avgHr: _weeklyAvgHr,
                kcal: _weeklyKcal,
                durationText: _fmt(_weeklyDur),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayDateLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const wds = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const mns = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final wd = wds[(now.weekday - 1).clamp(0, 6)];
    final mon = mns[now.month - 1];
    final day = now.day;

    return Text(
      '$wd, $mon $day',
      style: Theme.of(context)
          .textTheme
          .bodyLarge
          ?.copyWith(color: const Color.fromARGB(137, 229, 220, 220), fontWeight: FontWeight.w600),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({super.key});
  final List<String> _weekLetters = const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_weekLetters.length, (i) {
        final isToday = (today.weekday % 7) == i;
        return Column(
          children: [
            Text(
              _weekLetters[i],
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isToday ? const Color.fromARGB(255, 55, 49, 45) : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isToday ? const Color.fromARGB(255, 107, 99, 121) : Colors.black54,
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isToday ? const Color.fromARGB(255, 115, 196, 209) : Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _WeatherNow extends StatelessWidget {
  final IconData icon;
  final int tempC;
  final String condition;
  const _WeatherNow({
    super.key,
    required this.icon,
    required this.tempC,
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
          Text('$tempC°C',
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(condition,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  final String label;
  final String value;
  const _MetricLine({super.key, required this.label, required this.value});

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
            style:
                const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
          ),
        ),
        const SizedBox(width: 10),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

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
            const Text('Weekly Summary',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(title,
              style: const TextStyle(fontSize: 12, color: Color.fromARGB(137, 236, 227, 227))),
        ],
      ),
    );
  }
}