import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import 'dashboard_page.dart';
import 'login_page.dart';

/// Layar pembuka: menampilkan logo lalu memeriksa sesi login.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  @override
  void initState() {
    super.initState();
    _lanjut();
  }

  Future<void> _lanjut() async {
    final tunggu = Future<void>.delayed(const Duration(milliseconds: 2200));
    User? user;
    try {
      user = await AuthService.instance.currentUser();
    } catch (_) {
      user = null;
    }
    await tunggu;
    if (!mounted) return;

    final Widget tujuan =
        user != null ? const DashboardPage() : const LoginPage();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => tujuan,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: _anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1).animate(
              CurvedAnimation(parent: _anim, curve: Curves.easeOutBack),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: scheme.onPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 72,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'SiKunjung',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sistem Informasi Kunjungan Lapangan',
                  style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: scheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
