import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/kunjungan.dart';
import '../services/gps_service.dart';
import '../services/kunjungan_service.dart';
import '../services/navigation_service.dart';
import '../widgets/gps_error.dart';
import '../widgets/status_chip.dart';
import 'kunjungan_form_page.dart';

/// Detail satu kunjungan: data pelanggan, koordinat, jarak, dan navigasi.
class KunjunganDetailPage extends StatefulWidget {
  final int id;
  const KunjunganDetailPage({super.key, required this.id});

  @override
  State<KunjunganDetailPage> createState() => _KunjunganDetailPageState();
}

class _KunjunganDetailPageState extends State<KunjunganDetailPage> {
  late Future<Kunjungan?> _future;
  bool _berubah = false;

  double? _jarakMeter;
  bool _hitung = false;

  @override
  void initState() {
    super.initState();
    _future = KunjunganService.instance.getById(widget.id);
  }

  void _muatUlang() {
    setState(() {
      _jarakMeter = null;
      _future = KunjunganService.instance.getById(widget.id);
    });
  }

  Future<void> _hitungJarak(Kunjungan k) async {
    setState(() => _hitung = true);
    try {
      final pos = await GpsService.instance.ambilLokasi();
      final m = GpsService.jarakMeter(
        pos.latitude,
        pos.longitude,
        k.latitude!,
        k.longitude!,
      );
      if (!mounted) return;
      setState(() => _jarakMeter = m);
    } catch (e) {
      if (!mounted) return;
      showGpsError(context, e);
    } finally {
      if (mounted) setState(() => _hitung = false);
    }
  }

  Future<void> _navigasi(Kunjungan k) async {
    final ok = await NavigationService.bukaRute(k.latitude!, k.longitude!);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Maps / browser tidak dapat dibuka'),
        ),
      );
    }
  }

  Future<void> _edit(Kunjungan k) async {
    final hasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => KunjunganFormPage(data: k)),
    );
    if (hasil == true) {
      _berubah = true;
      _muatUlang();
    }
  }

  Future<void> _hapus(Kunjungan k) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus kunjungan?'),
        content: Text('Data "${k.namaPelanggan}" akan dihapus permanen.'),
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
    await KunjunganService.instance.hapus(k.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Data dihapus')));
    Navigator.pop(context, true);
  }

  Widget _baris(IconData ikon, String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline)),
                Text(nilai, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _berubah);
      },
      child: FutureBuilder<Kunjungan?>(
        future: _future,
        builder: (context, snap) {
          final k = snap.data;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Detail Kunjungan'),
              actions: [
                if (k != null) ...[
                  IconButton(
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _edit(k),
                  ),
                  IconButton(
                    tooltip: 'Hapus',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _hapus(k),
                  ),
                ],
              ],
            ),
            body: () {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError || k == null) {
                return const Center(child: Text('Data tidak ditemukan'));
              }
              final tgl = k.tanggalDateTime;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          k.namaPelanggan,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      StatusChip(k.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _baris(Icons.place_outlined, 'Alamat', k.alamat),
                          _baris(Icons.phone_outlined, 'Nomor HP', k.noHp),
                          _baris(
                            Icons.event_outlined,
                            'Tanggal kunjungan',
                            tgl == null
                                ? '-'
                                : DateFormat('dd/MM/yyyy HH:mm').format(tgl),
                          ),
                          _baris(
                            Icons.notes,
                            'Catatan',
                            k.catatan.isEmpty ? '-' : k.catatan,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Lokasi GPS',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (!k.punyaKoordinat)
                            const Text(
                                'Koordinat belum direkam. Ubah data dan tekan "Ambil Lokasi".')
                          else ...[
                            _baris(
                              Icons.my_location,
                              'Koordinat',
                              '${k.latitude!.toStringAsFixed(6)}, '
                                  '${k.longitude!.toStringAsFixed(6)}'
                                  '${k.akurasiGps == null ? '' : '  (±${k.akurasiGps!.toStringAsFixed(1)} m)'}',
                            ),
                            _baris(
                              Icons.straighten,
                              'Jarak dari posisi Anda',
                              _jarakMeter == null
                                  ? 'Belum dihitung'
                                  : GpsService.formatJarak(_jarakMeter!),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _hitung ? null : () => _hitungJarak(k),
                                  icon: _hitung
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Icon(Icons.social_distance),
                                  label: const Text('HITUNG JARAK'),
                                ),
                                FilledButton.icon(
                                  onPressed: () => _navigasi(k),
                                  icon: const Icon(Icons.directions),
                                  label: const Text('NAVIGASI'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }(),
          );
        },
      ),
    );
  }
}
