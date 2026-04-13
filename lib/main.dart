import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:yeouido_parking_flutter/firebase_options.dart';
import 'package:yeouido_parking_flutter/utils/app_route/app_router.dart';
import 'package:yeouido_parking_flutter/view/auth/admin_auth_login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      ),
      debugShowCheckedModeBanner: false,
      home: const AdminLoginPage(),
      onGenerateRoute: AppRouter.generate,
    );
  }
}
