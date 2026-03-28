import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:heart_link_app/screens/history/workoutdetail_screen.dart';
import 'package:heart_link_app/screens/history/history_repo.dart';
import 'package:heart_link_app/app/theme/app_theme.dart';

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

  final Map<String, _ExerciseStyle> _exerciseStyles = {
    'running': _ExerciseStyle('🏃', AppColors.green, const Color(0x2605DF72)),
    'cycling': _ExerciseStyle('🚴', AppColors.blue, const Color(0x2651A2FF)),
    'hiit': _ExerciseStyle('⚡', AppColors.orange, const Color(0x26FF8904)),
    'walking': _ExerciseStyle('🚶', AppColors.purple, const Color(0x26C27AFF)),
    'swimming': _ExerciseStyle('🏊', AppColors.blue, const Color(0x2651A2FF)),
  };

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
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(_title())),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.pageBackground,
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: HistoryRepo.instance,
      builder: (context, _) {
        final all = HistoryRepo.instance.entries;
        final items = _filteredEntries(all);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: Text(_title())),
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.pageBackground,
            ),
            child: items.isEmpty
                ? Center(
              child: Text(
                widget.filterDate == null
                    ? 'No sessions yet'
                    : 'No sessions on this day',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _workoutTile(
                context,
                items[i],
                nudge: i == 0 && _showSwipeHint,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _workoutTile(BuildContext context, HistoryEntry entry, {bool nudge = false}) {
    final w = entry.workout;
    final theme = Theme.of(context);

    final style =
        _exerciseStyles[w.type.toLowerCase()] ??
            const _ExerciseStyle('💪', AppColors.blue, Color(0x2651A2FF));

    final card = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
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
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.strokeSoft),
            boxShadow: AppShadows.cardShadow,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0x6617191C),
                Color(0x4D17191C),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: style.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    style.emoji,
                    style: const TextStyle(fontSize: 24, height: 1),
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        w.type,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _hm(context, w.start),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          _inlineStat(
                            icon: Icons.favorite_border_rounded,
                            value: '${w.avgHr} bpm',
                            color: AppColors.red,
                          ),
                          const SizedBox(width: 16),
                          _inlineStat(
                            icon: Icons.timer_outlined,
                            value: _fmt(w.duration),
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final dismissible = Dismissible(
      key: ValueKey(entry.id ?? '${w.type}_${w.start.millisecondsSinceEpoch}'),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.redStrong,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
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
        ) ??
            false;
      },
      onDismissed: (_) {
        HistoryRepo.instance.delete(entry);
      },
      child: card,
    );

    if (!nudge) return dismissible;

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.redStrong,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
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

  Widget _inlineStat({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _ExerciseStyle {
  final String emoji;
  final Color accent;
  final Color background;

  const _ExerciseStyle(this.emoji, this.accent, this.background);
}