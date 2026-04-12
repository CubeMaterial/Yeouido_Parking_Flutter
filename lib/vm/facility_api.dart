import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:yeouido_parking_flutter/model/facility.dart';

class FacilityApi {
  static const String baseUrl = String.fromEnvironment(
    'FASTAPI_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static String _normalizedBase() => baseUrl.replaceFirst(RegExp(r'/$'), '');

  static Future<List<Facility>> fetchFacilities() async {
    final uri = Uri.parse('${_normalizedBase()}/facilities');
    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw Exception('Unexpected response');
    }

    return decoded.whereType<Map<String, dynamic>>().map(Facility.fromJson).toList(growable: false);
  }

  static Future<Facility> fetchFacilityDetail(int facilityId) async {
    final uri = Uri.parse('${_normalizedBase()}/facilities/$facilityId');
    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected response');
    }

    return Facility.fromJson(decoded);
  }

  static Future<int> createFacility({
    required double lat,
    required double lng,
    required String name,
    required String info,
    required String image,
    required int possible,
  }) async {
    final uri = Uri.parse('${_normalizedBase()}/facilities');
    final response = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'f_lat': lat,
            'f_long': lng,
            'f_name': name,
            'f_info': info,
            'f_image': image,
            'f_possible': possible,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected response');
    }
    final id = int.tryParse(decoded['f_id']?.toString() ?? '');
    if (id == null) throw Exception('Invalid facility id');
    return id;
  }

  static Future<void> updateFacility({
    required int facilityId,
    required double lat,
    required double lng,
    required String name,
    required String info,
    required String image,
    required int possible,
  }) async {
    final uri = Uri.parse('${_normalizedBase()}/facilities/$facilityId');
    final response = await http
        .patch(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'f_lat': lat,
            'f_long': lng,
            'f_name': name,
            'f_info': info,
            'f_image': image,
            'f_possible': possible,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }
  }
}
