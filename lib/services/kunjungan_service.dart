import '../database/database_helper.dart';
import '../models/kunjungan.dart';
import 'auth_service.dart';

/// Lapisan antara UI dan DatabaseHelper
class KunjunganService {
  KunjunganService._();
  static final KunjunganService instance = KunjunganService._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<Kunjungan>> getAll({String? cari}) async {
    final uid = await AuthService.instance.requireUserId();
    return _db.queryKunjungan(uid, cari: cari);
  }

  Future<Kunjungan?> getById(int id) async {
    final uid = await AuthService.instance.requireUserId();
    return _db.getKunjungan(id, uid);
  }

  Future<List<Kunjungan>> getDenganKoordinat() async {
    final all = await getAll();
    return all.where((k) => k.punyaKoordinat).toList();
  }

  Future<int> tambah({
    required String nama,
    required String alamat,
    required String noHp,
    required String catatan,
    required String status,
    double? latitude,
    double? longitude,
    double? akurasi,
  }) async {
    final uid = await AuthService.instance.requireUserId();
    final now = DateTime.now().toIso8601String();
    return _db.insertKunjungan(Kunjungan(
      userId: uid,
      namaPelanggan: nama.trim(),
      alamat: alamat.trim(),
      noHp: noHp.trim(),
      catatan: catatan.trim(),
      status: status,
      latitude: latitude,
      longitude: longitude,
      akurasiGps: akurasi,
      tanggal: now,
      createdAt: now,
      updatedAt: now,
    ));
  }

  Future<int> ubah(Kunjungan lama, {
    required String nama,
    required String alamat,
    required String noHp,
    required String catatan,
    required String status,
    double? latitude,
    double? longitude,
    double? akurasi,
  }) {
    return _db.updateKunjungan(Kunjungan(
      id: lama.id,
      userId: lama.userId,
      namaPelanggan: nama.trim(),
      alamat: alamat.trim(),
      noHp: noHp.trim(),
      catatan: catatan.trim(),
      status: status,
      latitude: latitude,
      longitude: longitude,
      akurasiGps: akurasi,
      tanggal: lama.tanggal,
      createdAt: lama.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    ));
  }

  Future<int> hapus(int id) async {
    final uid = await AuthService.instance.requireUserId();
    return _db.deleteKunjungan(id, uid);
  }

  Future<Map<String, int>> ringkasan() async {
    final uid = await AuthService.instance.requireUserId();
    return _db.hitungPerStatus(uid);
  }
}
