import 'dart:async';
import 'dart:convert';
import 'dart:io';

class AuthSession {
  final int userId;
  final String userEmail;
  final String? userName;
  final String? userPhone;
  final String? userDate;

  const AuthSession({
    required this.userId,
    required this.userEmail,
    this.userName,
    this.userPhone,
    this.userDate,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      userId: json['user_id'] as int,
      userEmail: json['user_email'] as String,
      userName: json['user_name'] as String?,
      userPhone: json['user_phone'] as String?,
      userDate: json['user_date']?.toString(),
    );
  }
}

class AuthApiException implements Exception {
  final int statusCode;
  final String message;

  const AuthApiException(this.statusCode, this.message);

  bool get isNotRegistered => statusCode == 404;

  @override
  String toString() => message;
}

class AuthApi {
  static const String baseUrl = String.fromEnvironment(
    'FASTAPI_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final json = await _postJson(
      'auth/login',
      {
        'user_email': email,
        'user_password': password,
      },
    );
    return AuthSession.fromJson(json);
  }

  static Future<void> signup({
    required String email,
    required String password,
    required String phone,
    String? name,
  }) async {
    await _postJson(
      'auth/users',
      {
        'user_email': email,
        'user_password': password,
        'user_name': name == null || name.isEmpty ? null : name,
        'user_phone': phone,
      },
    );
  }

  static Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final client = HttpClient();

    try {
      final uri = Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}/$path');
      final request = await client.postUrl(uri).timeout(
            const Duration(seconds: 5),
          );

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

      throw AuthApiException(
        response.statusCode,
        _detailMessage(decoded),
      );
    } on AuthApiException {
      rethrow;
    } on SocketException {
      throw const AuthApiException(
        0,
        'FastAPI 서버에 연결할 수 없습니다. 서버 실행과 주소를 확인해 주세요.',
      );
    } on TimeoutException {
      throw const AuthApiException(
        0,
        'FastAPI 서버 응답 시간이 초과되었습니다.',
      );
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
