// 문의 답변 (관리자 웹) - TODO
import 'package:flutter/material.dart';
import 'package:yeouido_parking_flutter/view/common/admin_sidebar.dart';
import 'package:yeouido_parking_flutter/view/common/admin_top_bar.dart';

class AdminAskingResponse extends StatefulWidget {
  const AdminAskingResponse({super.key});

  @override
  State<AdminAskingResponse> createState() => _AdminAskingResponseState();
}

class _AdminAskingResponseState extends State<AdminAskingResponse> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 3;

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
                    const Expanded(
                      child: Center(child: Text('문의글 답변 (TODO)')),
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

