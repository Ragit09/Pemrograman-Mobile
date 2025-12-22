import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';

void main() {
  // WAJIB: Initialize Flutter binding sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 ==========================================');
  print('🚀 FINFLOW APP STARTING');
  print('🚀 ==========================================');
  print('📱 Time: ${DateTime.now()}');
  print('🚀 ==========================================');
  
  // Global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    print('🔥 FLUTTER ERROR: ${details.exception}');
    print('🔥 Stack trace: ${details.stack}');
  };
  
  // Run app dengan error boundary
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => TransactionProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'FinFlow',
            theme: themeProvider.currentTheme,
            home: const HomeScreen(),
            debugShowCheckedModeBanner: false,
            // Error boundary untuk menangani crash
            builder: (context, child) {
              return ErrorBoundary(
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}

class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Oops! Terjadi Kesalahan',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  _errorMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Coba restart dengan reset state
                        setState(() {
                          _hasError = false;
                          _errorMessage = '';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () {
                        // Reset aplikasi secara paksa
                        final transactionProvider =
                            Provider.of<TransactionProvider>(context, listen: false);
                        transactionProvider.resetAllData();
                        
                        setState(() {
                          _hasError = false;
                          _errorMessage = '';
                        });
                      },
                      child: const Text('Reset App'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return widget.child;
  }
}