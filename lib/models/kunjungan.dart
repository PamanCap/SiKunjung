/// Model data kunjungan pelanggan
class Kunjungan {
  final int? id;
  final int userId;
  final String namaPelanggan;
  final String alamat;
  final String noHp;
  final String catatan;
  final double? latitude;
  final double? longitude;
  final double? akurasiGps;
  final String status; // Pending | Selesai | Batal
  final String tanggal; // ISO-8601
  final String createdAt;
  final String updatedAt;

  const Kunjungan({
    this.id,
    required this.userId,
    required this.namaPelanggan,
    required this.alamat,
    required this.noHp,
    this.catatan = '',
    this.latitude,
    this.longitude,
    this.akurasiGps,
    this.status = 'Pending',
    required this.tanggal,
    required this.createdAt,
    required this.updatedAt,
  });

  static const List<String> daftarStatus = ['Pending', 'Selesai', 'Batal'];

  bool get punyaKoordinat => latitude != null && longitude != null;

  DateTime? get tanggalDateTime => DateTime.tryParse(tanggal)?.toLocal();

  /// Objek -> Map (untuk insert/update ke SQLite).
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'nama_pelanggan': namaPelanggan,
      'alamat': alamat,
      'no_hp': noHp,
      'catatan': catatan,
      'latitude': latitude,
      'longitude': longitude,
      'akurasi_gps': akurasiGps,
      'status': status,
      'tanggal': tanggal,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Map (hasil query SQLite) -> objek.
  factory Kunjungan.fromMap(Map<String, Object?> map) {
    return Kunjungan(
      id: map['id'] as int?,
      userId: (map['user_id'] as num).toInt(),
      namaPelanggan: map['nama_pelanggan'] as String? ?? '',
      alamat: map['alamat'] as String? ?? '',
      noHp: map['no_hp'] as String? ?? '',
      catatan: map['catatan'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      akurasiGps: (map['akurasi_gps'] as num?)?.toDouble(),
      status: map['status'] as String? ?? 'Pending',
      tanggal: map['tanggal'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }

  Kunjungan copyWith({
    String? namaPelanggan,
    String? alamat,
    String? noHp,
    String? catatan,
    double? latitude,
    double? longitude,
    double? akurasiGps,
    String? status,
    String? updatedAt,
  }) {
    return Kunjungan(
      id: id,
      userId: userId,
      namaPelanggan: namaPelanggan ?? this.namaPelanggan,
      alamat: alamat ?? this.alamat,
      noHp: noHp ?? this.noHp,
      catatan: catatan ?? this.catatan,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      akurasiGps: akurasiGps ?? this.akurasiGps,
      status: status ?? this.status,
      tanggal: tanggal,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
