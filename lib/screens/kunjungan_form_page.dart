import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../models/kunjungan.dart';
import '../services/gps_service.dart';
import '../services/kunjungan_service.dart';
import '../widgets/gps_error.dart';
import '../widgets/offline_banner.dart';

class KunjunganFormPage extends StatefulWidget {
  final Kunjungan? data; // null = tambah, ada isi = edit
  const KunjunganFormPage({super.key, this.data});

  @override
  State<KunjunganFormPage> createState() => _KunjunganFormPageState();
}

class _KunjunganFormPageState extends State<KunjunganFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _alamat = TextEditingController();
  final _noHp = TextEditingController();
  final _catatan = TextEditingController();

  String _status = 'Pending';
  bool _saving = false;

  double? _latitude, _longitude, _akurasi;
  bool _gpsLoading = false;

  bool get _edit => widget.data != null;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    if (d != null) {
      _nama.text = d.namaPelanggan;
      _alamat.text = d.alamat;
      _noHp.text = d.noHp;
      _catatan.text = d.catatan;
      _status = Kunjungan.daftarStatus.contains(d.status) ? d.status : 'Pending';
      _latitude = d.latitude;
      _longitude = d.longitude;
      _akurasi = d.akurasiGps;
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    _alamat.dispose();
    _noHp.dispose();
    _catatan.dispose();
    super.dispose();
  }

  Future<void> _ambilLokasi() async {
    setState(() => _gpsLoading = true);
    try {
      final posisi = await GpsService.instance.ambilLokasi();
      if (!mounted) return;
      setState(() {
        _latitude = posisi.latitude;
        _longitude = posisi.longitude;
        _akurasi = posisi.accuracy;
      });
    } catch (e) {
      if (!mounted) return;
      showGpsError(context, e);
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  // Tambah data baru WAJIB dengan GPS aktif. Dicek saat menyimpan, jadi
  // kalau GPS dimatikan setelah lokasi diambil, data tetap tidak bisa disimpan.
  Future<bool> _pastikanGps() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const GpsException(
          'GPS mati. Aktifkan GPS untuk menyimpan kunjungan baru.',
          bukaPengaturanLokasi: true,
        );
      }
      if (_latitude == null || _longitude == null) {
        final posisi = await GpsService.instance.ambilLokasi();
        if (!mounted) return false;
        setState(() {
          _latitude = posisi.latitude;
          _longitude = posisi.longitude;
          _akurasi = posisi.accuracy;
        });
      }
      return true;
    } catch (e) {
      if (mounted) showGpsError(context, e);
      return false;
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    if (!_edit && !await _pastikanGps()) {
      if (mounted) setState(() => _saving = false);
      return;
    }
    try {
      final svc = KunjunganService.instance;
      if (_edit) {
        await svc.ubah(
          widget.data!,
          nama: _nama.text,
          alamat: _alamat.text,
          noHp: _noHp.text,
          catatan: _catatan.text,
          status: _status,
          latitude: _latitude,
          longitude: _longitude,
          akurasi: _akurasi,
        );
      } else {
        await svc.tambah(
          nama: _nama.text,
          alamat: _alamat.text,
          noHp: _noHp.text,
          catatan: _catatan.text,
          status: _status,
          latitude: _latitude,
          longitude: _longitude,
          akurasi: _akurasi,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunjungan berhasil disimpan')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final punyaGps = _latitude != null && _longitude != null;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_edit ? 'Edit Kunjungan' : 'Tambah Kunjungan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const OfflineBanner(
              message: 'Mode offline: kunjungan tetap dapat disimpan di '
                  'perangkat (GPS tetap harus aktif).',
            ),
            const Text('Informasi Pelanggan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Lengkapi data dan lokasi kunjungan.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nama,
              maxLength: 100,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama Pelanggan *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'Nama wajib diisi';
                if (t.length < 3) return 'Nama minimal 3 karakter';
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _alamat,
              maxLength: 300,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Alamat Pelanggan *',
                prefixIcon: Icon(Icons.home_outlined),
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'Alamat wajib diisi';
                if (t.length < 5) return 'Alamat terlalu pendek';
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noHp,
              maxLength: 15,
              keyboardType: TextInputType.phone,
              // Hanya angka yang bisa diketik / ditempel.
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Nomor HP *',
                hintText: 'contoh: 081234567890',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'Nomor HP wajib diisi';
                if (!RegExp(r'^[0-9]+$').hasMatch(t)) {
                  return 'Nomor HP hanya boleh berisi angka';
                }
                if (t.length < 10) return 'Nomor HP minimal 10 digit';
                return null;
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status Kunjungan',
                prefixIcon: Icon(Icons.fact_check_outlined),
              ),
              items: Kunjungan.daftarStatus
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v ?? 'Pending'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _catatan,
              maxLength: 1000,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Catatan Kunjungan',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.my_location, color: scheme.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Text(
                        _edit ? 'Lokasi GPS Kunjungan' : 'Lokasi GPS Kunjungan *',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    punyaGps
                        ? 'Latitude: ${_latitude!.toStringAsFixed(6)}\n'
                            'Longitude: ${_longitude!.toStringAsFixed(6)}\n'
                            'Akurasi: ${_akurasi?.toStringAsFixed(1) ?? "-"} m'
                        : _edit
                            ? 'Lokasi belum diambil. Tekan tombol untuk merekam koordinat.'
                            : 'Wajib: aktifkan GPS. Lokasi diambil otomatis saat '
                                'menyimpan, atau tekan tombol di bawah.',
                    style: TextStyle(color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _gpsLoading ? null : _ambilLokasi,
                      icon: _gpsLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(punyaGps ? 'PERBARUI LOKASI' : 'AMBIL LOKASI'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _simpan,
              child: Text(_saving ? 'MENYIMPAN...' : 'SIMPAN'),
            ),
          ],
        ),
      ),
    );
  }
}