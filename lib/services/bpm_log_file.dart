import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// Persists the BPM series to a binary append-only file so that crash recovery
/// never needs to re-serialize the full list. Each HR value is stored as a
/// 2-byte big-endian uint16, so a 4-hour workout (~14 400 samples) costs
/// ~28 KB on disk and only 20 bytes are appended per 10-second save tick.
class BpmLogFile {
  static const _kFileName = 'active_bpm_log.bin';

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_kFileName');
  }

  /// Appends [entries] to the log. Only the NEW samples since the last call
  /// should be passed — the caller tracks the offset.
  static Future<void> append(List<int> entries) async {
    if (entries.isEmpty) return;
    final bytes = Uint8List(entries.length * 2);
    for (var i = 0; i < entries.length; i++) {
      final v = entries[i].clamp(0, 65535);
      bytes[i * 2]     = (v >> 8) & 0xFF;
      bytes[i * 2 + 1] = v & 0xFF;
    }
    final f = await _file();
    await f.writeAsBytes(bytes, mode: FileMode.append, flush: true);
  }

  /// Reads and returns all stored BPM values.
  static Future<List<int>> readAll() async {
    final f = await _file();
    if (!await f.exists()) return [];
    final bytes = await f.readAsBytes();
    if (bytes.length % 2 != 0) return []; // guard against corruption
    final result = <int>[];
    for (var i = 0; i < bytes.length; i += 2) {
      result.add((bytes[i] << 8) | bytes[i + 1]);
    }
    return result;
  }

  /// Deletes the log file. Call at workout start (clean slate) and after
  /// a successful save to Firestore.
  static Future<void> clear() async {
    final f = await _file();
    if (await f.exists()) await f.delete();
  }
}
