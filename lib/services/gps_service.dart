import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Kesalahan GPS dengan pesan yang siap ditampilkan ke pengguna.
class GpsException implements Exception {
  final String message;

  final bool bukaPengaturanAplikasi;

  final bool bukaPengaturanLokasi;

  const GpsException(
    this.message, {
    this.bukaPengaturanAplikasi = false,
    this.bukaPengaturanLokasi = false,
  });

  @override
  String toString() => message;
}

class GpsService {
  GpsService._();
  static final GpsService instance = GpsService._();

  /// Meminta izin lokasi saat runtime
  Future<Position> ambilLokasi() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const GpsException(
        'Layanan lokasi (GPS) perangkat mati. Aktifkan terlebih dahulu.',
        bukaPengaturanLokasi: true,
      );
    }

    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }
    if (status.isPermanentlyDenied) {
      throw const GpsException(
        'Izin lokasi ditolak permanen. Aktifkan di Pengaturan aplikasi.',
        bukaPengaturanAplikasi: true,
      );
    }
    if (!status.isGranted) {
      throw const GpsException(
        'Izin lokasi ditolak. Fitur GPS tidak dapat digunakan.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );
    } catch (_) {
      throw const GpsException(
        'Gagal membaca lokasi. Pastikan GPS aktif dan sinyal memadai.',
      );
    }
  }

  /// Jarak dua titik dalam meter
  static double jarakMeter(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  static String formatJarak(double meter) {
    if (meter < 1000) return '${meter.round()} m';
    return '${(meter / 1000).toStringAsFixed(2).replaceAll('.', ',')} km';
  }
}
