// 시설 관리 - 상세 (관리자 웹)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yeouido_parking_flutter/model/facility.dart';
import 'package:yeouido_parking_flutter/utils/app_route/app_route.dart';
import 'package:yeouido_parking_flutter/view/common/admin_sidebar.dart';
import 'package:yeouido_parking_flutter/view/common/admin_top_bar.dart';
import 'package:yeouido_parking_flutter/vm/api_config.dart';
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
      arguments: {'facility_id': id, 'facility': f.toJson()},
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
                                            f?.facility_name.isNotEmpty == true
                                                ? f!.facility_name
                                                : '시설 상세',
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
                                        // const SizedBox(width: 10),
                                        // Expanded(
                                        // child:
                                        // ),
                                        OutlinedButton.icon(
                                          onPressed: _loading || f == null
                                              ? null
                                              : _openUpdate,
                                          icon: const Icon(Icons.edit),
                                          label: const Text('수정'),
                                        ),
                                        // Expanded(
                                        //   child: FilledButton.icon(
                                        //     onPressed: _loading ? null : _openAdd,
                                        //     icon: const Icon(Icons.add),
                                        //     label: const Text('추가'),
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (f == null)
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 20,
                                          ),
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
    final image = facility.facility_image.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReadOnlyField(label: '시설 ID', value: '${facility.facility_id ?? ''}'),
        const SizedBox(height: 10),
        _ReadOnlyField(label: '시설명', value: facility.facility_name),
        const SizedBox(height: 10),
        _ReadOnlyField(label: '설명', value: facility.facility_info),
        const SizedBox(height: 10),
        // _ReadOnlyField(label: '이미지', value: image),
        // if (image.isNotEmpty) ...[
        //   const SizedBox(height: 10),
        //   _FacilityImagePreview(image: image),
        // ],
        const SizedBox(height: 10),
        _ReadOnlyField(label: '위도', value: facility.facility_lat.toString()),
        const SizedBox(height: 10),
        _ReadOnlyField(label: '경도', value: facility.facility_lng.toString()),
        const SizedBox(height: 10),
        _ReadOnlyField(
          label: '예약 가능',
          value: facility.facility_possible == 1 ? '가능' : '불가',
        ),
      ],
    );
  }
}

class _FacilityImagePreview extends StatelessWidget {
  const _FacilityImagePreview({required this.image});

  final String image;

  static String _normalizeImageUrl(String value) {
    final raw = value.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null) return raw;

    if (uri.host == 'drive.google.com' ||
        uri.host.endsWith('.drive.google.com')) {
      final id = _googleDriveFileId(uri);
      if (id != null && id.isNotEmpty) {
        // Convert share links to a direct-view URL that Image.network can load.
        return 'https://drive.google.com/uc?export=view&id=$id';
      }
    }

    return raw;
  }

  static String? _googleDriveFileId(Uri uri) {
    // Examples:
    // - https://drive.google.com/file/d/<id>/view?usp=sharing
    // - https://drive.google.com/open?id=<id>
    // - https://drive.google.com/uc?id=<id>&export=download
    final segments = uri.pathSegments;
    if (segments.length >= 3 && segments[0] == 'file' && segments[1] == 'd') {
      return segments[2];
    }
    return uri.queryParameters['id'];
  }

  static bool _looksLikeNetworkUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  static bool _looksLikeAssetPath(String value) {
    return value.startsWith('images/') || value.startsWith('assets/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedImage = _normalizeImageUrl(image);
    final imageWidget = _looksLikeNetworkUrl(resolvedImage)
        ? Image.network(
            resolvedImage,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: progress.expectedTotalBytes == null
                        ? null
                        : progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stack) => _ImageErrorBox(
              message: '이미지를 불러올 수 없습니다.',
              detail: resolvedImage == image
                  ? image
                  : '$image → $resolvedImage',
            ),
          )
        : _looksLikeAssetPath(resolvedImage)
        ? Image.asset(
            resolvedImage,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => _ImageErrorBox(
              message: '에셋 이미지를 찾을 수 없습니다.',
              detail: resolvedImage,
            ),
          )
        : Image.network(
            '${ApiConfig.fastApiBaseUrl}/$resolvedImage',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => _ImageErrorBox(
              message: '이미지를 불러올 수 없습니다.',
              detail: resolvedImage,
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '미리보기',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        if (resolvedImage != image)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Google Drive 공유 링크는 변환해서 미리보기를 시도합니다.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF757575),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F8),
              border: Border.all(color: const Color(0xFFEEEEEE)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: AspectRatio(aspectRatio: 16 / 9, child: imageWidget),
          ),
        ),
      ],
    );
  }
}

class _ImageErrorBox extends StatelessWidget {
  const _ImageErrorBox({required this.message, required this.detail});

  final String message;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: const Color(0xFFF3F4F8),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image_outlined, color: Color(0xFF9E9E9E)),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF616161),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF9E9E9E),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
