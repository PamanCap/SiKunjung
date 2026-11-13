import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/gps_service.dart';

/// Menampilkan SnackBar untuk kesalahan GPS
void showGpsError(BuildContext context, Object error) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();

  if (error is GpsException) {
    SnackBarAction? action;
    if (error.bukaPengaturanAplikasi) {
      action = SnackBarAction(label: 'PENGATURAN', onPressed: openAppSettings);
    } else if (error.bukaPengaturanLokasi) {
      action = SnackBarAction(
        label: 'AKTIFKAN',
        onPressed: Geolocator.openLocationSettings,
      );
    }
    messenger.showSnackBar(SnackBar(
      content: Text(error.message),
      action: action,
      duration: const Duration(seconds: 6),
    ));
    return;
  }
  messenger.showSnackBar(SnackBar(content: Text('GPS gagal: $error')));
}
