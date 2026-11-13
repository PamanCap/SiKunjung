import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../database/database_helper.dart';
import '../models/user.dart';
import 'preferences_service.dart';

/// Autentikasi petugas.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'sikunjung_session_token';
  static const String _userIdKey = 'sikunjung_session_user_id';

  static String hashPassword(String password, String salt) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }

  static String _randomBase64(int bytes) {
    final rnd = Random.secure();
    return base64Url.encode(List<int>.generate(bytes, (_) => rnd.nextInt(256)));
  }

  static bool _sama(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  /// Membuat akun uji
  Future<void> createDemoAccount() async {
    final db = DatabaseHelper.instance;
    final salt = _randomBase64(16);
    final hash = hashPassword('12345678', salt);

    final existing = await db.getUserByUsername('pamancecuy');
    if (existing == null) {
      await db.insertUser(User(
        username: 'pamancecuy',
        nama: 'Petugas Lapangan',
        passwordHash: hash,
        passwordSalt: salt,
        createdAt: DateTime.now().toIso8601String(),
      ));
    } else if (existing.passwordHash.length != 64) {
      await db.updateUserPassword(existing.id!, hash, salt);
    }
  }

  /// Mengembalikan data user bila login berhasil, null bila gagal.
  Future<User?> login(String username, String password) async {
    final user = await DatabaseHelper.instance.getUserByUsername(username.trim());
    if (user == null) return null;

    final actual = hashPassword(password, user.passwordSalt);
    if (!_sama(actual, user.passwordHash)) return null;

    // Token sesi acak disimpan terenkripsi.
    await _storage.write(key: _tokenKey, value: _randomBase64(32));
    await _storage.write(key: _userIdKey, value: '${user.id}');
    await PreferencesService.instance.simpanLogin(user.username, user.nama);
    return user;
  }

  Future<User?> currentUser() async {
    final token = await _storage.read(key: _tokenKey);
    final rawId = await _storage.read(key: _userIdKey);
    final id = int.tryParse(rawId ?? '');
    if (token == null || token.isEmpty || id == null) return null;

    final user = await DatabaseHelper.instance.getUserById(id);
    if (user == null) {
      await logout();
      return null;
    }
    return user;
  }

  Future<int> requireUserId() async {
    final user = await currentUser();
    if (user == null) throw StateError('Sesi berakhir, silakan login ulang');
    return user.id!;
  }

  Future<bool> sudahLogin() async => (await currentUser()) != null;

  /// Menghapus sesi login.
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
  }
}
