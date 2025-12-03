import 'package:flutter/material.dart';
import 'package:heart_link_app/screens/history/workoutdetail_screen.dart';
import 'package:heart_link_app/screens/history/history_repo.dart';

// simple workout data class
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

class HistoryScreen extends StatefulWidget {
  final DateTime? filterDate;
  const HistoryScreen({super.key, this.filterDate});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // check if it loading from firebase
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory(); // when the screen open it will pull the history data from firebase
  }

  // load data from historyrepo(invoke firebase)
  Future<void> _loadHistory() async {
    await HistoryRepo.instance.loadFromCloud();
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  // get only date
  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  // apply filterdate to put to history list
  List<HistoryEntry> _filteredEntries(List<HistoryEntry> all) {
    if (widget.filterDate == null) return all;
    final target = _onlyDate(widget.filterDate!);
    return all.where((e) {
      final d = _onlyDate(e.workout.start);
      return d == target;
    }).toList();
  }

  // format datetime
  String _hm(DateTime dt) {
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$mm/$dd  $hh:$mi';
  }

  // format duration
  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0 ? '${h}h ${m}m' : '${m}m ${s}s';
  }

  // icon for workout type
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

  // select color for workout type
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

  // title for selected day history
  String _title() {
    if (widget.filterDate == null) return 'History';
    final d = widget.filterDate!;
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return 'History  $mm/$dd';
  }

  @override
  Widget build(BuildContext context) {
    // loading state from firebase
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(_title())),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // once load, listen to historyrepo update
    return AnimatedBuilder(
      animation: HistoryRepo.instance,
      builder: (context, _) {
        final all = HistoryRepo.instance.entries;
        final items = _filteredEntries(all);
        return Scaffold(
          appBar: AppBar(title: Text(_title())),
          body: items.isEmpty
              ? Center(
                  child: Text(
                    widget.filterDate == null
                        ? 'No sessions yet'
                        : 'No sessions on this day',
                    style: const TextStyle(fontSize: 16),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _workoutTile(context, items[i]),
                ),
        );
      },
    );
  }

  // single workout tile with delete button
  Widget _workoutTile(BuildContext context, HistoryEntry entry) {
    final w = entry.workout;
    final c = _colorFor(context, w.type);
    final scheme = Theme.of(context).colorScheme;

    final titleColor = scheme.onSurface;
    final subColor = scheme.onSurfaceVariant;

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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _hm(w.start),
              style: TextStyle(color: subColor),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _pill(
                  icon: Icons.favorite_rounded,
                  label: 'Avg',
                  value: '${w.avgHr} bpm',
                  color: const Color.fromARGB(255, 160, 52, 52),
                ),
                _pill(
                  icon: Icons.timer_rounded,
                  label: 'time',
                  value: _fmt(w.duration),
                  color: Colors.blueGrey,
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  title: const Text('Delete Workout?'),
                  content: const Text('Are you sure you want to delete this workout? This cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                );
              },
            );
            
            if (confirm == true) {
              await HistoryRepo.instance.delete(entry);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${w.type} workout deleted'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            }
          },
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WorkoutDetailScreen(
                workout: w,
                series: entry.series,
              ),
            ),
          );
        },
      ),
    );
  }

  // single pill widget
  Widget _pill({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }
}