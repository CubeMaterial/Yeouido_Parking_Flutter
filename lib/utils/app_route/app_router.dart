import 'package:flutter/material.dart';
import 'package:yeouido_parking_flutter/view/auth/admin_auth_login.dart';
import 'package:yeouido_parking_flutter/view/auth/auth_login.dart';
import 'package:yeouido_parking_flutter/view/auth/auth_register.dart';

import 'app_route.dart';
// ===== ADMIN =====
import 'package:yeouido_parking_flutter/view/admin_main_page.dart';
import 'package:yeouido_parking_flutter/view/asking/admin_asking_list.dart';
import 'package:yeouido_parking_flutter/view/asking/admin_asking_response.dart';
import 'package:yeouido_parking_flutter/view/asking/admin_asking_view.dart';
import 'package:yeouido_parking_flutter/view/facility/admin_facility_add.dart';
import 'package:yeouido_parking_flutter/view/facility/admin_facility_list.dart';
import 'package:yeouido_parking_flutter/view/facility/admin_facility_update.dart';
import 'package:yeouido_parking_flutter/view/facility/admin_facility_view.dart';
import 'package:yeouido_parking_flutter/view/parking/admin_parking_add.dart';
import 'package:yeouido_parking_flutter/view/parking/admin_parking_list.dart';
import 'package:yeouido_parking_flutter/view/parking/admin_parking_update.dart';
import 'package:yeouido_parking_flutter/view/parking/admin_parking_view.dart';
import 'package:yeouido_parking_flutter/view/reservation/admin_reservation_list.dart';
import 'package:yeouido_parking_flutter/view/reservation/admin_reservation_view.dart';
import 'package:yeouido_parking_flutter/model/facility.dart';
import 'package:yeouido_parking_flutter/model/parking.dart';

class AppRouter {
  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      // ===== USER =====
      case AppRoute.userLogin:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case AppRoute.userRegister:
        return MaterialPageRoute(builder: (_) => const SignupPage());

      // ===== ADMIN =====
      case AppRoute.adminLogin:
        return MaterialPageRoute(builder: (_) => const AdminLoginPage());
      case AppRoute.adminMainPage:
        return MaterialPageRoute(builder: (_) => const AdminMainPage());
      case AppRoute.adminParkingList:
        return MaterialPageRoute(builder: (_) => const AdminParkingList());
      case AppRoute.adminParkingView:
        {
          final args = settings.arguments;
          final parkingId = switch (args) {
            int v => v,
            Map m => int.tryParse(m['parking_id']?.toString() ?? ''),
            _ => null,
          };
          final initialParking = args is Map
              ? Parking.fromJson(Map<String, dynamic>.from(args))
              : null;
          return MaterialPageRoute(
            builder: (_) => AdminParkingView(
              parkingId: parkingId,
              initialParking: initialParking,
            ),
          );
        }
      case AppRoute.adminParkingUpdate:
        {
          final args = settings.arguments;
          final parkingId = args is int
              ? args
              : args is Map
              ? int.tryParse(args['parking_id']?.toString() ?? '')
              : null;
          final initialParking = args is Map && args['parking'] is Map
              ? Parking.fromJson(
                  Map<String, dynamic>.from(args['parking'] as Map),
                )
              : null;
          return MaterialPageRoute(
            builder: (_) => AdminParkingUpdate(
              parkingId: parkingId,
              initialParking: initialParking,
            ),
          );
        }
      case AppRoute.adminParkingAdd:
        return MaterialPageRoute(builder: (_) => const AdminParkingAdd());
      case AppRoute.adminAskingList:
        return MaterialPageRoute(builder: (_) => const AdminAskingList());
      case AppRoute.adminAskingResponse:
        return MaterialPageRoute(builder: (_) => const AdminAskingResponse());
      case AppRoute.adminAskingView:
        final args = settings.arguments;
        final chatId = args is Map ? args['chatId']?.toString() : null;
        final title = args is Map ? args['title']?.toString() : null;
        return MaterialPageRoute(
          builder: (_) => AdminAskingView(chatId: chatId, title: title),
        );
      case AppRoute.adminReservationList:
        return MaterialPageRoute(builder: (_) => const AdminReservationList());
      case AppRoute.adminReservationView:
        final args = settings.arguments;
        final reservationId = switch (args) {
          int v => v,
          Map m => int.tryParse(m['reservation_id']?.toString() ?? ''),
          _ => null,
        };
        final initialDetail = args is Map
            ? Map<String, dynamic>.from(args)
            : null;
        return MaterialPageRoute(
          builder: (_) => AdminReservationView(
            reservationId: reservationId,
            initialDetail: initialDetail,
          ),
        );
      case AppRoute.adminFacilityList:
        return MaterialPageRoute(builder: (_) => const AdminFacilityList());
      case AppRoute.adminFacilityView:
        {
          final args = settings.arguments;
          final facilityId = switch (args) {
            int v => v,
            Map m => int.tryParse(m['facility_id']?.toString() ?? ''),
            _ => null,
          };
          final initialFacility = args is Map
              ? Facility.fromJson(Map<String, dynamic>.from(args))
              : null;
          return MaterialPageRoute(
            builder: (_) => AdminFacilityView(
              facilityId: facilityId,
              initialFacility: initialFacility,
            ),
          );
        }
      case AppRoute.adminFacilityUpdate:
        {
          final args = settings.arguments;
          final facilityId = args is int
              ? args
              : args is Map
              ? int.tryParse(args['facility_id']?.toString() ?? '')
              : null;
          final initialFacility = args is Map && args['facility'] is Map
              ? Facility.fromJson(
                  Map<String, dynamic>.from(args['facility'] as Map),
                )
              : null;
          return MaterialPageRoute(
            builder: (_) => AdminFacilityUpdate(
              facilityId: facilityId,
              initialFacility: initialFacility,
            ),
          );
        }
      case AppRoute.adminFacilityAdd:
        return MaterialPageRoute(builder: (_) => const AdminFacilityAdd());
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }
}
