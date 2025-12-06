import 'package:flutter/foundation.dart';
import 'history_screen.dart' show Workout;
import 'package:heart_link_app/services/workout_service.dart';

// a single workout record entry
class HistoryEntry {
  String ? id; // using for delete or update 
  final Workout workout;
  final List<int> series;
  HistoryEntry({this.id, required this.workout, required this.series});
}

class HistoryRepo extends ChangeNotifier {
  HistoryRepo._();
  static final HistoryRepo instance = HistoryRepo._();

  final List<HistoryEntry> _entries = [];
  final WorkoutService _service = WorkoutService();
  List<HistoryEntry> get entries => List.unmodifiable(_entries);

// add a workout entry
Future<void> add(Workout workout, List<int> series) async {
    final entry = HistoryEntry(workout:workout, series: List<int>.from(series));
    _entries.insert(0, entry);
    notifyListeners(); 
    final docId = await _service.saveEntry(entry);
    entry.id = docId;
  }

  // load all workout entries
  Future<void> loadFromCloud() async {
    final loadedEntries = await _service.loadEntriesForCurrentUser();
    _entries.clear();
    _entries.addAll(loadedEntries);
    notifyListeners();
  }

  // delete a workout entry
  Future<void> delete(HistoryEntry entry) async {    
    final id = entry.id;                            
    _entries.remove(entry);                       
    notifyListeners();                              

    if (id == null) return;                         
    try {                                           
      await _service.deleteEntry(id);                
    } catch (e) {                                    
      debugPrint('Failed to delete workout: $e');  
    }                                               
  }     
}