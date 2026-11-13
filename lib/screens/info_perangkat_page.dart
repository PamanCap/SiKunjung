import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../database/database_helper.dart';

class InfoPerangkatPage extends StatefulWidget {
  const InfoPerangkatPage({super.key});

  @override
  State<InfoPerangkatPage> createState() => _InfoPerangkatPageState();
}

class _InfoData {
  final List<MapEntry<String, String>> perangkat;
  final List<MapEntry<String, String>> aplikasi;
  final List<MapEntry<String, String>> platform;

  _InfoData(this.perangkat, this.aplikasi, this.platform);
}

class _InfoPerangkatPageState extends State<InfoPerangkatPage> {
  late Future<_InfoData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_InfoData> _load() async {
    final pkg = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();

    final List<MapEntry<String, String>> perangkat;
    if (Platform.isAndroid) {
      final a = await deviceInfo.androidInfo;
      perangkat = [
        const MapEntry('Sistem operasi', 'Android'),
        MapEntry('Versi Android', a.version.release),
        MapEntry('API level', '${a.version.sdkInt}'),
        MapEntry('Merek', a.brand),
        MapEntry('Produsen', a.manufacturer),
        MapEntry('Model', a.model),
        MapEntry(
          'Jenis perangkat',
          a.isPhysicalDevice ? 'Perangkat fisik' : 'Emulator',
        ),
      ];
    } else {
      perangkat = [
        MapEntry('Sistem operasi', Platform.operatingSystem),
        MapEntry('Versi OS', Platform.operatingSystemVersion),
      ];
    }

    final aplikasi = [
      MapEntry('Nama aplikasi', pkg.appName),
      MapEntry('Versi', pkg.version),
      MapEntry('Build number', pkg.buildNumber),
      MapEntry('Package name', pkg.packageName),
      MapEntry('Database', await DatabaseHelper.instance.dbPath),
    ];

    final platform = [
      const MapEntry('Framework', 'Flutter'),
      const MapEntry('Bahasa pemrograman', 'Dart'),
      MapEntry('Versi Dart', Platform.version.split(' ').first),
      const MapEntry('Target platform', 'Android'),
    ];

    return _InfoData(perangkat, aplikasi, platform);
  }

  Widget _bagian(
    IconData ikon,
    String judul,
    List<MapEntry<String, String>> data,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(ikon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  judul,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...data.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        e.key,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        e.value,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Info Perangkat')),
      body: FutureBuilder<_InfoData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Gagal membaca info perangkat: ${snapshot.error}'),
              ),
            );
          }
          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _bagian(Icons.phone_android, 'Perangkat', data.perangkat),
              _bagian(Icons.apps, 'Aplikasi', data.aplikasi),
              _bagian(Icons.code, 'Platform & Bahasa', data.platform),
              const Card(
                elevation: 0,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Flutter SDK menyediakan framework, compiler Dart, dan '
                    'alat build (flutter build apk). Android SDK menyediakan '
                    'platform-tools, build-tools, dan emulator yang dipakai '
                    'Gradle untuk mengemas aplikasi menjadi APK untuk Android.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}