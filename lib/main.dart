import 'package:flutter/material.dart';
import 'package:greenbank/pages/LoginPage.dart';
import 'package:greenbank/pages/RegisterPage.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
        useMaterial3: true,
      ),
      home: const LoginPageWidget(),
      routes: {
        '/login': (context) => const LoginPageWidget(),
        '/registro': (context) => const RegisterPage(),
      },
    );
  }
}