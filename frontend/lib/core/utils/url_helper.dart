import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlHelper {
  static String resolveUrl(String url) {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && !origin.startsWith('file://')) {
        if (Uri.base.host != 'localhost' && Uri.base.host != '127.0.0.1') {
          if (url.startsWith('http://localhost:5000')) {
            return url.replaceFirst('http://localhost:5000', origin);
          } else if (url.startsWith('/')) {
            return '$origin$url';
          }
        }
      }
    }
    return url;
  }

  static Future<void> openUrl(String url) async {
    final resolved = resolveUrl(url);
    final uri = Uri.parse(resolved);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        await launchUrl(uri);
      }
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (e) {
        debugPrint('UrlHelper launch error: $e');
      }
    }
  }
}
