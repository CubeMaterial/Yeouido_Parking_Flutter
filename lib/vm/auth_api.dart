import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

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
      userId: _parseInt(json['user_id']),
      userEmail: json['user_email']?.toString() ?? '',
      userName: json['user_name']?.toString(),
      userPhone: json['user_phone']?.toString(),
      userDate: json['user_date']?.toString(),
    );
  }

  static int _parseInt(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
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
  static String get baseUrl => ApiConfig.fastApiBaseUrl;

  static Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final json = await _postJson('auth/login', {
      'user_email': email,
      'user_password': password,
    });
    return AuthSession.fromJson(json);
  }

  static Future<void> signup({
    required String email,
    required String password,
    required String phone,
    String? name,
  }) async {
    await _postJson('auth/users', {
      'user_email': email,
      'user_password': password,
      'user_name': name == null || name.isEmpty ? null : name,
      'user_phone': phone,
    });
  }

  static Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl/$path');

    try {
      final response = await http
          .post(
            uri,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5));
      final responseBody = utf8.decode(response.bodyBytes);
      final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      }

      throw AuthApiException(response.statusCode, _detailMessage(decoded));
    } on AuthApiException {
      rethrow;
    } on http.ClientException catch (error) {
      throw AuthApiException(
        0,
        'FastAPI 서버에 연결할 수 없습니다. 요청 주소: $baseUrl (${error.message})',
      );
    } on TimeoutException {
      throw AuthApiException(0, 'FastAPI 서버 응답 시간이 초과되었습니다. 요청 주소: $baseUrl');
    } catch (error) {
      throw AuthApiException(
        0,
        '요청 처리에 실패했습니다. 요청 주소: $baseUrl (${error.runtimeType})',
      );
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
