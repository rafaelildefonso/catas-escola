import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Helper interno para fallback do dotenv
  static String _fallback(String key, {String defaultValue = ''}) {
    try {
      if (dotenv.isInitialized) {
        return dotenv.env[key] ?? defaultValue;
      }
    } catch (_) {}
    return defaultValue;
  }

  static String get apiBaseUrl {
    const injected = String.fromEnvironment('API_BASE_URL');
    String url = injected.isNotEmpty ? injected : _fallback('API_BASE_URL', defaultValue: 'http://localhost:8000/api/v1');

    // If on Web, localhost works fine
    if (kIsWeb) return url;

    // If on Android and URL is localhost, replace with emulator IP
    if (Platform.isAndroid && url.contains('localhost')) {
      return url.replaceAll('localhost', '10.0.2.2');
    }

    return url;
  }

  static String get cloudinaryCloudName {
    const injected = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
    return injected.isNotEmpty ? injected : _fallback('CLOUDINARY_CLOUD_NAME');
  }

  static bool get isDemoMode {
    const injected = String.fromEnvironment('DEMO_MODE');
    final val = injected.isNotEmpty ? injected : _fallback('DEMO_MODE');
    return val == 'true';
  }

  static String? get webClientId {
    const injected = String.fromEnvironment('WEB_CLIENT_ID');
    return injected.isNotEmpty ? injected : _fallback('WEB_CLIENT_ID');
  }

  static String? get androidClientId {
    const injected = String.fromEnvironment('ANDROID_CLIENT_ID');
    return injected.isNotEmpty ? injected : _fallback('ANDROID_CLIENT_ID');
  }

  static String? get iosClientId {
    const injected = String.fromEnvironment('IOS_CLIENT_ID');
    return injected.isNotEmpty ? injected : _fallback('IOS_CLIENT_ID');
  }
}
