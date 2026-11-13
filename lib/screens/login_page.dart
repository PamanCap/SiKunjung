import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/preferences_service.dart';
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static final RegExp _usernameRegex = RegExp(r'^[A-Za-z0-9_.]+$');

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _hidePassword = true;
  bool _isLoading = false;
  String? _petugasTerakhir;

  @override
  void initState() {
    super.initState();
    _muatPreferensi();
  }

  // Nama petugas terakhir login diambil dari shared_preferences.
  Future<void> _muatPreferensi() async {
    final prefs = PreferencesService.instance;
    final username = await prefs.lastUsername();
    final petugas = await prefs.lastPetugas();
    if (!mounted) return;
    setState(() {
      if (username != null) _usernameController.text = username;
      _petugasTerakhir = petugas;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = await AuthService.instance.login(
        _usernameController.text,
        _passwordController.text,
      );
      if (!mounted) return;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Username atau password salah'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const DashboardPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal melakukan login: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 76, color: scheme.primary),
                    const SizedBox(height: 12),
                    const Text(
                      'SiKunjung',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sistem Informasi Kunjungan Lapangan',
                      textAlign: TextAlign.center,
                    ),
                    if (_petugasTerakhir != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Terakhir login: $_petugasTerakhir',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.outline, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 36),
                    TextFormField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      maxLength: 30,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person),
                        counterText: '',
                      ),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Username wajib diisi';
                        if (value.length < 3) return 'Username minimal 3 karakter';
                        if (!_usernameRegex.hasMatch(value)) {
                          return 'Hanya huruf, angka, titik, dan garis bawah';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _hidePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _isLoading ? null : _login(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          tooltip: _hidePassword ? 'Tampilkan' : 'Sembunyikan',
                          icon: Icon(_hidePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password wajib diisi';
                        if (v.length < 6) return 'Password minimal 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: scheme.onPrimary,
                                ),
                              )
                            : const Text(
                                'MASUK',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
