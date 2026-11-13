/// Model petugas lapangan (tabel `users`).
class User {
  final int? id;
  final String username;
  final String nama;
  final String passwordHash;
  final String passwordSalt;
  final String createdAt;

  const User({
    this.id,
    required this.username,
    required this.nama,
    required this.passwordHash,
    required this.passwordSalt,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'username': username,
      'nama': nama,
      'password_hash': passwordHash,
      'password_salt': passwordSalt,
      'created_at': createdAt,
    };
  }

  factory User.fromMap(Map<String, Object?> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String? ?? '',
      nama: map['nama'] as String? ?? '',
      passwordHash: map['password_hash'] as String? ?? '',
      passwordSalt: map['password_salt'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}
