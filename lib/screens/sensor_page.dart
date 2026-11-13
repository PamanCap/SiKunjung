import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../services/sensor_service.dart';
import '../widgets/compass_widget.dart';

class SensorPage extends StatefulWidget {
  const SensorPage({super.key});

  @override
  State<SensorPage> createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  static const _timeout = Duration(seconds: 3);

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magSub;
  Timer? _timer;

  AccelerometerEvent? _accel;
  GyroscopeEvent? _gyro;
  MagnetometerEvent? _mag;

  // true = sensor dipastikan tidak ada / tidak mengirim data.
  bool _accelTidakAda = false;
  bool _gyroTidakAda = false;
  bool _magTidakAda = false;

  double? _heading;
  bool _aktif = false;

  @override
  void initState() {
    super.initState();
    _mulai();
  }

  void _mulai() {
    _berhenti();
    _aktif = true;
    _accelTidakAda = _gyroTidakAda = _magTidakAda = false;

    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen(
      (e) {
        if (!mounted) return;
        setState(() {
          _accel = e;
          _hitungKompas();
        });
      },
      onError: (Object _) {
        if (mounted) setState(() => _accelTidakAda = true);
      },
    );

    _gyroSub = gyroscopeEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen(
      (e) {
        if (mounted) setState(() => _gyro = e);
      },
      onError: (Object _) {
        if (mounted) setState(() => _gyroTidakAda = true);
      },
    );

    _magSub = magnetometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen(
      (e) {
        if (!mounted) return;
        setState(() {
          _mag = e;
          _hitungKompas();
        });
      },
      onError: (Object _) {
        if (mounted) setState(() => _magTidakAda = true);
      },
    );

    // Bila setelah beberapa detik belum ada data, anggap sensor tidak ada.
    _timer = Timer(_timeout, () {
      if (!mounted) return;
      setState(() {
        if (_accel == null) _accelTidakAda = true;
        if (_gyro == null) _gyroTidakAda = true;
        if (_mag == null) _magTidakAda = true;
      });
    });
  }

  void _berhenti() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
    _timer?.cancel();
    _accelSub = _gyroSub = _magSub = null;
    _timer = null;
    _aktif = false;
  }

  void _hitungKompas() {
    final a = _accel;
    final m = _mag;
    if (a == null || m == null) return;
    final h = CompassCalculator.heading(
      ax: a.x, ay: a.y, az: a.z,
      mx: m.x, my: m.y, mz: m.z,
    );
    if (h != null) _heading = CompassCalculator.haluskan(_heading, h);
  }

  @override
  void dispose() {
    _berhenti();
    super.dispose();
  }

  String _f(double? v) => v == null ? '-' : v.toStringAsFixed(2);

  Widget _kartuSensor({
    required IconData ikon,
    required String judul,
    required String deskripsi,
    required String satuan,
    required bool tidakAda,
    required double? x,
    required double? y,
    required double? z,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(ikon, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(judul,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(deskripsi, style: TextStyle(color: scheme.outline)),
            const SizedBox(height: 12),
            if (tidakAda && x == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Perangkat ini tidak memiliki sensor $judul '
                  '(atau sensor tidak mengirim data).',
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              )
            else
              Row(
                children: [
                  _nilai('X', _f(x), satuan, Colors.red),
                  const SizedBox(width: 8),
                  _nilai('Y', _f(y), satuan, Colors.green),
                  const SizedBox(width: 8),
                  _nilai('Z', _f(z), satuan, Colors.blue),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _nilai(String sumbu, String nilai, String satuan, Color warna) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: warna.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(sumbu,
                style: TextStyle(color: warna, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(nilai,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Text(satuan,
                style: TextStyle(
                    fontSize: 11, color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      ),
    );
  }

  Widget _kartuKompas() {
    final scheme = Theme.of(context).colorScheme;
    final h = _heading;
    final tidakAda = _magTidakAda || _accelTidakAda;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.explore, color: scheme.primary),
                const SizedBox(width: 10),
                const Text('Kompas',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Dihitung dari magnetometer + accelerometer.',
                style: TextStyle(color: scheme.outline),
              ),
            ),
            const SizedBox(height: 12),
            if (tidakAda && h == null)
              Text(
                'Kompas tidak tersedia: perangkat tidak memiliki magnetometer '
                'atau accelerometer.',
                style: TextStyle(color: scheme.error),
              )
            else ...[
              CompassWidget(heading: h, size: 190),
              const SizedBox(height: 10),
              Text(
                h == null
                    ? '-'
                    : '${h.round()}°  ${CompassCalculator.arahMataAngin(h)}',
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              if (_mag != null)
                Text(
                  'Kuat medan: ${CompassCalculator.kuatMedan(_mag!.x, _mag!.y, _mag!.z).toStringAsFixed(1)} µT',
                  style: TextStyle(color: scheme.outline),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kartuSpesifikasi() {
    Widget baris(String a, String b, String c) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  flex: 3,
                  child: Text(a,
                      style: const TextStyle(fontWeight: FontWeight.w600))),
              Expanded(flex: 4, child: Text(b)),
              Expanded(flex: 4, child: Text(c)),
            ],
          ),
        );
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.menu_book_outlined),
        title: const Text('Spesifikasi teknis sensor'),
        subtitle: const Text('Nilai tipikal, berbeda tiap perangkat'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          baris('Sensor', 'Satuan & rentang', 'Resolusi / sampling'),
          const Divider(),
          baris('Accelerometer', 'm/s²; ±2g–±16g', '16 bit; 50–500 Hz'),
          baris('Gyroscope', 'rad/s; ±250–±2000 °/s', '16 bit; 100–1000 Hz'),
          baris('Magnetometer', 'µT; ±4900 µT', '≈0,15 µT; 10–100 Hz'),
          baris('GPS (GNSS)', 'derajat lat/long; akurasi 3–10 m',
              '1 Hz; sinyal satelit'),
          const SizedBox(height: 8),
          const Text(
            'Accelerometer mengukur percepatan (termasuk gravitasi ≈ 9,8 m/s²), '
            'gyroscope mengukur kecepatan rotasi, magnetometer mengukur medan '
            'magnet bumi untuk arah kompas, dan GPS menentukan posisi dari '
            'satelit.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Sensor Perangkat')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Icon(Icons.sensors,
                  size: 18, color: _aktif ? Colors.green : scheme.outline),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_aktif
                    ? 'Pembacaan sensor aktif'
                    : 'Pembacaan dihentikan'),
              ),
              OutlinedButton(
                onPressed: () => setState(_aktif ? _berhenti : _mulai),
                child: Text(_aktif ? 'HENTIKAN' : 'MULAI'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _kartuSensor(
            ikon: Icons.screen_rotation,
            judul: 'Accelerometer',
            deskripsi: 'Percepatan perangkat termasuk gravitasi.',
            satuan: 'm/s²',
            tidakAda: _accelTidakAda,
            x: _accel?.x,
            y: _accel?.y,
            z: _accel?.z,
          ),
          _kartuSensor(
            ikon: Icons.threesixty,
            judul: 'Gyroscope',
            deskripsi: 'Kecepatan rotasi pada sumbu X, Y, dan Z.',
            satuan: 'rad/s',
            tidakAda: _gyroTidakAda,
            x: _gyro?.x,
            y: _gyro?.y,
            z: _gyro?.z,
          ),
          _kartuSensor(
            ikon: Icons.waves,
            judul: 'Magnetometer',
            deskripsi: 'Kuat medan magnet pada sumbu X, Y, dan Z.',
            satuan: 'µT',
            tidakAda: _magTidakAda,
            x: _mag?.x,
            y: _mag?.y,
            z: _mag?.z,
          ),
          _kartuKompas(),
          _kartuSpesifikasi(),
        ],
      ),
    );
  }
}
