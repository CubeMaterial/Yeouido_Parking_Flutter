import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _configuredFastApiBaseUrl = String.fromEnvironment(
    'FASTAPI_BASE_URL',
  );

  static String get fastApiBaseUrl {
    if (_configuredFastApiBaseUrl.isNotEmpty) {
      return _withoutTrailingSlash(_configuredFastApiBaseUrl);
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:8000',
      TargetPlatform.iOS => 'http://127.0.0.1:8000',
      _ => 'http://127.0.0.1:8000',
    };
  }

  static String _withoutTrailingSlash(String value) {
    return value.trim().replaceFirst(RegExp(r'/$'), '');
  }
}
