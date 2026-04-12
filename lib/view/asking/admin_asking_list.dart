// 문의글 리스트
import 'package:flutter/material.dart';
import 'package:yeouido_parking_flutter/view/common/admin_sidebar.dart';
import 'package:yeouido_parking_flutter/view/common/admin_top_bar.dart';

class AdminAskingList extends StatefulWidget {
  const AdminAskingList({super.key});

  @override
  State<AdminAskingList> createState() => _AdminAskingListState();
}

class _AdminAskingListState extends State<AdminAskingList> {
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
                      onMenuPressed: useDrawer
                          ? () => _scaffoldKey.currentState?.openDrawer()
                          : null,
                    ),
                    const Expanded(
                      child: Center(child: Text('문의글 리스트 (TODO)')),
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
