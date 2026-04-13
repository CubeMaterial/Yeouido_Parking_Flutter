// 주차장 관리 - 상세 (관리자 웹)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yeouido_parking_flutter/model/parking.dart';
import 'package:yeouido_parking_flutter/utils/app_route/app_route.dart';
import 'package:yeouido_parking_flutter/view/common/admin_sidebar.dart';
import 'package:yeouido_parking_flutter/view/common/admin_top_bar.dart';
import 'package:yeouido_parking_flutter/vm/parking_api.dart';

class AdminParkingView extends StatefulWidget {
  const AdminParkingView({
    super.key,
    required this.parkingId,
    this.initialParking,
  });

  final int? parkingId;
  final Parking? initialParking;

  @override
  State<AdminParkingView> createState() => _AdminParkingViewState();
}

class _AdminParkingViewState extends State<AdminParkingView> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1;

  bool _loading = false;
  String? _error;
  Parking? _parking;

  @override
  void initState() {
    super.initState();
    _parking = widget.initialParking;
    unawaited(_fetch());
  }

  Future<void> _fetch() async {
    final id = widget.parkingId;
    if (id == null) {
      setState(() => _error = 'parkingId가 전달되지 않았습니다.');
      return;
    }
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final p = await ParkingApi.fetchParkingDetail(id);
      if (!mounted) return;
      setState(() {
        _parking = p;
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

  Future<void> _openUpdate() async {
    final id = widget.parkingId;
    final p = _parking;
    if (id == null || p == null) return;

    final result = await Navigator.of(context).pushNamed(
      AppRoute.adminParkingUpdate,
      arguments: {'parking_id': id, 'parking': p.toJson()},
    );
    if (!mounted) return;
    if (result is Map && result['updated'] == true) {
      final message = result['message']?.toString() ?? '수정되었습니다.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      await _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _parking;
    return LayoutBuilder(
      builder: (context, constraints) {
        final useDrawer = constraints.maxWidth < 980;
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
                            constraints: const BoxConstraints(maxWidth: 720),
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            p?.parking_name.isNotEmpty == true
                                                ? p!.parking_name
                                                : '주차장 상세',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                        if (_loading)
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        else if (_error != null)
                                          Tooltip(
                                            message: _error!,
                                            child: const Icon(
                                              Icons.warning_amber_rounded,
                                              color: Color(0xFFD50000),
                                            ),
                                          ),
                                        IconButton(
                                          onPressed: _loading ? null : _fetch,
                                          tooltip: '새로고침',
                                          icon: const Icon(Icons.refresh),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: _loading || p == null
                                              ? null
                                              : _openUpdate,
                                          icon: const Icon(Icons.edit),
                                          label: const Text('수정'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (p == null)
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 20,
                                          ),
                                          child: Text('데이터 없음'),
                                        ),
                                      )
                                    else
                                      _ParkingDetailBody(parking: p),
                                  ],
                                ),
                              ),
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

class _ParkingDetailBody extends StatelessWidget {
  const _ParkingDetailBody({required this.parking});

  final Parking parking;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReadOnlyField(label: '주차장 ID', value: '${parking.parking_id ?? ''}'),
        const SizedBox(height: 10),
        _ReadOnlyField(label: '주차장명', value: parking.parking_name),
        const SizedBox(height: 10),
        _ReadOnlyField(label: '최대 수용량', value: '${parking.parking_max}'),
        const SizedBox(height: 10),
        _ReadOnlyField(label: '위도', value: parking.parking_lat.toString()),
        const SizedBox(height: 10),
        _ReadOnlyField(label: '경도', value: parking.parking_lng.toString()),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
