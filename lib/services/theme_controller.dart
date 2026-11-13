import 'package:flutter/material.dart';

import 'preferences_service.dart';

class AppThemeOption {
  final String nama;
  final Color seed;
  const AppThemeOption(this.nama, this.seed);
}

/// Pengatur tema 
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const List<AppThemeOption> options = [
    AppThemeOption('Biru Samudra', Color(0xFF1765D1)),
    AppThemeOption('Hijau Hutan', Color(0xFF2E7D32)),
    AppThemeOption('Oranye Senja', Color(0xFFE65100)),
    AppThemeOption('Ungu Lavender', Color(0xFF6A1B9A)),
    AppThemeOption('Merah Ruby', Color(0xFFC62828)),
  ];

  static const List<ThemeMode> modes = [
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark,
  ];

  int _index = 0;
  int _modeIndex = 0;

  int get index => _index;
  ThemeMode get mode => modes[_modeIndex];
  AppThemeOption get current => options[_index];

  Future<void> load() async {
    final prefs = PreferencesService.instance;
    final i = await prefs.themeIndex();
    final m = await prefs.themeModeIndex();
    _index = (i >= 0 && i < options.length) ? i : 0;
    _modeIndex = (m >= 0 && m < modes.length) ? m : 0;
  }

  Future<void> setIndex(int value) async {
    _index = value;
    notifyListeners();
    await PreferencesService.instance.simpanTema(_index, _modeIndex);
  }

  Future<void> setMode(ThemeMode value) async {
    _modeIndex = modes.indexOf(value);
    notifyListeners();
    await PreferencesService.instance.simpanTema(_index, _modeIndex);
  }

  ThemeData themeData(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: current.seed,
        brightness: brightness,
      ),
      appBarTheme: const AppBarTheme(centerTitle: false),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
