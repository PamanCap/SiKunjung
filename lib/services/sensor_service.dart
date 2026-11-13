import 'dart:math';

/// Perhitungan kompas dari accelerometer + magnetometer.
class CompassCalculator {
  CompassCalculator._();


  static double? heading({
    required double ax,
    required double ay,
    required double az,
    required double mx,
    required double my,
    required double mz,
  }) {
    // arah timur
    var hx = my * az - mz * ay;
    var hy = mz * ax - mx * az;
    var hz = mx * ay - my * ax;
    final normH = sqrt(hx * hx + hy * hy + hz * hz);
    if (normH < 0.1) return null; // jatuh bebas / medan magnet tidak valid

    hx /= normH;
    hy /= normH;
    hz /= normH;

    final normA = sqrt(ax * ax + ay * ay + az * az);
    if (normA == 0) return null;
    final nax = ax / normA;
    final naz = az / normA;

    // arah utara magnetic
    final myNorth = naz * hx - nax * hz;

    final azimuth = atan2(hy, myNorth) * 180 / pi;
    return (azimuth + 360) % 360;
  }

  static double haluskan(double? lama, double baru, {double alpha = 0.2}) {
    if (lama == null) return baru;
    var selisih = baru - lama;
    while (selisih > 180) {
      selisih -= 360;
    }
    while (selisih < -180) {
      selisih += 360;
    }
    return (lama + alpha * selisih + 360) % 360;
  }

  static String arahMataAngin(double derajat) {
    const nama = [
      'Utara',
      'Timur Laut',
      'Timur',
      'Tenggara',
      'Selatan',
      'Barat Daya',
      'Barat',
      'Barat Laut',
    ];
    final idx = ((derajat % 360) / 45).round() % 8;
    return nama[idx];
  }

  /// Kekuatan medan magnet total
  static double kuatMedan(double x, double y, double z) =>
      sqrt(x * x + y * y + z * z);
}

/// Deteksi goyangan berdasarkan besar percepatan accelerometer.
class ShakeDetector {
  static const double _gravitasi = 9.81;

  final double ambang; 
  final int minimalGoyangan;
  final Duration jendela;
  final Duration cooldown;

  final List<DateTime> _hentakan = [];
  DateTime? _terakhir;

  ShakeDetector({
    this.ambang = 4,
    this.minimalGoyangan = 2,
    this.jendela = const Duration(milliseconds: 1000),
    this.cooldown = const Duration(milliseconds: 1500),
  });


  bool update(double x, double y, double z, {DateTime? now}) {
    final t = now ?? DateTime.now();

    if (_terakhir != null && t.difference(_terakhir!) < cooldown) return false;

    final selisih = (sqrt(x * x + y * y + z * z) - _gravitasi).abs();
    if (selisih < ambang) return false;

    _hentakan.removeWhere((e) => t.difference(e) > jendela);

    if (_hentakan.isNotEmpty &&
        t.difference(_hentakan.last) < const Duration(milliseconds: 60)) {
      return false;
    }

    _hentakan.add(t);
    if (_hentakan.length >= minimalGoyangan) {
      _hentakan.clear();
      _terakhir = t;
      return true;
    }
    return false;
  }
}