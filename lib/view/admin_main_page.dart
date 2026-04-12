// 관리자 메인 화면. 로그인 후 여기로 옴
import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:yeouido_parking_flutter/view/common/admin_sidebar.dart';
import 'package:yeouido_parking_flutter/view/common/admin_top_bar.dart';
import 'package:yeouido_parking_flutter/utils/parking/ihangang_parking_client.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

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
                    onSelected: (index) => setState(() => _selectedIndex = index),
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
                    onSelected: (index) => setState(() => _selectedIndex = index),
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    AdminTopBar(
                      useDrawer: useDrawer,
                      onMenuPressed: useDrawer ? () => _scaffoldKey.currentState?.openDrawer() : null,
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
                                  onMore: () {},
                                ),
                                const SizedBox(height: 16),
                                _ParkingStatusCard(
                                  onMore: () {},
                                ),
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
  const _SectionCard({
    required this.title,
    this.trailing,
    required this.child,
  });

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
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
  const _ReservationStatusCard({required this.onMore});

  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final tiles = const [
      (name: '야구장', value: 0.5),
      (name: '사우나', value: 0.5),
      (name: '00 공원', value: 0.5),
      (name: '야구장', value: 0.5),
    ];

    return _SectionCard(
      title: '시설 예약 현황',
      trailing: TextButton.icon(
        onPressed: onMore,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('더보기'),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth < 720 ? 1 : 2;
          final tileWidth =
              crossAxisCount == 1 ? constraints.maxWidth : (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final t in tiles)
                SizedBox(
                  width: tileWidth,
                  child: _ProgressTile(
                    title: t.name,
                    value: t.value,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressTile extends StatelessWidget {
  const _ProgressTile({required this.title, required this.value});

  final String title;
  final double value;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: value.clamp(0, 1),
                    minHeight: 18,
                    backgroundColor: const Color(0xFFBDBDBD),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF7E7AF5)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 42,
                child: Text(
                  '$percent%',
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
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
      final available = (_lots != null && i < _lots!.length) ? _lots![i].available : 0;
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
              child: const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFD50000)),
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
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
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
        final envCard = const _EnvironmentCard();

        if (stacked) {
          return Column(
            children: [
              mapCard,
              const SizedBox(height: 16),
              envCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(flex: 3, child: _MapCard()),
            SizedBox(width: 16),
            Expanded(flex: 2, child: _EnvironmentCard()),
          ],
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

class _EnvironmentCard extends StatelessWidget {
  const _EnvironmentCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '환경 지수',
      child: Column(
        children: const [
          _GaugeBlock(
            title: '생활기상지수',
            value: 0.35,
            badgeText: '2',
          ),
          SizedBox(height: 18),
          _GaugeBlock(
            title: '대기확산지수',
            value: 0.7,
            badgeText: '34',
          ),
        ],
      ),
    );
  }
}

class _GaugeBlock extends StatelessWidget {
  const _GaugeBlock({required this.title, required this.value, required this.badgeText});

  final String title;
  final double value;
  final String badgeText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Center(
            child: _SemiGauge(
              value: value,
              badgeText: badgeText,
            ),
          ),
        ],
      ),
    );
  }
}

class _SemiGauge extends StatelessWidget {
  const _SemiGauge({required this.value, required this.badgeText});

  final double value;
  final String badgeText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 150,
      child: CustomPaint(
        painter: _SemiGaugePainter(value: value.clamp(0, 1), badgeText: badgeText),
      ),
    );
  }
}

class _SemiGaugePainter extends CustomPainter {
  _SemiGaugePainter({required this.value, required this.badgeText});

  final double value;
  final String badgeText;

  static const _colors = [
    Color(0xFF2F6BFF), // 낮음
    Color(0xFF34C759), // 보통
    Color(0xFFFFCC00), // 높음
    Color(0xFFFF9500), // 매우높음
    Color(0xFFFF3B30), // 위험
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = math.min(size.width / 2, size.height) - 12;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = math.pi / _colors.length;
    for (int i = 0; i < _colors.length; i++) {
      stroke.color = _colors[i];
      canvas.drawArc(rect, math.pi + (sweep * i), sweep, false, stroke);
    }

    final needleAngle = math.pi + (math.pi * (1 - value));
    final needlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFF424242);

    final needleEnd = Offset(
      center.dx + (radius - 10) * math.cos(needleAngle),
      center.dy + (radius - 10) * math.sin(needleAngle),
    );
    canvas.drawLine(center, needleEnd, needlePaint);

    final knobPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 18, Paint()..color = const Color(0xFF424242));
    canvas.drawCircle(center, 16, knobPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: badgeText,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF424242)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - (textPainter.width / 2), center.dy - (textPainter.height / 2)),
    );

    final legend = [
      ('낮음', _colors[0]),
      ('보통', _colors[1]),
      ('높음', _colors[2]),
      ('매우높음', _colors[3]),
      ('위험', _colors[4]),
    ];
    final legendTop = 6.0;
    final spacing = (size.width - 12) / legend.length;
    for (int i = 0; i < legend.length; i++) {
      final (label, color) = legend[i];
      final x = 6 + spacing * i + (spacing / 2);
      final dot = Paint()..color = color;
      canvas.drawCircle(Offset(x, legendTop + 4), 4, dot);
      final t = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF616161)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      t.paint(canvas, Offset(x - (t.width / 2), legendTop + 10));
    }
  }

  @override
  bool shouldRepaint(covariant _SemiGaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.badgeText != badgeText;
  }
}
