// 시설 관리 - 수정 (관리자 웹)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yeouido_parking_flutter/model/facility.dart';
import 'package:yeouido_parking_flutter/view/common/admin_sidebar.dart';
import 'package:yeouido_parking_flutter/view/common/admin_top_bar.dart';
import 'package:yeouido_parking_flutter/vm/facility_api.dart';

class AdminFacilityUpdate extends StatefulWidget {
  const AdminFacilityUpdate({
    super.key,
    required this.facilityId,
    this.initialFacility,
  });

  final int? facilityId;
  final Facility? initialFacility;

  @override
  State<AdminFacilityUpdate> createState() => _AdminFacilityUpdateState();
}

class _AdminFacilityUpdateState extends State<AdminFacilityUpdate> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 2;

  final _nameController = TextEditingController();
  final _infoController = TextEditingController();
  final _imageController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  int _possible = 0;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final f = widget.initialFacility;
    if (f != null) _applyFacility(f);
    unawaited(_fetchIfNeeded());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _infoController.dispose();
    _imageController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _applyFacility(Facility f) {
    _nameController.text = f.facility_name;
    _infoController.text = f.facility_info;
    _imageController.text = f.facility_image;
    _latController.text = f.facility_lat.toString();
    _lngController.text = f.facility_lng.toString();
    _possible = f.facility_possible;
  }

  Future<void> _fetchIfNeeded() async {
    final id = widget.facilityId;
    if (id == null) {
      setState(() => _error = 'facilityId가 전달되지 않았습니다.');
      return;
    }
    if (widget.initialFacility != null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final f = await FacilityApi.fetchFacilityDetail(id);
      if (!mounted) return;
      setState(() {
        _applyFacility(f);
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

  Future<void> _submit() async {
    final id = widget.facilityId;
    if (id == null) return;
    if (_loading) return;

    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    final name = _nameController.text.trim();
    final info = _infoController.text.trim();
    final image = _imageController.text.trim();

    if (lat == null || lng == null) {
      setState(() => _error = '위도/경도를 확인해 주세요.');
      return;
    }
    if (name.isEmpty) {
      setState(() => _error = '시설명을 입력해 주세요.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await FacilityApi.updateFacility(
        facilityId: id,
        lat: lat,
        lng: lng,
        name: name,
        info: info,
        image: image,
        possible: _possible,
      );

      if (!mounted) return;
      Navigator.of(context).pop({'updated': true, 'message': '수정되었습니다.'});
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
                                        const Expanded(
                                          child: Text(
                                            '시설 수정',
                                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
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
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _TextFieldBlock(label: '시설명', controller: _nameController),
                                    const SizedBox(height: 10),
                                    _TextFieldBlock(label: '설명', controller: _infoController, maxLines: 4),
                                    const SizedBox(height: 10),
                                    _TextFieldBlock(label: '이미지 URL', controller: _imageController),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _TextFieldBlock(
                                            label: '위도',
                                            controller: _latController,
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: _TextFieldBlock(
                                            label: '경도',
                                            controller: _lngController,
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Text('예약 가능', style: TextStyle(fontWeight: FontWeight.w900)),
                                        const Spacer(),
                                        SegmentedButton<int>(
                                          segments: const [
                                            ButtonSegment(value: 1, label: Text('가능')),
                                            ButtonSegment(value: 0, label: Text('불가')),
                                          ],
                                          selected: {_possible},
                                          onSelectionChanged: _loading
                                              ? null
                                              : (v) => setState(() => _possible = v.first),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    FilledButton(
                                      onPressed: _loading ? null : _submit,
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        backgroundColor: const Color(0xFF7E7AF5),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                      child: const Text('저장', style: TextStyle(fontWeight: FontWeight.w900)),
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

class _TextFieldBlock extends StatelessWidget {
  const _TextFieldBlock({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF3F4F8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}

