import 'package:freshkeep/features/settings/domain/app_preferences.dart';
import 'package:freshkeep/features/settings/domain/preferences_repository.dart';

class MemoryPreferencesRepository implements PreferencesRepository {
  MemoryPreferencesRepository([this.value = const AppPreferences()]);
  AppPreferences value;
  bool failRead = false;
  bool failWrite = false;
  @override
  Future<AppPreferences> read() async {
    if (failRead) throw StateError('Read failed');
    return value;
  }

  @override
  Future<void> write(AppPreferences preferences) async {
    if (failWrite) throw StateError('Write failed');
    value = preferences;
  }
}
