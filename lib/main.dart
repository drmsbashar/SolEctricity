import 'package:flutter/material.dart';
import 'views/dashboard_screen.dart';

void main() {
  runApp(const SolectricityApp());
}

class SolectricityApp extends StatelessWidget {
  const SolectricityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solectricity',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F4C81)),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}