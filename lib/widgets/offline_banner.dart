import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Banner peringatan yang muncul otomatis saat perangkat tidak punya koneksi.
class OfflineBanner extends StatefulWidget {
  final String message;

  const OfflineBanner({
    super.key,
    this.message =
        'Offline — tidak ada koneksi internet. Data kunjungan tetap '
        'tersimpan di perangkat.',
  });

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _offline = false;

  static bool _isOffline(List<ConnectivityResult> r) =>
      r.isEmpty || r.every((e) => e == ConnectivityResult.none);

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then((r) {
      if (mounted) setState(() => _offline = _isOffline(r));
    });
    _sub = Connectivity().onConnectivityChanged.listen((r) {
      if (mounted) setState(() => _offline = _isOffline(r));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: !_offline
          ? const SizedBox.shrink(key: ValueKey('online'))
          : Container(
              key: const ValueKey('offline'),
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_off_rounded, color: scheme.onErrorContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
