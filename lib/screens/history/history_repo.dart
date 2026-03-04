import 'package:flutter/foundation.dart';
import 'history_screen.dart' show Workout;
import 'package:heart_link_app/services/workout_service.dart';

// A single workout record entry
class HistoryEntry {
  String? id; // Firebase document ID for delete/update
  final Workout workout;
  final List<int> series;

  HistoryEntry({
    this.id,
    required this.workout,
    required this.series,
  });
}

class HistoryRepo extends ChangeNotifier {
  HistoryRepo._();
  static final HistoryRepo instance = HistoryRepo._();

  final List<HistoryEntry> _entries = [];
  final WorkoutService _service = WorkoutService();

  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  bool _hasDeletions = false;
  bool get hasDeletions => _hasDeletions;
  void clearDeletions() => _hasDeletions = false;

  Future<void> add({
    required double avgHr,
    required List<int> bpmSeries,
    required Duration elapsed,
    required String workoutMode,
    required int maxSessionHr,
    required String topZone,
    required int theoreticalMaxHr,
  }) async {
    final entry = HistoryEntry(
      workout: Workout(
        type: workoutMode,
        start: DateTime.now(),
        duration: elapsed,
        avgHr: avgHr.round(),
        calories: 0,
        maxSessionHr: maxSessionHr,
        theoreticalMaxHr: theoreticalMaxHr,
        topZone: topZone,
      ),
      series: List<int>.from(bpmSeries),
    );

    _entries.insert(0, entry);
    notifyListeners();

    final docId = await _service.saveEntry(
      avgHr: avgHr,
      bpmSeries: bpmSeries,
      elapsed: elapsed,
      workoutMode: workoutMode,
      maxSessionHr: maxSessionHr,
      topZone: topZone,
      theoreticalMaxHr: theoreticalMaxHr,
    );
    entry.id = docId;
  }

  Future<void> loadFromCloud() async {
    try {
      final loaded = await _service.loadEntriesForCurrentUser();
      _entries.clear();
      _entries.addAll(loaded);
      notifyListeners();
    } catch (e) {
      debugPrint("HistoryRepo.loadFromCloud ERROR → $e");
    }
  }

  Future<void> delete(HistoryEntry entry) async {
    final id = entry.id;

    _entries.remove(entry);
    _hasDeletions = true;
    notifyListeners();

    if (id == null) return;

    try {
      await _service.deleteEntry(id);
    } catch (e) {
      debugPrint('Failed to delete workout: $e');
    }
  }
}
