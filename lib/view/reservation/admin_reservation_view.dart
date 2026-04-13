// 예약글 보기. 허용, 반려를 여기서 함. (관리자 웹)
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:yeouido_parking_flutter/view/common/admin_sidebar.dart';
import 'package:yeouido_parking_flutter/view/common/admin_top_bar.dart';
import 'package:yeouido_parking_flutter/vm/api_config.dart';

class AdminReservationView extends StatefulWidget {
  const AdminReservationView({
    super.key,
    required this.reservationId,
    this.initialDetail,
  });

  final int? reservationId;
  final Map<String, dynamic>? initialDetail;

  @override
  State<AdminReservationView> createState() => _AdminReservationViewState();
}

class _AdminReservationViewState extends State<AdminReservationView> {
  static String get _baseUrl => ApiConfig.fastApiBaseUrl;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1;

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _detail;

  @override
  void initState() {
    super.initState();
    _detail = widget.initialDetail;
    unawaited(_fetchDetail());
  }

  Future<void> _fetchDetail() async {
    final reservationId = widget.reservationId;
    if (reservationId == null) {
      setState(() => _error = 'reservationId가 전달되지 않았습니다.');
      return;
    }

    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final base = _baseUrl;
      final uri = Uri.parse('$base/reservation/$reservationId');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response');
      }
      if (!mounted) return;
      setState(() {
        _detail = decoded;
        _loading = false;
      });
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
  
  Future<void> _updateState(int newState) async {
    final reservationId = widget.reservationId;
    if (reservationId == null) return;
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final base = _baseUrl;
      final uri = Uri.parse('$base/reservation/$reservationId/state');
      final response = await http
          .patch(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'reservation_state': newState}),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }

      if (!mounted) return;
      Navigator.of(context).pop({
        'updated': true,
        'message': newState == 2 ? '승인 처리되었습니다.' : '반려 처리되었습니다.',
      });
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
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: _ReservationDetailCard(
                              loading: _loading,
                              error: _error,
                              detail: _detail,
                              onRefresh: _fetchDetail,
                              onApprove: () => _updateState(2),
                              onReject: () => _updateState(3),
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

class _ReservationDetailCard extends StatelessWidget {
  const _ReservationDetailCard({
    required this.loading,
    required this.error,
    required this.detail,
    required this.onRefresh,
    required this.onApprove,
    required this.onReject,
  });

  final bool loading;
  final String? error;
  final Map<String, dynamic>? detail;
  final VoidCallback onRefresh;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final facilityName = (detail?['facility_name'] ?? detail?['f_name'])
        ?.toString()
        .trim();

    final dateText = _formatDate(detail?['reservation_start_date']?.toString());
    final startText = _formatTime(
      detail?['reservation_start_date']?.toString(),
    );
    final endText = _formatTime(detail?['reservation_end_date']?.toString());
    final userId = _userId(detail);
    final userName = _userName(detail);
    final userText = _formatUser(userId: userId, userName: userName);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    facilityName?.isNotEmpty == true ? facilityName! : '예약 상세',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
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
                      color: Color(0xFFD50000),
                    ),
                  ),
                IconButton(
                  onPressed: loading ? null : onRefresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: '새로고침',
                ),
              ],
            ),
            const SizedBox(height: 8),
            _FieldBlock(
              icon: Icons.calendar_month_outlined,
              title: '예약 날짜',
              child: _ReadOnlyBox(
                text: dateText,
                trailing: const Icon(Icons.calendar_today_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _FieldBlock(
                    icon: Icons.schedule_outlined,
                    title: '시작 시간',
                    child: _ReadOnlyBox(
                      text: startText,
                      trailing: const Icon(Icons.access_time, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FieldBlock(
                    icon: Icons.schedule_outlined,
                    title: '종료 시간',
                    child: _ReadOnlyBox(
                      text: endText,
                      trailing: const Icon(Icons.access_time, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FieldBlock(
              icon: Icons.person_outline,
              title: '신청자',
              child: _ReadOnlyBox(
                text: userText,
                trailing: const Icon(Icons.badge_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: loading ? null : onReject,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: const Color(0xFFD50000),
                      side: const BorderSide(color: Color(0xFFD50000)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '반려',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: loading ? null : onApprove,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF7E7AF5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '승인',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static int? _userId(Map<String, dynamic>? detail) {
    final user = detail?['user'];
    final candidates = [
      detail?['user_id'],
      detail?['u_id'],
      detail?['userid'],
      detail?['reservation_user_id'],
      if (user is Map<String, dynamic>) user['user_id'],
      if (user is Map<String, dynamic>) user['u_id'],
      if (user is Map<String, dynamic>) user['userid'],
    ];

    for (final c in candidates) {
      final parsed = _tryParseInt(c);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static String? _userName(Map<String, dynamic>? detail) {
    final user = detail?['user'];
    final candidates = [
      detail?['user_name'],
      detail?['username'],
      detail?['name'],
      if (user is Map<String, dynamic>) user['user_name'],
      if (user is Map<String, dynamic>) user['username'],
      if (user is Map<String, dynamic>) user['name'],
    ];

    for (final c in candidates) {
      final text = c?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  static int? _tryParseInt(Object? value) {
    if (value is int) return value;
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  static String _formatUser({required int? userId, required String? userName}) {
    final id = userId;
    final name = userName?.trim();

    if (id == null && (name == null || name.isEmpty)) return '-';
    if (name == null || name.isEmpty) return 'ID: $id';
    if (id == null) return name;
    return '$name (ID: $id)';
  }

  static DateTime? _tryParseDateTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static String _formatDate(String? raw) {
    final dt = _tryParseDateTime(raw);
    if (dt == null) return '-';
    final local = dt.toLocal();
    final yyyy = local.year.toString().padLeft(4, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  static String _formatTime(String? raw) {
    final dt = _tryParseDateTime(raw);
    if (dt == null) return '-';
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$hh:$min';
  }
}

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF4F4F4F)),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _ReadOnlyBox extends StatelessWidget {
  const _ReadOnlyBox({required this.text, required this.trailing});

  final String text;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}
