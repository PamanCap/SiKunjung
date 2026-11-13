import 'package:flutter/material.dart';

import 'database/database_helper.dart';
import 'screens/splash_page.dart';
import 'services/auth_service.dart';
import 'services/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi database SQLite
  await DatabaseHelper.instance.database;

  // Akun uji
  await AuthService.instance.createDemoAccount();

  // Muat pilihan tema yang tersimpan di shared_preferences.
  await ThemeController.instance.load();

  runApp(const SiKunjungApp());
}

class SiKunjungApp extends StatelessWidget {
  const SiKunjungApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    return ListenableBuilder(
      listenable: theme,
      builder: (context, _) {
        return MaterialApp(
          title: 'SiKunjung',
          debugShowCheckedModeBanner: false,
          theme: theme.themeData(Brightness.light),
          darkTheme: theme.themeData(Brightness.dark),
          themeMode: theme.mode,
          home: const SplashPage(),
        );
      },
    );
  }
}
