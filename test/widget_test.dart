import 'package:flutter_test/flutter_test.dart';

import 'package:sikunjung/models/kunjungan.dart';
import 'package:sikunjung/services/auth_service.dart';
import 'package:sikunjung/services/sensor_service.dart';

void main() {
  test('Kunjungan toMap() dan fromMap() konsisten', () {
    const k = Kunjungan(
      id: 1,
      userId: 2,
      namaPelanggan: 'Budi',
      alamat: 'Jl. Mawar 1',
      noHp: '081234567890',
      catatan: 'tes',
      latitude: -7.25,
      longitude: 112.75,
      akurasiGps: 5,
      status: 'Selesai',
      tanggal: '2026-01-01T10:00:00.000',
      createdAt: '2026-01-01T10:00:00.000',
      updatedAt: '2026-01-01T10:00:00.000',
    );
    final hasil = Kunjungan.fromMap(k.toMap());
    expect(hasil.namaPelanggan, 'Budi');
    expect(hasil.noHp, '081234567890');
    expect(hasil.latitude, -7.25);
    expect(hasil.status, 'Selesai');
    expect(hasil.punyaKoordinat, isTrue);
  });

  test('Password di-hash SHA-256 (64 hex) dan bukan plain text', () {
    final h = AuthService.hashPassword('Demo@12345', 'garam');
    expect(h.length, 64);
    expect(h.contains('Demo@12345'), isFalse);
    expect(h, AuthService.hashPassword('Demo@12345', 'garam'));
    expect(h, isNot(AuthService.hashPassword('Demo@12345', 'garam2')));
  });

  test('Arah mata angin', () {
    expect(CompassCalculator.arahMataAngin(0), 'Utara');
    expect(CompassCalculator.arahMataAngin(90), 'Timur');
    expect(CompassCalculator.arahMataAngin(185), 'Selatan');
    expect(CompassCalculator.arahMataAngin(359), 'Utara');
  });

  test('Kompas menghadap utara dan timur (ponsel datar)', () {
    final utara = CompassCalculator.heading(
      ax: 0,
      ay: 0,
      az: 9.8,
      mx: 0,
      my: 20,
      mz: -40,
    )!;
    final timur = CompassCalculator.heading(
      ax: 0,
      ay: 0,
      az: 9.8,
      mx: -20,
      my: 0,
      mz: -40,
    )!;
    expect(utara, closeTo(0, 0.5));
    expect(timur, closeTo(90, 0.5));
  });

  test('ShakeDetector: perlu dua hentakan dalam waktu singkat', () {
    final d = ShakeDetector();
    final t0 = DateTime(2026, 1, 1);
    expect(d.update(0, 0, 9.8, now: t0), isFalse);
    expect(d.update(20, 0, 10, now: t0), isFalse);
    expect(
      d.update(-20, 0, 10, now: t0.add(const Duration(milliseconds: 200))),
      isTrue,
    );
  });
}
