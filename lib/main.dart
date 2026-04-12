import 'package:flutter/material.dart';
import 'package:yeouido_parking_flutter/utils/app_route/app_router.dart';
import 'package:yeouido_parking_flutter/view/auth/auth_login.dart';

void main() {
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
      home: const LoginPage(),
      onGenerateRoute: AppRouter.generate,
    );
  }
}
