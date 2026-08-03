import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const WorderApp());
}

class WorderApp extends StatelessWidget {
  const WorderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WORDER',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
