import 'app_preferences.dart';

/// Food and inventory events belong to SQLite in phase two, not this store.
abstract interface class PreferencesRepository {
  Future<AppPreferences> read();
  Future<void> write(AppPreferences preferences);
}
