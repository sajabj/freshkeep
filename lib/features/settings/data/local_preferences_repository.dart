import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_preferences.dart';
import '../domain/preferences_repository.dart';

class LocalPreferencesRepository implements PreferencesRepository {
  LocalPreferencesRepository(this._storage);
  final SharedPreferencesAsync _storage;
  static const storageKey = 'freshkeep.preferences.v1';
  @override
  Future<AppPreferences> read() async {
    final value = await _storage.getString(storageKey);
    if (value == null) return const AppPreferences();
    // Corruption is surfaced; never silently overwrite the user's preferences.
    return AppPreferences.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  @override
  Future<void> write(AppPreferences preferences) =>
      _storage.setString(storageKey, jsonEncode(preferences.toJson()));
}
