import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:yeouido_parking_flutter/model/parking.dart';

import 'api_config.dart';

class ParkingApi {
  static String get baseUrl => ApiConfig.fastApiBaseUrl;

  static String _normalizedBase() => baseUrl;

  static Future<List<Parking>> fetchParkinglots() async {
    final uri = Uri.parse('${_normalizedBase()}/parking');
    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw Exception('Unexpected response');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Parking.fromJson)
        .toList(growable: false);
  }

  static Future<Parking> fetchParkingDetail(int parkingId) async {
    final uri = Uri.parse('${_normalizedBase()}/parking/$parkingId');
    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected response');
    }

    return Parking.fromJson(decoded);
  }

  static Future<int> createParkinglot({
    required double lat,
    required double lng,
    required String name,
    required int maxCount,
  }) async {
    final uri = Uri.parse('${_normalizedBase()}/parking');
    final response = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'parking_lat': lat,
            'parking_lng': lng,
            'parking_name': name,
            'parking_max': maxCount,
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
    final id = int.tryParse(
      (decoded['parking_id'] ?? decoded['parkinglot_id'])?.toString() ?? '',
    );
    if (id == null) throw Exception('Invalid parking id');
    return id;
  }

  static Future<void> updateParkinglot({
    required int parkingId,
    required double lat,
    required double lng,
    required String name,
    required int maxCount,
  }) async {
    final uri = Uri.parse('${_normalizedBase()}/parking/$parkingId');
    final response = await http
        .patch(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'parking_lat': lat,
            'parking_lng': lng,
            'parking_name': name,
            'parking_max': maxCount,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }
  }

  static Future<void> deleteParkinglot(int parkingId) async {
    final uri = Uri.parse('${_normalizedBase()}/parking/$parkingId');
    final response = await http.delete(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }
  }
}
