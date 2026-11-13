import 'package:shared_preferences/shared_preferences.dart';

/// Preferensi pengguna (bukan data sensitif) memakai shared_preferences.
class PreferencesService {
  PreferencesService._();
  static final PreferencesService instance = PreferencesService._();

  static const _kLastUsername = 'last_username';
  static const _kLastPetugas = 'last_petugas';
  static const _kThemeIndex = 'theme_index';
  static const _kThemeMode = 'theme_mode';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> simpanLogin(String username, String namaPetugas) async {
    final p = await _prefs;
    await p.setString(_kLastUsername, username);
    await p.setString(_kLastPetugas, namaPetugas);
  }

  Future<String?> lastUsername() async => (await _prefs).getString(_kLastUsername);

  Future<String?> lastPetugas() async => (await _prefs).getString(_kLastPetugas);

  Future<void> simpanTema(int index, int modeIndex) async {
    final p = await _prefs;
    await p.setInt(_kThemeIndex, index);
    await p.setInt(_kThemeMode, modeIndex);
  }

  Future<int> themeIndex() async => (await _prefs).getInt(_kThemeIndex) ?? 0;

  Future<int> themeModeIndex() async => (await _prefs).getInt(_kThemeMode) ?? 0;
}
