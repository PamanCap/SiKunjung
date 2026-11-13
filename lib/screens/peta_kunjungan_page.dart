import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/kunjungan.dart';
import '../services/gps_service.dart';
import '../services/kunjungan_service.dart';
import '../services/navigation_service.dart';
import '../widgets/gps_error.dart';
import '../widgets/offline_banner.dart';
import 'kunjungan_detail_page.dart';

class PetaKunjunganPage extends StatefulWidget {
  const PetaKunjunganPage({super.key});

  @override
  State<PetaKunjunganPage> createState() => _PetaKunjunganPageState();
}

class _PetaKunjunganPageState extends State<PetaKunjunganPage> {
  final MapController _map = MapController();
  late Future<List<Kunjungan>> _future;

  Kunjungan? _selected;
  Position? _posisi; // posisi petugas saat ini
  bool _cariPosisi = false;

  @override
  void initState() {
    super.initState();
    _future = KunjunganService.instance.getDenganKoordinat();
    _perbaruiPosisi(tampilkanError: false);
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  Future<void> _perbaruiPosisi({bool tampilkanError = true, bool pusatkan = false}) async {
    setState(() => _cariPosisi = true);
    try {
      final p = await GpsService.instance.ambilLokasi();
      if (!mounted) return;
      setState(() => _posisi = p);
      if (pusatkan) {
        try {
          _map.move(LatLng(p.latitude, p.longitude), 16);
        } catch (_) {
          // Peta belum siap (data masih dimuat); abaikan.
        }
      }
    } catch (e) {
      if (mounted && tampilkanError) showGpsError(context, e);
    } finally {
      if (mounted) setState(() => _cariPosisi = false);
    }
  }

  void _refresh() {
    setState(() {
      _selected = null;
      _future = KunjunganService.instance.getDenganKoordinat();
    });
    _perbaruiPosisi(tampilkanError: false);
  }

  double? _jarakKe(Kunjungan k) {
    final p = _posisi;
    if (p == null || !k.punyaKoordinat) return null;
    return GpsService.jarakMeter(
        p.latitude, p.longitude, k.latitude!, k.longitude!);
  }

  Future<void> _navigasi(Kunjungan k) async {
    final ok = await NavigationService.bukaRute(k.latitude!, k.longitude!);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigasi gagal: Google Maps tidak dapat dibuka')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Kunjungan'),
        actions: [
          IconButton(
            tooltip: 'Lokasi saya',
            icon: _cariPosisi
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            onPressed:
                _cariPosisi ? null : () => _perbaruiPosisi(pusatkan: true),
          ),
          IconButton(
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<Kunjungan>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat data: ${snapshot.error}'));
          }

          final rows = snapshot.data ?? [];
          final titik =
              rows.map((k) => LatLng(k.latitude!, k.longitude!)).toList();

          final MapOptions options;
          if (titik.length >= 2) {
            options = MapOptions(
              initialCameraFit: CameraFit.coordinates(
                coordinates: titik,
                padding: const EdgeInsets.fromLTRB(48, 110, 48, 80),
                maxZoom: 16,
              ),
              onTap: (_, __) => setState(() => _selected = null),
            );
          } else {
            options = MapOptions(
              initialCenter: titik.isEmpty
                  ? const LatLng(-7.2575, 112.7521) // Surabaya
                  : titik.first,
              initialZoom: titik.isEmpty ? 12 : 16,
              onTap: (_, __) => setState(() => _selected = null),
            );
          }

          final scheme = Theme.of(context).colorScheme;
          final markers = <Marker>[
            for (final k in rows)
              Marker(
                point: LatLng(k.latitude!, k.longitude!),
                width: 48,
                height: 48,
                child: GestureDetector(
                  onTap: () => setState(() => _selected = k),
                  child: Icon(
                    Icons.location_on,
                    size: 42,
                    color: _selected?.id == k.id ? Colors.orange : scheme.primary,
                  ),
                ),
              ),
            if (_posisi != null)
              Marker(
                point: LatLng(_posisi!.latitude, _posisi!.longitude),
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.circle, size: 18, color: Colors.blue),
                  ),
                ),
              ),
          ];

          return Stack(
            children: [
              FlutterMap(
                mapController: _map,
                options: options,
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.sikunjung',
                  ),
                  MarkerLayer(markers: markers),
                  const SimpleAttributionWidget(
                    source: Text('© OpenStreetMap contributors'),
                  ),
                ],
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Column(
                  children: [
                    const OfflineBanner(
                      message: 'Offline: peta online (OpenStreetMap) tidak dapat '
                          'dimuat. Marker dan data tetap tersedia.',
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          rows.isEmpty
                              ? 'Belum ada kunjungan yang memiliki koordinat GPS.'
                              : '${rows.length} lokasi kunjungan. Titik biru = posisi Anda'
                                  '${_posisi == null ? ' (belum terdeteksi)' : ''}.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_selected != null) _kartuInfo(_selected!),
            ],
          );
        },
      ),
    );
  }

  Widget _kartuInfo(Kunjungan k) {
    final jarak = _jarakKe(k);
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      k.namaPelanggan,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selected = null),
                  ),
                ],
              ),
              Text(k.alamat, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.straighten, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      jarak == null
                          ? 'Jarak: posisi Anda belum terdeteksi'
                          : 'Jarak dari posisi Anda: ${GpsService.formatJarak(jarak)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => KunjunganDetailPage(id: k.id!),
                        ),
                      ),
                      child: const Text('DETAIL'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () => _navigasi(k),
                      icon: const Icon(Icons.directions),
                      label: const Text('NAVIGASI'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
