import 'package:flutter/material.dart';

// one workout session
class Workout {
  final String type;
  final DateTime start;
  final Duration duration;
  final int avgHr;
  final int calories;

  const Workout({
    required this.type,
    required this.start,
    required this.duration,
    required this.avgHr,
    required this.calories,
  });
}

/// Mock history data
final List<Workout> _mock = [
  Workout(
    type: 'Running',
    start: DateTime.now().subtract(const Duration(hours: 4)),
    duration: const Duration(minutes: 32, seconds: 18),
    avgHr: 137,
    calories: 286,
  ),
  Workout(
    type: 'Walking',
    start: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    duration: const Duration(minutes: 41),
    avgHr: 98,
    calories: 160,
  ),
  Workout(
    type: 'Cycling',
    start: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
    duration: const Duration(minutes: 55, seconds: 20),
    avgHr: 122,
    calories: 410,
  ),
  Workout(
    type: 'Swimming',
    start: DateTime.now().subtract(const Duration(days: 3, hours: 1)),
    duration: const Duration(minutes: 28, seconds: 12),
    avgHr: 132,
    calories: 220,
  ),
];

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // Format
  String _hm(DateTime dt) {
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$mm/$dd  $hh:$mi';
  }

  // Format duration 
  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0 ? '${h}h ${m}m' : '${m}m ${s}s';
  }

  // Map workout type to an icon
  IconData _iconFor(String type) {
    switch (type.toLowerCase()) {
      case 'running':
        return Icons.directions_run_rounded;
      case 'walking':
        return Icons.directions_walk_rounded;
      case 'cycling':
        return Icons.pedal_bike_rounded;
      case 'swimming':
        return Icons.pool_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }

  // Accent color by workout type (fallback to theme primary)
  Color _colorFor(BuildContext context, String type) {
    final scheme = Theme.of(context).colorScheme;
    switch (type.toLowerCase()) {
      case 'running':
        return Colors.redAccent;
      case 'walking':
        return Colors.green;
      case 'cycling':
        return Colors.indigo;
      case 'swimming':
        return Colors.teal;
      default:
        return scheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    // newest first
    final items = [..._mock]..sort((a, b) => b.start.compareTo(a.start));

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _workoutTile(context, items[i]),
      ),
    );
  }

  /// One session row 
  Widget _workoutTile(BuildContext context, Workout w) {
    final c = _colorFor(context, w.type);
    final scheme = Theme.of(context).colorScheme;

    final titleColor = scheme.onSurface;
    final subColor = scheme.onSurfaceVariant;

    final maxChipWidth = MediaQuery.of(context).size.width * 0.50;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: c.withOpacity(0.12), 
          foregroundColor: c,
          child: Icon(_iconFor(w.type)),
        ),
        title: Text(
          w.type,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
        subtitle: Text(
          _hm(w.start),
          style: TextStyle(color: subColor),
        ),
        trailing: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxChipWidth),
          child: Wrap(
            spacing: 5,
            runSpacing: 5,
            alignment: WrapAlignment.end,
            children: [
              _pill(
                icon: Icons.favorite_rounded,
                label: 'Avg',
                value: '${w.avgHr} bpm',
                color: const Color.fromARGB(255, 160, 52, 52),
              ),
              _pill(
                icon: Icons.local_fire_department_rounded,
                label: 'kcal',
                value: '${w.calories}',
                color: const Color.fromARGB(255, 216, 126, 56),
              ),
              _pill(
                icon: Icons.timer_rounded,
                label: 'time',
                value: _fmt(w.duration),
                color: Colors.blueGrey,
              ),
            ],
          ),
        ),
        onTap: () {},
      ),
    );
  }

  /// icon + value + label
  Widget _pill({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }
}