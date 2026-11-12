import 'package:flutter/cupertino.dart';
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
          // 🌟 গ্লোবাল টেক্সট স্কেলার ফিক্স: যাতে কোনো মোবাইলেই টেক্সট বক্স উপচে না পড়ে
          builder: (context, child) {
            final mediaQueryData = MediaQuery.of(context);
            final constrainedTextScaler = mediaQueryData.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.15,
            );

            return MediaQuery(
              data: mediaQueryData.copyWith(textScaler: constrainedTextScaler),
              child: child!,
            );
          },
          // ১. লাইট থিম (Light Theme)
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            primaryColor: AppColors.primaryGreen,
            scaffoldBackgroundColor: AppColors.lightScaffoldBg,
            cardColor: AppColors.lightCardBg,
            dividerColor: AppColors.lightBorder,
            // 🌟 গ্লোবাল ব্যাক-সোয়াইপ সক্রিয়করণ (const ছাড়া)
            pageTransitionsTheme: PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              titleSpacing:
                  12.0, // বামের অতিরিক্ত স্পেস কমিয়ে টাইটেলের জায়গা বাড়ানো হলো
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 16.0, // ১৮ থেকে কমিয়ে ১৬.০ করায় লেখা আর উপচে পড়বে না
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              secondary: AppColors.energyGreen,
              surface: AppColors.lightCardBg,
            ),
          ),

          // ২. ডার্ক থিম (Dark Theme)
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primaryColor: AppColors.accentCyan,
            scaffoldBackgroundColor: AppColors.darkScaffoldBg,
            cardColor: AppColors.darkCardBg,
            dividerColor: AppColors.darkBorder,
            // 🌟 গ্লোবাল ব্যাক-সোয়াইপ সক্রিয়করণ (const ছাড়া)
            pageTransitionsTheme: PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.darkCardBg,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              titleSpacing:
                  12.0, // বামের অতিরিক্ত স্পেস কমিয়ে টাইটেলের জায়গা বাড়ানো হলো
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 16.0, // ১৭ থেকে কমিয়ে ১৬.০ করা হলো
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
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
