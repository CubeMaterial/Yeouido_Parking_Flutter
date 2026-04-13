// 주차장 관리 - 수정 (관리자 웹)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yeouido_parking_flutter/model/parking.dart';
import 'package:yeouido_parking_flutter/view/common/admin_sidebar.dart';
import 'package:yeouido_parking_flutter/view/common/admin_top_bar.dart';
import 'package:yeouido_parking_flutter/vm/parking_api.dart';

class AdminParkingUpdate extends StatefulWidget {
  const AdminParkingUpdate({
    super.key,
    required this.parkingId,
    this.initialParking,
  });

  final int? parkingId;
  final Parking? initialParking;

  @override
  State<AdminParkingUpdate> createState() => _AdminParkingUpdateState();
}

class _AdminParkingUpdateState extends State<AdminParkingUpdate> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1;

  final _nameController = TextEditingController();
  final _maxController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.initialParking;
    if (p != null) _applyParking(p);
    unawaited(_fetchIfNeeded());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _maxController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _applyParking(Parking p) {
    _nameController.text = p.parking_name;
    _maxController.text = p.parking_max.toString();
    _latController.text = p.parking_lat.toString();
    _lngController.text = p.parking_lng.toString();
  }

  Future<void> _fetchIfNeeded() async {
    final id = widget.parkingId;
    if (id == null) {
      setState(() => _error = 'parkingId가 전달되지 않았습니다.');
      return;
    }
    if (widget.initialParking != null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final p = await ParkingApi.fetchParkingDetail(id);
      if (!mounted) return;
      setState(() {
        _applyParking(p);
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
    final id = widget.parkingId;
    if (id == null) return;
    if (_loading) return;

    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    final name = _nameController.text.trim();
    final maxCount = int.tryParse(_maxController.text.trim());

    if (lat == null || lng == null) {
      setState(() => _error = '위도/경도를 확인해 주세요.');
      return;
    }
    if (name.isEmpty) {
      setState(() => _error = '주차장명을 입력해 주세요.');
      return;
    }
    if (maxCount == null) {
      setState(() => _error = '최대 수용량을 확인해 주세요.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ParkingApi.updateParkinglot(
        parkingId: id,
        lat: lat,
        lng: lng,
        name: name,
        maxCount: maxCount,
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
                                        const Expanded(
                                          child: Text(
                                            '주차장 수정',
                                            style: TextStyle(
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
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _TextFieldBlock(
                                      label: '주차장명',
                                      controller: _nameController,
                                    ),
                                    const SizedBox(height: 10),
                                    _TextFieldBlock(
                                      label: '최대 수용량',
                                      controller: _maxController,
                                      keyboardType: TextInputType.number,
                                    ),
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
                                    const SizedBox(height: 16),
                                    FilledButton(
                                      onPressed: _loading ? null : _submit,
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        backgroundColor: const Color(
                                          0xFF7E7AF5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        '수정',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
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
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
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
          maxLines: 1,
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
