// 예약 리스트 (관리자 웹)
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:yeouido_parking_flutter/model/reservation.dart';
import 'package:yeouido_parking_flutter/utils/app_route/app_route.dart';
import 'package:yeouido_parking_flutter/view/common/admin_sidebar.dart';
import 'package:yeouido_parking_flutter/view/common/admin_top_bar.dart';

class AdminReservationList extends StatefulWidget {
  const AdminReservationList({super.key});

  @override
  State<AdminReservationList> createState() => _AdminReservationListState();
}

class _AdminReservationListState extends State<AdminReservationList> {
  static const String _baseUrl = String.fromEnvironment(
    'FASTAPI_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1;

  bool _loading = false;
  String? _error;
  DateTime? _lastUpdated;
  List<Reservation> _reservations = const [];
  Map<int, String> _facilityNames = const {};

  bool _statsLoading = false;
  String? _statsError;
  _ReservationDashboardStats? _stats;

  final int _limit = 10;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_fetchStats());
    unawaited(_fetch());
  }

  Future<void> _fetchStats() async {
    if (_statsLoading) return;
    setState(() {
      _statsLoading = true;
      _statsError = null;
    });

    try {
      final base = _baseUrl.replaceFirst(RegExp(r'/$'), '');
      final uri = Uri.parse(
        '$base/reservation/stats/dashboard',
      ).replace(queryParameters: const {'top': '3'});
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response');
      }
      final stats = _ReservationDashboardStats.fromJson(decoded);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _statsLoading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _statsError = '서버 응답 시간이 초과되었습니다.';
        _statsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statsError = e.toString();
        _statsLoading = false;
      });
    }
  }

  Future<void> _openReservation(Map<String, dynamic> args) async {
    final result = await Navigator.of(
      context,
    ).pushNamed(AppRoute.adminReservationView, arguments: args);

    if (!mounted) return;
    if (result is Map && result['updated'] == true) {
      final message = result['message']?.toString().trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message == null || message.isEmpty ? '처리되었습니다.' : message,
          ),
        ),
      );
      await _fetchStats();
      await _fetch();
    }
  }

  Future<void> _fetch() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final base = _baseUrl.replaceFirst(RegExp(r'/$'), '');
      final uri = Uri.parse('$base/reservation').replace(
        queryParameters: {
          'limit': _limit.toString(),
          'offset': _offset.toString(),
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List) {
        throw Exception('Unexpected response');
      }

      final reservations = decoded
          .whereType<Map<String, dynamic>>()
          .map(Reservation.fromJson)
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _reservations = reservations;
        _lastUpdated = DateTime.now();
        _loading = false;
      });

      unawaited(
        _ensureFacilityNames(reservations.map((e) => e.facility_id).toSet()),
      );
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _error = '서버 응답 시간이 초과되었습니다.';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _ensureFacilityNames(Set<int> facilityIds) async {
    final missing = facilityIds
        .where((id) => !_facilityNames.containsKey(id))
        .toList(growable: false);
    if (missing.isEmpty) return;

    try {
      final base = _baseUrl.replaceFirst(RegExp(r'/$'), '');
      final uri = Uri.parse('$base/facilities');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) return;

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List) return;

      final map = <int, String>{..._facilityNames};
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        final rawId = item['f_id'] ?? item['facility_id'];
        final id = int.tryParse(rawId?.toString() ?? '');
        if (id == null) continue;
        final name = (item['f_name'] ?? item['facility_name'])
            ?.toString()
            .trim();
        if (name == null || name.isEmpty) continue;
        map[id] = name;
      }

      if (!mounted) return;
      setState(() => _facilityNames = Map.unmodifiable(map));
    } catch (_) {
      // ignore facility name failures (keep IDs)
    }
  }

  void _nextPage() {
    setState(() => _offset += _limit);
    unawaited(_fetch());
  }

  void _prevPage() {
    final next = _offset - _limit;
    setState(() => _offset = next < 0 ? 0 : next);
    unawaited(_fetch());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool useDrawer = constraints.maxWidth < 980;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF3F4F6),
          drawer: useDrawer
              ? Drawer(
                  child: AdminSidebar(
                    selectedIndex: _selectedIndex,
                    onSelected: (index) =>
                        setState(() => _selectedIndex = index),
                  ),
                )
              : null,
          body: Row(
            children: [
              if (!useDrawer)
                SizedBox(
                  width: 220,
                  child: AdminSidebar(
                    selectedIndex: _selectedIndex,
                    onSelected: (index) =>
                        setState(() => _selectedIndex = index),
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    AdminTopBar(
                      useDrawer: useDrawer,
                      onMenuPressed: useDrawer
                          ? () => _scaffoldKey.currentState?.openDrawer()
                          : null,
                    ),
                    Expanded(
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: _ReservationTableCard(
                              loading: _loading,
                              error: _error,
                              lastUpdated: _lastUpdated,
                              reservations: _reservations,
                              facilityNames: _facilityNames,
                              statsLoading: _statsLoading,
                              statsError: _statsError,
                              stats: _stats,
                              offset: _offset,
                              limit: _limit,
                              onRefresh: () => unawaited(_fetch()),
                              onRefreshStats: () => unawaited(_fetchStats()),
                              onNext: _nextPage,
                              onPrev: _prevPage,
                              onOpenReservation: (args) =>
                                  unawaited(_openReservation(args)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReservationTableCard extends StatelessWidget {
  const _ReservationTableCard({
    required this.loading,
    required this.error,
    required this.lastUpdated,
    required this.reservations,
    required this.facilityNames,
    required this.statsLoading,
    required this.statsError,
    required this.stats,
    required this.offset,
    required this.limit,
    required this.onRefresh,
    required this.onRefreshStats,
    required this.onNext,
    required this.onPrev,
    required this.onOpenReservation,
  });

  final bool loading;
  final String? error;
  final DateTime? lastUpdated;
  final List<Reservation> reservations;
  final Map<int, String> facilityNames;
  final bool statsLoading;
  final String? statsError;
  final _ReservationDashboardStats? stats;
  final int offset;
  final int limit;
  final VoidCallback onRefresh;
  final VoidCallback onRefreshStats;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final ValueChanged<Map<String, dynamic>> onOpenReservation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatsHeader(
              loading: statsLoading,
              error: statsError,
              stats: stats,
              onRefresh: onRefreshStats,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '예약 리스트',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                if (loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (error != null)
                  Tooltip(
                    message: error!,
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: Color(0xFFD50000),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: loading ? null : onRefresh,
                  tooltip: '새로고침',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (lastUpdated != null) ...[
              const SizedBox(height: 4),
              Text(
                '업데이트: ${_formatTime(lastUpdated!)}',
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _Table(
              reservations: reservations,
              facilityNames: facilityNames,
              onOpenReservation: onOpenReservation,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '페이지: ${(offset ~/ limit) + 1}  (offset: $offset / limit: $limit)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: loading || offset == 0 ? null : onPrev,
                  child: const Text('이전'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: loading || reservations.length < limit
                      ? null
                      : onNext,
                  child: const Text('다음'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
}

class _Table extends StatelessWidget {
  const _Table({
    required this.reservations,
    required this.facilityNames,
    required this.onOpenReservation,
  });

  final List<Reservation> reservations;
  final Map<int, String> facilityNames;
  final ValueChanged<Map<String, dynamic>> onOpenReservation;

  @override
  Widget build(BuildContext context) {
    final rows = reservations;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        showCheckboxColumn: false,
        columns: const [
          DataColumn(label: Text('예약ID')),
          DataColumn(label: Text('시설')),
          DataColumn(label: Text('유저ID')),
          DataColumn(label: Text('상태')),
          DataColumn(label: Text('시작')),
          DataColumn(label: Text('종료')),
          DataColumn(label: Text('생성일')),
        ],
        rows: [
          for (final r in rows)
            DataRow(
              onSelectChanged: (selected) {
                if (selected != true) return;
                final reservationId = r.reservation_id;
                if (reservationId == null) return;
                onOpenReservation({
                  'reservation_id': reservationId,
                  'reservation_start_date': r.reservation_start_date,
                  'reservation_end_date': r.reservation_end_date,
                  'reservation_date': r.reservation_date,
                  'reservation_state': r.reservation_state,
                  'user_id': r.user_id,
                  'facility_id': r.facility_id,
                  'facility_name': facilityNames[r.facility_id],
                });
              },
              cells: [
                DataCell(Text('${r.reservation_id ?? ''}')),
                DataCell(
                  _FacilityCell(
                    facilityId: r.facility_id,
                    facilityName: facilityNames[r.facility_id],
                  ),
                ),
                DataCell(Text('${r.user_id}')),
                DataCell(_StateChip(state: r.reservation_state)),
                DataCell(Text(_formatDateTime(r.reservation_start_date))),
                DataCell(Text(_formatDateTime(r.reservation_end_date))),
                DataCell(Text(_formatDateTime(r.reservation_date))),
              ],
            ),
          if (rows.isEmpty)
            const DataRow(
              cells: [
                DataCell(Text('-')),
                DataCell(Text('-')),
                DataCell(Text('-')),
                DataCell(Text('-')),
                DataCell(Text('-')),
                DataCell(Text('-')),
                DataCell(Text('데이터 없음')),
              ],
            ),
        ],
      ),
    );
  }

  static String _formatDateTime(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.toLocal();
    final yyyy = local.year.toString().padLeft(4, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd $hh:$min';
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.state});

  final int state;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      1 => ('대기', const Color(0xFF616161)),
      2 => ('승인 완료', const Color(0xFF2E7D32)),
      3 => ('반려', const Color(0xFFD50000)),
      4 => ('완료', const Color(0xFF1565C0)),
      _ => ('$state', const Color(0xFF616161)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({
    required this.loading,
    required this.error,
    required this.stats,
    required this.onRefresh,
  });

  final bool loading;
  final String? error;
  final _ReservationDashboardStats? stats;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = stats;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '요약',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (error != null)
                Tooltip(
                  message: error!,
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: Color(0xFFD50000),
                  ),
                ),
              IconButton(
                onPressed: loading ? null : onRefresh,
                tooltip: '새로고침',
                icon: const Icon(Icons.refresh, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (s == null)
            const Text(
              '통계 데이터를 불러오는 중입니다.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF616161),
              ),
            )
          else ...[
            Text(
              'Best 3 (전체 예약 건수)',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final t in s.topFacilities)
                  _MiniBestTile(name: t.name, count: t.count),
                if (s.topFacilities.isEmpty)
                  const Text(
                    '데이터 없음',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF616161),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${s.month} 예약 요약',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _CountChip(
                  label: '전체',
                  value: s.monthly.total,
                  color: const Color(0xFF424242),
                ),
                _CountChip(
                  label: '대기',
                  value: s.monthly.waiting,
                  color: const Color(0xFF616161),
                ),
                _CountChip(
                  label: '승인',
                  value: s.monthly.approved,
                  color: const Color(0xFF2E7D32),
                ),
                _CountChip(
                  label: '반려',
                  value: s.monthly.rejected,
                  color: const Color(0xFFD50000),
                ),
                _CountChip(
                  label: '완료',
                  value: s.monthly.completed,
                  color: const Color(0xFF1565C0),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniBestTile extends StatelessWidget {
  const _MiniBestTile({required this.name, required this.count});

  final String name;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF616161),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$value',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservationDashboardStats {
  const _ReservationDashboardStats({
    required this.month,
    required this.topFacilities,
    required this.monthly,
  });

  final String month;
  final List<_TopFacility> topFacilities;
  final _MonthlyCounts monthly;

  factory _ReservationDashboardStats.fromJson(Map<String, dynamic> json) {
    final top = (json['top_facilities'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_TopFacility.fromJson)
        .toList(growable: false);
    final monthly = _MonthlyCounts.fromJson(
      (json['monthly_counts'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    );
    return _ReservationDashboardStats(
      month: (json['month']?.toString() ?? '').trim().isEmpty
          ? '-'
          : json['month'].toString(),
      topFacilities: top,
      monthly: monthly,
    );
  }
}

class _TopFacility {
  const _TopFacility({
    required this.id,
    required this.name,
    required this.count,
  });

  final int? id;
  final String name;
  final int count;

  factory _TopFacility.fromJson(Map<String, dynamic> json) {
    final id = int.tryParse(json['facility_id']?.toString() ?? '');
    final rawName = (json['facility_name']?.toString() ?? '').trim();
    final name = rawName.isEmpty ? (id == null ? '시설' : '시설 #$id') : rawName;
    final count = int.tryParse(json['count']?.toString() ?? '') ?? 0;
    return _TopFacility(id: id, name: name, count: count);
  }
}

class _MonthlyCounts {
  const _MonthlyCounts({
    required this.total,
    required this.waiting,
    required this.approved,
    required this.rejected,
    required this.completed,
  });

  final int total;
  final int waiting;
  final int approved;
  final int rejected;
  final int completed;

  factory _MonthlyCounts.fromJson(Map<String, dynamic> json) {
    int read(String key) => int.tryParse(json[key]?.toString() ?? '') ?? 0;
    return _MonthlyCounts(
      total: read('total'),
      waiting: read('waiting'),
      approved: read('approved'),
      rejected: read('rejected'),
      completed: read('completed'),
    );
  }
}

class _FacilityCell extends StatelessWidget {
  const _FacilityCell({required this.facilityId, required this.facilityName});

  final int facilityId;
  final String? facilityName;

  @override
  Widget build(BuildContext context) {
    final name = facilityName;
    if (name == null || name.isEmpty) {
      return Text('$facilityId');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w800),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          'ID: $facilityId',
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF757575),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
