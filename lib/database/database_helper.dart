import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/kunjungan.dart';
import '../models/user.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const String dbName = 'sikunjung.db';
  static const int _dbVersion = 2;
  static Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<String> get dbPath async => join(await getDatabasesPath(), dbName);

  Future<Database> _open() async {
    return openDatabase(
      await dbPath,
      version: _dbVersion,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await _createUsers(db);
        await _createKunjungan(db, 'kunjungan');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _migrateV1toV2(db);
      },
    );
  }

  Future<void> _createUsers(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        nama TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL,
        created_at TEXT NOT NULL
      )''');
  }

  Future<void> _createKunjungan(Database db, String table) async {
    await db.execute('''
      CREATE TABLE $table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        nama_pelanggan TEXT NOT NULL,
        alamat TEXT NOT NULL,
        no_hp TEXT NOT NULL,
        catatan TEXT,
        latitude REAL,
        longitude REAL,
        akurasi_gps REAL,
        status TEXT NOT NULL DEFAULT 'Pending',
        tanggal TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )''');
  }

  Future<void> _migrateV1toV2(Database db) async {
    await _createKunjungan(db, 'kunjungan_baru');
    await db.execute('''
      INSERT INTO kunjungan_baru (id, user_id, nama_pelanggan, alamat, no_hp,
        catatan, latitude, longitude, akurasi_gps, status, tanggal,
        created_at, updated_at)
      SELECT id, user_id, nama_pelanggan, alamat, COALESCE(nomor_telepon, ''),
        catatan, latitude, longitude, akurasi_gps, status, tanggal_kunjungan,
        created_at, updated_at
      FROM kunjungan''');
    await db.execute('DROP TABLE kunjungan');
    await db.execute('ALTER TABLE kunjungan_baru RENAME TO kunjungan');
  }

  // USERS

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    return rows.isEmpty ? null : User.fromMap(rows.first);
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : User.fromMap(rows.first);
  }

  Future<int> insertUser(User user) async {
    final db = await database;
    final map = user.toMap()..remove('id');
    return db.insert('users', map);
  }

  Future<int> updateUserPassword(int id, String hash, String salt) async {
    final db = await database;
    return db.update(
      'users',
      {'password_hash': hash, 'password_salt': salt},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // KUNJUNGAN

  // CREATE
  Future<int> insertKunjungan(Kunjungan k) async {
    final db = await database;
    final map = k.toMap()..remove('id');
    return db.insert('kunjungan', map);
  }

  // READ (daftar, dengan pencarian opsional)
  Future<List<Kunjungan>> queryKunjungan(int userId, {String? cari}) async {
    final db = await database;
    final keyword = (cari ?? '').trim();

    final List<Map<String, Object?>> rows;
    if (keyword.isEmpty) {
      rows = await db.query(
        'kunjungan',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'tanggal DESC, id DESC',
      );
    } else {
      // Karakter khusus LIKE di-escape; nilai tetap dikirim lewat whereArgs.
      final escaped = keyword
          .replaceAll(r'\', r'\\')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_');
      final like = '%$escaped%';
      rows = await db.query(
        'kunjungan',
        where:
            "user_id = ? AND (nama_pelanggan LIKE ? ESCAPE '\\' "
            "OR alamat LIKE ? ESCAPE '\\' OR no_hp LIKE ? ESCAPE '\\')",
        whereArgs: [userId, like, like, like],
        orderBy: 'tanggal DESC, id DESC',
      );
    }
    return rows.map(Kunjungan.fromMap).toList();
  }

  // READ (satu data)
  Future<Kunjungan?> getKunjungan(int id, int userId) async {
    final db = await database;
    final rows = await db.query(
      'kunjungan',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
      limit: 1,
    );
    return rows.isEmpty ? null : Kunjungan.fromMap(rows.first);
  }

  // UPDATE
  Future<int> updateKunjungan(Kunjungan k) async {
    final db = await database;
    final map = k.toMap()
      ..remove('id')
      ..remove('user_id')
      ..remove('created_at');
    return db.update(
      'kunjungan',
      map,
      where: 'id = ? AND user_id = ?',
      whereArgs: [k.id, k.userId],
    );
  }

  // DELETE
  Future<int> deleteKunjungan(int id, int userId) async {
    final db = await database;
    return db.delete(
      'kunjungan',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  /// Jumlah kunjungan per status, misalnya {'Pending': 2, 'Selesai': 5}.
  Future<Map<String, int>> hitungPerStatus(int userId) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT status, COUNT(*) AS jumlah FROM kunjungan '
      'WHERE user_id = ? GROUP BY status',
      [userId],
    );
    return {
      for (final r in rows) r['status'] as String: (r['jumlah'] as num).toInt(),
    };
  }
}
