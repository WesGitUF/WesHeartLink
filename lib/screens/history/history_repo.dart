import 'package:flutter/foundation.dart';
import 'history_screen.dart' show Workout;
import 'package:heart_link_app/services/workout_service.dart';

// a single workout record entry
class HistoryEntry {
  final Workout workout;
  final List<int> series;
  final String? docId; // ADD THIS FIELD
  
  HistoryEntry({
    required this.workout, 
    required this.series,
    this.docId,  // ADD THIS PARAMETER
  });
}

class HistoryRepo extends ChangeNotifier {
  HistoryRepo._();
  static final HistoryRepo instance = HistoryRepo._();

  final List<HistoryEntry> _entries = [];
  final WorkoutService _service = WorkoutService();
  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  // add a workout entry
  Future<void> add(Workout workout, List<int> series) async {
    final entry = HistoryEntry(workout: workout, series: List<int>.from(series));
    _entries.insert(0, entry);
    notifyListeners(); 
    await _service.saveEntry(entry);
  }

  // ADD THIS METHOD
  // delete a workout entry
  Future<void> delete(HistoryEntry entry) async {
    if (entry.docId != null) {
      await _service.deleteEntry(entry.docId!);
    }
    _entries.remove(entry);
    notifyListeners();
  }

  // load all workout entries
  Future<void> loadFromCloud() async {
    final loadedEntries = await _service.loadEntriesForCurrentUser();
    _entries.clear();
    for (final entry in loadedEntries) {
      _entries.add(entry);
    }
    notifyListeners();
  }
}