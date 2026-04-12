// 시설 관리 - 상세 (관리자 웹)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yeouido_parking_flutter/model/facility.dart';
import 'package:yeouido_parking_flutter/utils/app_route/app_route.dart';
import 'package:yeouido_parking_flutter/view/common/admin_sidebar.dart';
import 'package:yeouido_parking_flutter/view/common/admin_top_bar.dart';
import 'package:yeouido_parking_flutter/vm/facility_api.dart';

class AdminFacilityView extends StatefulWidget {
  const AdminFacilityView({
    super.key,
    required this.facilityId,
    this.initialFacility,
  });

  final int? facilityId;
  final Facility? initialFacility;

  @override
  State<AdminFacilityView> createState() => _AdminFacilityViewState();
}

class _AdminFacilityViewState extends State<AdminFacilityView> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 2;

  bool _loading = false;
  String? _error;
  Facility? _facility;

  @override
  void initState() {
    super.initState();
    _facility = widget.initialFacility;
    unawaited(_fetch());
  }

  Future<void> _fetch() async {
    final id = widget.facilityId;
    if (id == null) {
      setState(() => _error = 'facilityId가 전달되지 않았습니다.');
      return;
    }
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final f = await FacilityApi.fetchFacilityDetail(id);
      if (!mounted) return;
      setState(() {
        _facility = f;
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
    final id = widget.facilityId;
    final f = _facility;
    if (id == null || f == null) return;

    final result = await Navigator.of(context).pushNamed(
      AppRoute.adminFacilityUpdate,
      arguments: {
        'facility_id': id,
        'facility': f.toJson(),
      },
    );
    if (!mounted) return;
    if (result is Map && result['updated'] == true) {
      final message = result['message']?.toString() ?? '수정되었습니다.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      await _fetch();
    }
  }

  Future<void> _openAdd() async {
    final result = await Navigator.of(context).pushNamed(AppRoute.adminFacilityAdd);
    if (!mounted) return;
    if (result is Map && result['updated'] == true) {
      final message = result['message']?.toString() ?? '생성되었습니다.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      final createdId = int.tryParse(result['facility_id']?.toString() ?? '');
      if (createdId != null) {
        await Navigator.of(context).pushReplacementNamed(
          AppRoute.adminFacilityView,
          arguments: createdId,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = _facility;
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
                            constraints: const BoxConstraints(maxWidth: 720),
                            child: Card(
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
                                            f?.facility_name.isNotEmpty == true
                                                ? f!.facility_name
                                                : '시설 상세',
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                                          ),
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
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: _loading || f == null ? null : _openUpdate,
                                            icon: const Icon(Icons.edit),
                                            label: const Text('수정'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: FilledButton.icon(
                                            onPressed: _loading ? null : _openAdd,
                                            icon: const Icon(Icons.add),
                                            label: const Text('추가'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (f == null)
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(vertical: 20),
                                          child: Text('데이터 없음'),
                                        ),
                                      )
                                    else
                                      _FacilityDetailBody(facility: f),
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

class _FacilityDetailBody extends StatelessWidget {
  const _FacilityDetailBody({required this.facility});

  final Facility facility;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReadOnlyField(label: '시설 ID', value: '${facility.facility_id ?? ''}'),
        const SizedBox(height: 10),
        _ReadOnlyField(label: '시설명', value: facility.facility_name),
        const SizedBox(height: 10),
        _ReadOnlyField(label: '설명', value: facility.facility_info),
        const SizedBox(height: 10),
        _ReadOnlyField(label: '이미지', value: facility.facility_image),
        const SizedBox(height: 10),
        _ReadOnlyField(label: '위도', value: facility.facility_lat.toString()),
        const SizedBox(height: 10),
        _ReadOnlyField(label: '경도', value: facility.facility_lng.toString()),
        const SizedBox(height: 10),
        _ReadOnlyField(label: '예약 가능', value: facility.facility_possible == 1 ? '가능' : '불가'),
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
        Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Text(value.isEmpty ? '-' : value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

