import 'package:flutter/material.dart';
import 'package:yeouido_parking_flutter/utils/app_route/app_route.dart';

class RouterPage extends StatelessWidget {
  const RouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SeatUp Main (Route Hub)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('ADMIN'),

          _btn(context, 'admin_login', AppRoute.adminLogin),
          _btn(context, 'admin_dashboard', AppRoute.adminMainPage),
          // _btn(context, 'admin_curtain_create', AppRoute.adminCurtainCreate),
          _btn(context, 'admin_curtain_edit', AppRoute.adminAskingList),
          _btn(context, 'faq_list', AppRoute.adminAskingResponse),
          _btn(context, 'faq_insert', AppRoute.adminAskingView),
          _btn(context, 'faq_update', AppRoute.adminReservationList),
          _btn(context, 'faq_detail', AppRoute.adminReservationView),
        ],
      ),
    );
  }

  // ================= helper =================

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _btn(BuildContext context, String label, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(context, route);
        },
        style: ElevatedButton.styleFrom(alignment: Alignment.centerLeft),
        child: Text(label),
      ),
    );
  }
}
