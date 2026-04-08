import 'package:flutter/material.dart';

import 'app_route.dart';
// ===== ADMIN =====
import 'package:yeouido_parking_flutter/view/admin_login.dart';
import 'package:yeouido_parking_flutter/view/admin_main_page.dart';
import 'package:yeouido_parking_flutter/view/admin_asking_list.dart';
import 'package:yeouido_parking_flutter/view/admin_asking_response.dart';
import 'package:yeouido_parking_flutter/view/admin_asking_view.dart';
import 'package:yeouido_parking_flutter/view/admin_reservation_list.dart';
import 'package:yeouido_parking_flutter/view/admin_reservation_view.dart';

class AppRouter {
  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      // ===== ADMIN =====
      case AppRoute.adminLogin:
        return MaterialPageRoute(builder: (_) => const AdminLogin());
      case AppRoute.adminMainPage:
        return MaterialPageRoute(builder: (_) => const AdminMainPage());
      case AppRoute.adminAskingList:
        return MaterialPageRoute(builder: (_) => const AdminAskingList());
      case AppRoute.adminAskingResponse:
        return MaterialPageRoute(builder: (_) => const AdminAskingResponse());
      case AppRoute.adminAskingView:
        return MaterialPageRoute(builder: (_) => const AdminAskingView());
      case AppRoute.adminReservationList:
        return MaterialPageRoute(builder: (_) => const AdminReservationList());
      case AppRoute.adminReservationView:
        return MaterialPageRoute(builder: (_) => const AdminReservationView());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }
}
