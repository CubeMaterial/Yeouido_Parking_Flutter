// 시설 관리 - 리스트 (관리자 웹)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yeouido_parking_flutter/model/facility.dart';
import 'package:yeouido_parking_flutter/utils/app_route/app_route.dart';
import 'package:yeouido_parking_flutter/view/common/admin_sidebar.dart';
import 'package:yeouido_parking_flutter/view/common/admin_top_bar.dart';
import 'package:yeouido_parking_flutter/vm/facility_api.dart';

class AdminFacilityList extends StatefulWidget {
  const AdminFacilityList({super.key});

  @override
  State<AdminFacilityList> createState() => _AdminFacilityListState();
}

class _AdminFacilityListState extends State<AdminFacilityList> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 2;

  bool _loading = false;
  String? _error;
  List<Facility> _facilities = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_fetch());
  }

  Future<void> _fetch() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await FacilityApi.fetchFacilities();
      if (!mounted) return;
      setState(() {
        _facilities = list;
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

  Future<void> _openAdd() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final result = await navigator.pushNamed(AppRoute.adminFacilityAdd);
    if (!mounted) return;
    if (result is Map && result['updated'] == true) {
      final message = result['message']?.toString() ?? '생성되었습니다.';
      messenger.showSnackBar(SnackBar(content: Text(message)));
      await _fetch();
      if (!mounted) return;

      final createdId = int.tryParse(result['facility_id']?.toString() ?? '');
      if (createdId != null) {
        await navigator.pushNamed(
          AppRoute.adminFacilityView,
          arguments: createdId,
        );
      }
    }
  }

  Future<void> _openFacility(Facility facility) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final facilityId = facility.facility_id;
    if (facilityId == null) return;
    final result = await navigator.pushNamed(
      AppRoute.adminFacilityView,
      arguments: {
        'facility_id': facilityId,
        'facility_name': facility.facility_name,
        'facility_info': facility.facility_info,
        'facility_image': facility.facility_image,
        'facility_lat': facility.facility_lat,
        'facility_lng': facility.facility_lng,
        'facility_possible': facility.facility_possible,
      },
    );
    if (!mounted) return;
    if (result is Map && result['updated'] == true) {
      final message = result['message']?.toString() ?? '처리되었습니다.';
      messenger.showSnackBar(SnackBar(content: Text(message)));
      await _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          '시설 관리',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const Spacer(),
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
                                              size: 18,
                                              color: Color(0xFFD50000),
                                            ),
                                          ),
                                        IconButton(
                                          onPressed: _loading ? null : _fetch,
                                          tooltip: '새로고침',
                                          icon: const Icon(Icons.refresh),
                                        ),
                                        const SizedBox(width: 8),
                                        FilledButton.icon(
                                          onPressed: _loading ? null : _openAdd,
                                          icon: const Icon(Icons.add),
                                          label: const Text('추가'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _FacilityTable(
                                      facilities: _facilities,
                                      onOpen: _openFacility,
                                    ),
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

class _FacilityTable extends StatelessWidget {
  const _FacilityTable({required this.facilities, required this.onOpen});

  final List<Facility> facilities;
  final ValueChanged<Facility> onOpen;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        showCheckboxColumn: false,
        columns: const [
          DataColumn(label: Text('시설ID')),
          DataColumn(label: Text('시설명')),
        ],
        rows: [
          for (final f in facilities)
            DataRow(
              onSelectChanged: (selected) {
                if (selected != true) return;
                onOpen(f);
              },
              cells: [
                DataCell(Text('${f.facility_id ?? ''}')),
                DataCell(Text(f.facility_name)),
              ],
            ),
          if (facilities.isEmpty)
            const DataRow(
              cells: [DataCell(Text('-')), DataCell(Text('데이터 없음'))],
            ),
        ],
      ),
    );
  }
}
