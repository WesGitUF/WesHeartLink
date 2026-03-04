import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:heart_link_app/screens/history/workoutdetail_screen.dart';
import 'package:heart_link_app/screens/history/history_repo.dart';

// simple workout data class
class Workout {
  final String type;
  final DateTime start;
  final Duration duration;
  final int avgHr;
  final int calories;

  final int? maxSessionHr;
  final int? theoreticalMaxHr;
  final String? topZone;

  const Workout({
    required this.type,
    required this.start,
    required this.duration,
    required this.avgHr,
    required this.calories,
    this.maxSessionHr,
    this.theoreticalMaxHr,
    this.topZone,
  });
}

class HistoryScreen extends StatefulWidget {
  final DateTime? filterDate;
  final ValueNotifier<int>? onTabVisible;
  const HistoryScreen({super.key, this.filterDate, this.onTabVisible});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  // check if it loading from firebase
  bool _loading = true;
  bool _showSwipeHint = false;

  late final AnimationController _nudgeCtl;
  late final Animation<Offset> _nudgeOffset;

  // show the swipe hint every 2 weeks
  static const _kHintIntervalMs = 14 * 24 * 60 * 60 * 1000; // 2 weeks

  String get _kHintKey {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    return 'swipe_hint_last_shown_$uid';
  }

  @override
  void initState() {
    super.initState();
    _nudgeCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _nudgeOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.15, 0),
    ).animate(CurvedAnimation(parent: _nudgeCtl, curve: Curves.easeInOut));
    _loadHistory();
    widget.onTabVisible?.addListener(_onTabVisible);
  }

  @override
  void dispose() {
    widget.onTabVisible?.removeListener(_onTabVisible);
    _nudgeCtl.dispose();
    super.dispose();
  }

  Future<void> _onTabVisible() async {
    if (!mounted) return;
    final sp = await SharedPreferences.getInstance();
    final lastShown = sp.getInt(_kHintKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final items = _filteredEntries(HistoryRepo.instance.entries);
    final shouldNudge = items.isNotEmpty && (now - lastShown >= _kHintIntervalMs);
    if (!shouldNudge || !mounted) return;
    await sp.setInt(_kHintKey, now);
    setState(() => _showSwipeHint = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _playNudge());
  }

  // load data from historyrepo(invoke firebase)
  Future<void> _loadHistory() async {
    try {
      await HistoryRepo.instance.loadFromCloud()
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // network unavailable or timed out — proceed with cached entries
    }
    if (!mounted) return;

    // check if interval has passed since last swipe hint
    final sp = await SharedPreferences.getInstance();
    final lastShown = sp.getInt(_kHintKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final items = _filteredEntries(HistoryRepo.instance.entries);
    final shouldNudge = items.isNotEmpty && (now - lastShown >= _kHintIntervalMs);

    if (shouldNudge) await sp.setInt(_kHintKey, now);

    setState(() {
      _loading = false;
      _showSwipeHint = shouldNudge;
    });

    if (shouldNudge) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _playNudge());
    }
  }

  // peek the first tile left then bounce back
  Future<void> _playNudge() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted || !_showSwipeHint) return;
    await _nudgeCtl.forward();
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await _nudgeCtl.reverse();
    if (mounted) setState(() => _showSwipeHint = false);
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
  String _hm(BuildContext context, DateTime dt) {

    final mq = MediaQuery.of(context);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(dt),
      alwaysUse24HourFormat: mq.alwaysUse24HourFormat,
    );
    final mm = dt.month;
    final dd = dt.day;
    return '$mm/$dd  $time';
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
                  itemBuilder: (context, i) =>
                      _workoutTile(context, items[i], nudge: i == 0 && _showSwipeHint),
                ),
        );
      },
    );
  }

  // single workout tile
  Widget _workoutTile(BuildContext context, HistoryEntry entry, {bool nudge = false}) {
    final w = entry.workout;
    final c = _colorFor(context, w.type);
    final scheme = Theme.of(context).colorScheme;

    final titleColor = scheme.onSurface;
    final subColor = scheme.onSurfaceVariant;
    final maxChipWidth = MediaQuery.of(context).size.width * 0.50;

    final card = Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
          _hm(context,w.start),
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
                icon: Icons.timer_rounded,
                label: 'time',
                value: _fmt(w.duration),
                color: Colors.blueGrey,
              ),
            ],
          ),
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

    final dismissible = Dismissible(
      key: ValueKey(entry.id ?? '${w.type}_${w.start.millisecondsSinceEpoch}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('Delete workout?'),
              content: const Text('This session will be removed permanently.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ?? false;
      },
      onDismissed: (_) {
        HistoryRepo.instance.delete(entry);
      },
      child: card,
    );

    if (!nudge) return dismissible;

    // nudge: stack red background behind + animate the card sliding left
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white, size: 28),
          ),
        ),
        AnimatedBuilder(
          animation: _nudgeCtl,
          builder: (context, child) {
            return FractionalTranslation(
              translation: _nudgeOffset.value,
              child: child,
            );
          },
          child: dismissible,
        ),
      ],
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
            style:
                TextStyle(fontSize: 11, color: color.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }
}