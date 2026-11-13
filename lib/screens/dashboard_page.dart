import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/kunjungan_service.dart';
import '../widgets/offline_banner.dart';
import '../widgets/theme_picker.dart';
import 'info_perangkat_page.dart';
import 'kunjungan_form_page.dart';
import 'kunjungan_list_page.dart';
import 'login_page.dart';
import 'network_page.dart';
import 'peta_kunjungan_page.dart';
import 'sensor_page.dart';

/// Kerangka utama aplikasi dengan NavigationBar:
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _tab = 0;

  Widget _halaman() {
    switch (_tab) {
      case 1:
        return const KunjunganListPage();
      case 2:
        return const PetaKunjunganPage();
      case 3:
        return const SensorPage();
      default:
        return BerandaTab(onPindahTab: (i) => setState(() => _tab = i));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _halaman(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt_rounded),
            label: 'Kunjungan',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Peta',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined),
            selectedIcon: Icon(Icons.sensors_rounded),
            label: 'Sensor',
          ),
        ],
      ),
    );
  }
}

class _DashData {
  final String nama;
  final Map<String, int> status;
  const _DashData(this.nama, this.status);

  int get total => status.values.fold(0, (a, b) => a + b);
}

class BerandaTab extends StatefulWidget {
  final ValueChanged<int> onPindahTab;
  const BerandaTab({super.key, required this.onPindahTab});

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  late Future<_DashData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashData> _load() async {
    final user = await AuthService.instance.currentUser();
    final status = await KunjunganService.instance.ringkasan();
    return _DashData(user?.nama ?? 'Petugas', status);
  }

  void _muatUlang() => setState(() => _future = _load());

  Future<void> _buka(Widget page) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => page),
    );
    if (mounted) _muatUlang();
  }

  Future<void> _logout() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari aplikasi?'),
        content: const Text('Sesi login akan dihapus dari perangkat ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('BATAL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('KELUAR'),
          ),
        ],
      ),
    );
    if (yakin != true) return;

    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SiKunjung',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _muatUlang(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Banner peringatan saat tidak ada koneksi.
              const OfflineBanner(),

              FutureBuilder<_DashData>(
                future: _future,
                builder: (context, snap) {
                  final data = snap.data;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Selamat Datang,',
                                style: TextStyle(
                                    color: scheme.onPrimary.withValues(alpha: 0.8))),
                            const SizedBox(height: 6),
                            Text(
                              data?.nama ?? '...',
                              style: TextStyle(
                                color: scheme.onPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.verified_user_rounded,
                                    size: 16,
                                    color: scheme.onPrimary.withValues(alpha: 0.8)),
                                const SizedBox(width: 6),
                                Text('Petugas Lapangan',
                                    style: TextStyle(
                                        color: scheme.onPrimary
                                            .withValues(alpha: 0.8))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ringkasan Kunjungan',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () => widget.onPindahTab(1),
                            child: const Text('Lihat semua'),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _Stat('Total', data?.total, Icons.assignment_outlined,
                              scheme.primary),
                          _Stat('Selesai', data?.status['Selesai'] ?? (data == null ? null : 0),
                              Icons.check_circle_outline, Colors.green),
                          _Stat('Pending', data?.status['Pending'] ?? (data == null ? null : 0),
                              Icons.hourglass_empty, Colors.orange),
                          _Stat('Batal', data?.status['Batal'] ?? (data == null ? null : 0),
                              Icons.cancel_outlined, Colors.red),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),
              const Text('Menu Utama',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              _MenuTile(
                icon: Icons.add_location_alt_rounded,
                title: 'Tambah Kunjungan',
                subtitle: 'Catat kunjungan pelanggan baru',
                onTap: () => _buka(const KunjunganFormPage()),
              ),
              _MenuTile(
                icon: Icons.list_alt_rounded,
                title: 'Data Kunjungan',
                subtitle: 'Cari, lihat, ubah, dan hapus kunjungan',
                onTap: () => widget.onPindahTab(1),
              ),
              _MenuTile(
                icon: Icons.map_rounded,
                title: 'Peta Kunjungan',
                subtitle: 'Lokasi pelanggan, jarak, dan navigasi',
                onTap: () => widget.onPindahTab(2),
              ),
              _MenuTile(
                icon: Icons.sensors_rounded,
                title: 'Sensor Perangkat',
                subtitle: 'Accelerometer, gyroscope, magnetometer, kompas',
                onTap: () => widget.onPindahTab(3),
              ),
              _MenuTile(
                icon: Icons.wifi_rounded,
                title: 'Status Jaringan',
                subtitle: 'WiFi / seluler / offline',
                onTap: () => _buka(const NetworkPage()),
              ),
              _MenuTile(
                icon: Icons.phone_android_rounded,
                title: 'Info Perangkat',
                subtitle: 'Sistem operasi, perangkat, dan versi aplikasi',
                onTap: () => _buka(const InfoPerangkatPage()),
              ),
              _MenuTile(
                icon: Icons.palette_rounded,
                title: 'Tema Aplikasi',
                subtitle: 'Pilih warna dan mode terang/gelap',
                onTap: () => showThemePicker(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int? value;
  final IconData icon;
  final Color color;
  const _Stat(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(
                value?.toString() ?? '-',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: scheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
