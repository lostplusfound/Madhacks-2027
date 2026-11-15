import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../navigation/floor_data.dart';

/// User preferences only; map calibration and anchors retain their existing store.
class AppState extends ChangeNotifier {
  AppState(this.preferences) {
    try {
      if (preferences == null) throw StateError('Preferences unavailable');
      final raw = preferences!.getString(storageKey);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        saved.addAll(List<String>.from(data['saved'] as List? ?? []));
        visits.addAll(List<String>.from(data['visits'] as List? ?? []));
        aliases.addAll(Map<String, String>.from(data['aliases'] as Map? ?? {}));
        feet = data['feet'] == true;
        contrast = data['contrast'] == true;
        voice = data['voice'] == true;
      }
    } catch (_) {
      storageError =
          'Could not read preferences. Changes will be saved on this phone.';
    }
  }
  static const storageKey = 'madmaps.ui.v1';
  final SharedPreferences? preferences;
  final Set<String> saved = {};
  final List<String> visits = [];
  final Map<String, String> aliases = {};
  bool feet = false, contrast = false, voice = false;
  String? storageError;
  Future<void> _writes = Future.value();
  bool _disposed = false;
  String label(FloorLocation place) => aliases[place.id] ?? place.label;
  String distance(double meters) =>
      feet ? '${(meters * 3.28084).round()} ft' : '${meters.round()} m';
  List<String> get recent => visits.reversed.toSet().take(4).toList();
  List<String> get frequent {
    final counts = <String, int>{};
    for (final id in visits) {
      counts.update(id, (v) => v + 1, ifAbsent: () => 1);
    }
    return counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  }

  void toggleSaved(String id) {
    if (!saved.remove(id)) saved.add(id);
    persist();
  }

  void rename(String id, String value) {
    final clean = value.trim();
    if (clean.isEmpty) {
      aliases.remove(id);
    } else {
      aliases[id] = clean;
    }
    persist();
  }

  void recordVisit(String id) {
    visits.add(id);
    if (visits.length > 100) visits.removeRange(0, visits.length - 100);
    persist();
  }

  void setFeet(bool value) {
    feet = value;
    persist();
  }

  void setContrast(bool value) {
    contrast = value;
    persist();
  }

  void setVoice(bool value) {
    voice = value;
    persist();
  }

  void persist() {
    final value = jsonEncode({
      'saved': saved.toList(),
      'visits': visits,
      'aliases': aliases,
      'feet': feet,
      'contrast': contrast,
      'voice': voice,
    });
    _writes = _writes.then((_) async {
      try {
        if (preferences == null ||
            !await preferences!.setString(storageKey, value)) {
          throw StateError('Storage rejected write');
        }
        storageError = null;
      } catch (_) {
        storageError =
            'Could not save preferences. Changes remain available for this session.';
      }
      if (!_disposed) notifyListeners();
    });
    notifyListeners();
  }

  Future<void> get flushed => _writes;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
