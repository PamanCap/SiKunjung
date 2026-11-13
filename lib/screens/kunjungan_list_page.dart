import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/kunjungan.dart';
import '../services/kunjungan_service.dart';
import '../services/sensor_service.dart';
import '../widgets/kunjungan_card.dart';
import 'kunjungan_detail_page.dart';
import 'kunjungan_form_page.dart';

class KunjunganListPage extends StatefulWidget {
  const KunjunganListPage({super.key});

  @override
  State<KunjunganListPage> createState() => _KunjunganListPageState();
}

class _KunjunganListPageState extends State<KunjunganListPage> {
  final _cariController = TextEditingController();
  final _shake = ShakeDetector();

  late Future<List<Kunjungan>> _future;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  Timer? _debounce;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _future = _ambil();
    _mulaiShake();
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _debounce?.cancel();
    _cariController.dispose();
    super.dispose();
  }

  Future<List<Kunjungan>> _ambil() =>
      KunjunganService.instance.getAll(cari: _keyword);

  void _muatUlang() {
    if (!mounted) return;
    setState(() => _future = _ambil());
  }

  // Dipakai RefreshIndicator: harus MENUNGGU data selesai dimuat, kalau tidak
  // spinner langsung hilang dan terlihat seperti tidak terjadi apa-apa.
  Future<void> _segarkan() async {
    if (!mounted) return;
    final baru = _ambil();
    setState(() => _future = baru);
    await Future.wait([
      baru.then<void>((_) {}, onError: (_) {}),
      Future<void>.delayed(const Duration(milliseconds: 600)),
    ]);
    if (!mounted) return;
    _snack('Daftar disegarkan');
  }

  void _snack(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(pesan), duration: const Duration(seconds: 2)),
      );
  }

  // Goyang untuk menyegarkan.
  void _mulaiShake() {
    _accelSub =
        accelerometerEventStream(
          samplingPeriod: SensorInterval.gameInterval,
        ).listen(
          (e) {
            if (!mounted) return;
            // Abaikan goyangan saat halaman lain (form/detail) sedang di atas.
            if (ModalRoute.of(context)?.isCurrent != true) return;
            if (_shake.update(e.x, e.y, e.z)) {
              _segarkan();
            }
          },
          // Tanpa accelerometer: shake nonaktif, pull-to-refresh tetap jalan.
          onError: (Object _) {},
        );
  }

  void _onCari(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _keyword = value.trim();
      _muatUlang();
    });
  }

  Future<void> _bukaForm([Kunjungan? data]) async {
    final berubah = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => KunjunganFormPage(data: data)),
    );
    if (berubah == true) _muatUlang();
  }

  Future<void> _bukaDetail(Kunjungan data) async {
    final berubah = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => KunjunganDetailPage(id: data.id!),
      ),
    );
    if (berubah == true) _muatUlang();
  }

  Future<void> _hapus(Kunjungan data) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus kunjungan?'),
        content: Text('Data "${data.namaPelanggan}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('BATAL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('HAPUS'),
          ),
        ],
      ),
    );
    if (yakin != true) return;
    await KunjunganService.instance.hapus(data.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Data dihapus')));
    _muatUlang();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Kunjungan')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _cariController,
              onChanged: _onCari,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari nama, alamat, atau no. HP',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _cariController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _cariController.clear();
                          _keyword = '';
                          _muatUlang();
                        },
                      ),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Kunjungan>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Gagal memuat: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rows = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: _segarkan,
                  child: rows.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 120),
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                _keyword.isEmpty
                                    ? 'Belum ada kunjungan'
                                    : 'Tidak ada hasil untuk "$_keyword"',
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                          itemCount: rows.length,
                          itemBuilder: (context, i) {
                            final row = rows[i];
                            return KunjunganCard(
                              data: row,
                              onTap: () => _bukaDetail(row),
                              onEdit: () => _bukaForm(row),
                              onHapus: () => _hapus(row),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
