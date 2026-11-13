import 'package:url_launcher/url_launcher.dart';

class NavigationService {
  NavigationService._();

  /// Membuka rute menuju koordinat pelanggan di Google Maps.
  static Future<bool> bukaRute(double lat, double lng) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$lat,$lng',
      'travelmode': 'driving',
    });
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
