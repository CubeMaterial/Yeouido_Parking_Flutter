import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'api_config.dart';

class AdminAuthSession {
  final int adminId;
  final String adminEmail;
  final String? adminName;

  const AdminAuthSession({
    required this.adminId,
    required this.adminEmail,
    this.adminName,
  });

  factory AdminAuthSession.fromJson(Map<String, dynamic> json) {
    return AdminAuthSession(
      adminId: _parseInt(json['admin_id']),
      adminEmail: json['admin_email']?.toString() ?? '',
      adminName: json['admin_name']?.toString(),
    );
  }

  static int _parseInt(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AdminAuthApiException implements Exception {
  final int statusCode;
  final String message;

  const AdminAuthApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class AdminAuthApi {
  static String get baseUrl => ApiConfig.fastApiBaseUrl;

  static Future<AdminAuthSession> login({
    required String email,
    required String password,
  }) async {
    final json = await _postJson('auth/admin/login', {
      'admin_email': email,
      'admin_password': password,
    });
    return AdminAuthSession.fromJson(json);
  }

  static Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final client = HttpClient();

    try {
      final uri = Uri.parse('$baseUrl/$path');
      final request = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 5));

      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.write(jsonEncode(body));

      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      final responseBody = await response.transform(utf8.decoder).join();
      final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      }

      throw AdminAuthApiException(response.statusCode, _detailMessage(decoded));
    } on AdminAuthApiException {
      rethrow;
    } on SocketException {
      throw const AdminAuthApiException(
        0,
        'FastAPI 서버에 연결할 수 없습니다. 서버 실행과 주소를 확인해 주세요.',
      );
    } on TimeoutException {
      throw const AdminAuthApiException(0, 'FastAPI 서버 응답 시간이 초과되었습니다.');
    } finally {
      client.close(force: true);
    }
  }

  static String _detailMessage(Object? decoded) {
    if (decoded is Map<String, dynamic>) {
      final detail = decoded['detail'];

      if (detail is String) {
        return detail;
      }

      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map<String, dynamic> && first['msg'] is String) {
          return first['msg'] as String;
        }
      }
    }

    return '요청 처리에 실패했습니다.';
  }
}
