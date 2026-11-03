import 'package:flutter/material.dart';

import 'constants/app_colors.dart';
import 'theme/theme_controller.dart';
import 'views/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SolectricityApp());
}

class SolectricityApp extends StatelessWidget {
  const SolectricityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'সূর্য বিদ্যুৎ',
          themeMode: ThemeController.instance.themeMode,
          // লাইট থিম
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            primaryColor: AppColors.primaryGreen,
            scaffoldBackgroundColor: AppColors.lightScaffoldBg,
            cardColor: AppColors.lightCardBg,
            dividerColor: AppColors.lightBorder,

            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0, // ফ্ল্যাট রেখে কার্ভের মাধ্যমে ডেপথ তৈরি
              centerTitle: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(
                    16,
                  ), // 👈 AppBar-এর নিচে সফট রাউন্ড কার্ভ
                ),
              ),
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              secondary: AppColors.energyGreen,
              surface: AppColors.lightCardBg,
            ),
          ),
          // ডার্ক থিম
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primaryColor: AppColors.accentCyan,
            scaffoldBackgroundColor: AppColors.darkScaffoldBg,
            cardColor: AppColors.darkCardBg,
            dividerColor: AppColors.darkBorder,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.darkCardBg,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentCyan,
              secondary: AppColors.solarGold,
              surface: AppColors.darkCardBg,
            ),
          ),
          home: const DashboardScreen(),
        );
      },
    );
  }
}
