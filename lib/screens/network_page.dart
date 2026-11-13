import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  List<ConnectivityResult> _status = [];
  bool? _internetOk; // null = belum diperiksa
  bool _memeriksa = false;
  DateTime? _terakhir;

  @override
  void initState() {
    super.initState();
    _perbarui();
    _sub = _connectivity.onConnectivityChanged.listen((event) {
      if (!mounted) return;
      setState(() => _status = event);
      _cekInternet();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _perbarui() async {
    final result = await _connectivity.checkConnectivity();
    if (!mounted) return;
    setState(() => _status = result);
    await _cekInternet();
  }

  bool get _offline =>
      _status.isEmpty || _status.every((s) => s == ConnectivityResult.none);

  // Uji akses HTTPS ke endpoint terkontrol (HTTP 204 = berhasil).
  Future<void> _cekInternet() async {
    if (!mounted) return;
    setState(() => _memeriksa = true);

    bool ok = false;
    if (!_offline) {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5);
      try {
        final req = await client.getUrl(
          Uri.parse('https://www.gstatic.com/generate_204'),
        );
        final res = await req.close().timeout(const Duration(seconds: 5));
        await res.drain<void>();
        ok = res.statusCode == 204;
      } catch (_) {
        ok = false;
      } finally {
        client.close(force: true);
      }
    }

    if (!mounted) return;
    setState(() {
      _internetOk = ok;
      _memeriksa = false;
      _terakhir = DateTime.now();
    });
  }

  String _label(ConnectivityResult r) => switch (r) {
    ConnectivityResult.wifi => 'Wi-Fi',
    ConnectivityResult.mobile => 'Seluler',
    ConnectivityResult.ethernet => 'Ethernet',
    ConnectivityResult.vpn => 'VPN',
    ConnectivityResult.bluetooth => 'Bluetooth',
    ConnectivityResult.satellite => 'Satelit',
    ConnectivityResult.other => 'Lainnya',
    ConnectivityResult.none => 'Offline',
  };

  String _waktu(DateTime d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.day)}/${p(d.month)}/${d.year} '
        '${p(d.hour)}:${p(d.minute)}:${p(d.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final Color warna;
    final IconData ikon;
    final String judul;

    if (_memeriksa || _internetOk == null) {
      warna = Colors.grey;
      ikon = Icons.cloud_sync;
      judul = 'Memeriksa koneksi...';
    } else if (_offline) {
      warna = Colors.red;
      ikon = Icons.cloud_off;
      judul = 'Perangkat offline';
    } else if (_internetOk == true) {
      warna = Colors.green;
      ikon = Icons.cloud_done;
      judul = 'Internet terverifikasi';
    } else {
      warna = Colors.orange;
      ikon = Icons.cloud_queue;
      judul = 'Internet belum terverifikasi';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Status Jaringan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  Icon(ikon, size: 64, color: warna),
                  const SizedBox(height: 12),
                  Text(
                    judul,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: warna,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Monitoring Konektivitas SiKunjung'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jenis Koneksi',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_status.isEmpty ? '-' : _status.map(_label).join(', ')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Akses Internet',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _internetOk == true
                        ? 'Server verifikasi dapat diakses.'
                        : 'Server verifikasi belum dapat diakses.',
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pemeriksaan menggunakan HTTPS ke '
                    'www.gstatic.com/generate_204. Hasil gagal tidak selalu '
                    'berarti semua layanan internet terputus.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Pemeriksaan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Terakhir diperiksa: '
                    '${_terakhir == null ? '-' : _waktu(_terakhir!)}',
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Status diperbarui saat jenis jaringan berubah, saat '
                    'halaman dibuka, atau saat tombol refresh ditekan.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const _KartuGenerasi(),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _memeriksa ? null : _perbarui,
            icon: const Icon(Icons.refresh),
            label: const Text('PERBARUI STATUS'),
          ),
        ],
      ),
    );
  }
}

/// Ringkasan generasi jaringan seluler dan kecocokannya untuk SiKunjung.
class _KartuGenerasi extends StatelessWidget {
  const _KartuGenerasi();

  @override
  Widget build(BuildContext context) {
    Widget baris(String g, String cepat, String latensi, String ket) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 44,
              child: Text(
                g,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$cepat • latensi $latensi'),
                  Text(
                    ket,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 0,
      child: ExpansionTile(
        leading: const Icon(Icons.signal_cellular_alt),
        title: const Text('Generasi jaringan seluler'),
        subtitle: const Text('2G, 3G, 4G LTE, 5G'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          baris(
            '2G',
            '± 50–250 kbps',
            '300–1000 ms',
            'GSM/GPRS/EDGE. Cukup untuk SMS dan teks kecil.',
          ),
          baris(
            '3G',
            '± 1–42 Mbps',
            '100–500 ms',
            'UMTS/HSPA. Memuat peta masih lambat.',
          ),
          baris(
            '4G',
            '± 10–150 Mbps',
            '30–70 ms',
            'LTE. Nyaman untuk peta dan navigasi.',
          ),
          baris(
            '5G',
            '± 100 Mbps – >1 Gbps',
            '1–10 ms',
            'Sangat cepat, namun cakupan belum merata.',
          ),
          const Divider(),
          const Text(
            'Untuk SiKunjung, 4G LTE (minimal 3G) sudah memadai untuk memuat '
            'tile peta dan membuka navigasi. Pencatatan kunjungan, GPS, dan '
            'sensor tetap berjalan tanpa internet karena data disimpan lokal.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
