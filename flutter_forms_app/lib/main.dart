import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // TAMBAHKAN CONST CONSTRUCTOR

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Forms App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginPage(), // JADIKAN CONST
      debugShowCheckedModeBanner: false,
    );
  }
}