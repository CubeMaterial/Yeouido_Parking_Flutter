import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

class ParkingLotStatus {
  const ParkingLotStatus({
    required this.name,
    required this.total,
    required this.used,
    required this.available,
  });

  final String name;
  final int total;
  final int used;
  final int available;

  factory ParkingLotStatus.fromJson(Map<String, dynamic> json) {
    return ParkingLotStatus(
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : '주차장',
      total: (json['total'] as num?)?.toInt() ?? 0,
      used: (json['used'] as num?)?.toInt() ?? 0,
      available: (json['available'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'total': total,
        'used': used,
        'available': available,
      };
}

class IHangangParkingClient {
  static const String region8Url = 'https://www.ihangangpark.kr/parking/region/region8';
  static const Duration _timeout = Duration(seconds: 8);

  /// Flutter Web에서 CORS 때문에 원본 사이트로 직접 요청이 막힐 수 있어요.
  /// 그런 경우 프록시(예: FastAPI)에서 HTML을 가져와 JSON으로 내려주는 방식을 사용합니다.
  static const String proxyBaseUrl = String.fromEnvironment(
    'PARKING_PROXY_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  Future<List<ParkingLotStatus>> fetchRegion8Lots() async {
    if (kIsWeb) {
      return _fetchFromProxy();
    }
    return _fetchFromHtml();
  }

  Future<List<ParkingLotStatus>> _fetchFromProxy() async {
    final uri = Uri.parse('$proxyBaseUrl/parking/region8');
    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('proxy request failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final lotsRaw = (decoded['lots'] as List<dynamic>? ?? const []);
    return lotsRaw
        .whereType<Map<String, dynamic>>()
        .map(ParkingLotStatus.fromJson)
        .toList(growable: false);
  }

  Future<List<ParkingLotStatus>> _fetchFromHtml() async {
    final uri = Uri.parse(region8Url);
    final response = await http.get(
      uri,
      headers: const {
        'User-Agent': 'Mozilla/5.0 (YeouidoParkingFlutter; +https://example.invalid)',
        'Accept': 'text/html,application/xhtml+xml',
      },
    ).timeout(_timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('html request failed: ${response.statusCode}');
    }

    return _parseLotsFromHtml(utf8.decode(response.bodyBytes));
  }

  List<ParkingLotStatus> _parseLotsFromHtml(String html) {
    final doc = html_parser.parse(html);
    final tab = doc.getElementById('regionTab01') ?? doc.querySelector('#regionTab01');
    final rows = tab?.querySelectorAll('table tbody tr') ?? const [];

    final results = <ParkingLotStatus>[];
    for (final row in rows) {
      final cells = row.querySelectorAll('td').map((e) => e.text.trim()).toList(growable: false);
      if (cells.length < 4) continue;

      final name = cells[0].trim();
      final total = _parseInt(cells[1]);
      final used = _parseInt(cells[2]);
      final available = _parseInt(cells[3]);

      final normalizedUsed = (used == 0 && total > 0 && available > 0) ? (total - available) : used;
      results.add(
        ParkingLotStatus(
          name: name.isEmpty ? '주차장' : name,
          total: total,
          used: mathMax(0, normalizedUsed),
          available: available,
        ),
      );
    }

    return results;
  }

  int _parseInt(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return int.tryParse(digits) ?? 0;
  }
}

int mathMax(int a, int b) => a > b ? a : b;
