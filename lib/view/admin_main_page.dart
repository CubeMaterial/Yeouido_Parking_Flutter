// 관리자 메인 화면. 로그인 후 여기로 옴
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:yeouido_parking_flutter/view/common/admin_sidebar.dart';
import 'package:yeouido_parking_flutter/view/common/admin_top_bar.dart';
import 'package:yeouido_parking_flutter/utils/parking/ihangang_parking_client.dart';
import 'package:yeouido_parking_flutter/vm/api_config.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  static String get _baseUrl => ApiConfig.fastApiBaseUrl;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  bool _reservationStatsLoading = false;
  String? _reservationStatsError;
  _ReservationDashboardStats? _reservationStats;

  @override
  void initState() {
    super.initState();
    unawaited(_loadReservationDashboardStats());
  }

  Future<void> _loadReservationDashboardStats() async {
    if (_reservationStatsLoading) return;
    setState(() {
      _reservationStatsLoading = true;
      _reservationStatsError = null;
    });

    try {
      final base = _baseUrl;
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
        _reservationStats = stats;
        _reservationStatsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _reservationStatsError = e.toString();
        _reservationStatsLoading = false;
      });
    }
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ReservationStatusCard(
                                  loading: _reservationStatsLoading,
                                  error: _reservationStatsError,
                                  stats: _reservationStats,
                                  onRefresh: _loadReservationDashboardStats,
                                  onMore: () {},
                                ),
                                const SizedBox(height: 16),
                                _ParkingStatusCard(onMore: () {}),
                                const SizedBox(height: 16),
                                _BottomRow(),
                                const SizedBox(height: 24),
                              ],
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, this.trailing, required this.child});

  final String title;
  final Widget? trailing;
  final Widget child;

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
            Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                trailing ?? const SizedBox.shrink(),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ReservationStatusCard extends StatelessWidget {
  const _ReservationStatusCard({
    required this.loading,
    required this.error,
    required this.stats,
    required this.onRefresh,
    required this.onMore,
  });

  final VoidCallback onMore;
  final bool loading;
  final String? error;
  final _ReservationDashboardStats? stats;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '시설 예약 현황',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: loading ? null : onRefresh,
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh, size: 20),
          ),
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
          TextButton.icon(
            onPressed: onMore,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('더보기'),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (loading && stats == null) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (error != null && stats == null) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '시설 정보를 불러오지 못했습니다.',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          if (stats == null) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '통계 데이터가 없습니다.',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF616161),
                ),
              ),
            );
          }

          final s = stats!;
          final top = s.topFacilities;
          final maxCount = top.isEmpty
              ? 0
              : top.map((e) => e.count).reduce(math.max);
          final crossAxisCount = constraints.maxWidth < 720 ? 1 : 2;
          final tileWidth = crossAxisCount == 1
              ? constraints.maxWidth
              : (constraints.maxWidth - 12) / 2;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Best 3 (전체 예약 건수)',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final t in top)
                    SizedBox(
                      width: tileWidth,
                      child: _TopFacilityTile(
                        name: t.name,
                        count: t.count,
                        maxCount: maxCount,
                      ),
                    ),
                  if (top.isEmpty)
                    SizedBox(
                      width: constraints.maxWidth,
                      child: const Text(
                        '데이터 없음',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF616161),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${s.month} 예약 요약',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
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
          );
        },
      ),
    );
  }
}

class _TopFacilityTile extends StatelessWidget {
  const _TopFacilityTile({
    required this.name,
    required this.count,
    required this.maxCount,
  });

  final String name;
  final int count;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final ratio = maxCount <= 0
        ? 0.0
        : (count / maxCount).clamp(0, 1).toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 12,
              backgroundColor: const Color(0xFFBDBDBD),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF7E7AF5)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '예약 $count건',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF616161),
              fontWeight: FontWeight.w700,
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

class _ParkingStatusCard extends StatefulWidget {
  const _ParkingStatusCard({required this.onMore});

  final VoidCallback onMore;

  @override
  State<_ParkingStatusCard> createState() => _ParkingStatusCardState();
}

class _ParkingStatusCardState extends State<_ParkingStatusCard> {
  final _client = IHangangParkingClient();

  List<ParkingLotStatus>? _lots;
  DateTime? _lastUpdated;
  DateTime? _lastAttempt;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      _lastAttempt = DateTime.now();
    });

    try {
      final lots = await _client.fetchRegion8Lots();
      if (!mounted) return;
      setState(() {
        if (lots.isNotEmpty) _lots = lots;
        _lastUpdated = DateTime.now();
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

  @override
  Widget build(BuildContext context) {
    const totals = <int>[462, 176, 785, 218, 141];
    const labels = <String>['1주차장', '2주차장', '3주차장', '4주차장', '5주차장'];

    final availableByIndex = List<int>.generate(totals.length, (i) {
      final available = (_lots != null && i < _lots!.length)
          ? _lots![i].available
          : 0;
      return available.clamp(0, totals[i]);
    });

    final colors = const [
      Color(0xFFD50000),
      Color(0xFFD50000),
      Color(0xFFFF5252),
      Color(0xFFD50000),
      Color(0xFFD50000),
    ];

    return _SectionCard(
      title: '주차장 현황',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _loading ? null : () => unawaited(_refresh()),
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh, size: 20),
          ),
          if (_loading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (_error != null)
            Tooltip(
              message: _error!,
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: Color(0xFFD50000),
              ),
            ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: widget.onMore,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('더보기'),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double itemWidth = constraints.maxWidth < 720 ? 150 : 140;
          return Wrap(
            spacing: 10,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            children: [
              for (int i = 0; i < totals.length; i++)
                SizedBox(
                  width: itemWidth,
                  child: _DonutIndicator(
                    label: labels[i],
                    available: availableByIndex[i],
                    total: totals[i],
                    color: colors[i % colors.length],
                  ),
                ),
              if (_lastUpdated != null || _lastAttempt != null)
                SizedBox(
                  width: constraints.maxWidth,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _buildUpdatedText(),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _buildUpdatedText() {
    String format(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

    final updated = _lastUpdated == null ? null : format(_lastUpdated!);
    final attempt = _lastAttempt == null ? null : format(_lastAttempt!);

    if (updated != null && attempt != null && updated != attempt) {
      return '업데이트: $updated (시도: $attempt)';
    }
    if (updated != null) return '업데이트: $updated';
    if (attempt != null) return '시도: $attempt';
    return '';
  }
}

class _DonutIndicator extends StatelessWidget {
  const _DonutIndicator({
    required this.label,
    required this.available,
    required this.total,
    required this.color,
  });

  final String label;
  final int available;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : (available / total).clamp(0, 1).toDouble();
    final remaining = math.max(0, total - available);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  startDegreeOffset: -90,
                  sectionsSpace: 0,
                  centerSpaceRadius: 32,
                  sections: [
                    PieChartSectionData(
                      value: ratio <= 0 ? 0.0001 : available.toDouble(),
                      color: color,
                      radius: 18,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: (1 - ratio) <= 0 ? 0.0001 : remaining.toDouble(),
                      color: const Color(0xFFD9D9D9),
                      radius: 18,
                      showTitle: false,
                    ),
                  ],
                ),
                duration: Duration.zero,
              ),
              Text(
                '$available/\n$total',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _BottomRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool stacked = constraints.maxWidth < 980;
        final mapCard = const _MapCard();

        if (stacked) {
          return Column(children: [mapCard]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [Expanded(flex: 3, child: _MapCard())],
        );
      },
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '공원 지도',
      child: SizedBox(
        height: 320,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(37.5283, 126.9326),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'yeouido_parking_flutter',
              ),
              MarkerLayer(
                markers: const [
                  Marker(
                    point: LatLng(37.5283, 126.9326),
                    width: 40,
                    height: 40,
                    child: Icon(Icons.location_on, color: Color(0xFFD50000)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
