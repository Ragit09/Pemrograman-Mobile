import 'package:flutter/material.dart';
import 'screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MultiFormApp());
}

class MultiFormApp extends StatelessWidget {
  const MultiFormApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '3 Form App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      routes: {
        '/profile': (context) => const ProfileScreen(),
        '/survey': (context) => const SurveyScreen(),
      },
    );
  }
}