import 'package:flutter/material.dart';

class AppColors {
  // ১. মূল ব্র্যান্ড অ্যাকসেন্ট
  static const Color primaryGreen = Color(0xFF1B6A3B);
  static const Color energyGreen = Color(0xFF10B981);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color solarGold = Color(0xFFF59E0B);
  static const Color alertRed = Color(0xFFEF4444);
  static const Color skyBlue = Color(0xFF67B7D1);

  // ২. উইজেট ও মেনুর জন্য নির্দিষ্ট রং (যে দুটি মিসিং ছিল)
  static const Color fabGreen = Color(0xFF2E7D32);
  static const Color textMuted = Color(0xFF6B7280);

  // ৩. ড্যাশবোর্ড ব্যানার ও টাইটেল কনস্ট্যান্ট
  static const Color titleRed = Color(0xFFDC2626);
  static const Color textDark = Color(0xFF1E293B);

  // ৪. লাইট মোড (ইকো-গ্রিন প্যালেট - হাই কনট্রাস্ট ও স্মার্ট লুক)
  // স্পষ্ট ও প্রিমিয়াম গ্রেডিয়েন্ট
  // পরীক্ষা করার জন্য একটু বেশি কন্ট্রাস্ট দিয়ে দেখুন:
  static const Color lightBgTop = Color(
    0xFFD1E7DD,
  ); // স্পষ্ট দৃশ্যমান হালকা সবুজ টিন্ট
  static const Color lightBgBottom = Color(0xFFF0F4F8); // সফট ব্লুইশ-গ্রে

  // কার্ড ও ইনপুট
  static const Color lightCardBg = Color(0xFFFFFFFF); // পিওর হোয়াইট
  static const Color lightInputBg = Color(0xFFF1F5F9); // সফট ইনপুট ফিল

  // সোলার অ্যাম্বার (অ্যাকসেন্ট)
  static const Color solarAmber = Color(
    0xFFF59E0B,
  ); // ভাইব্রেন্ট সোলার গোল্ড/অ্যাম্বার
  static const Color solarAmberLight = Color(
    0xFFFEF3C7,
  ); // অ্যাম্বারের সফট ব্যাকগ্রাউন্ড

  // টেক্সট
  static const Color lightTextPrimary = Color(0xFF0F172A); // রিচ ডিপ স্লেট
  static const Color lightTextSecondary = Color(0xFF475569); // সফট মেটালিক গ্রে
  static const Color lightBorderSoft = Color(
    0xFFE2E8F0,
  ); // নিখুঁত সূক্ষ্ম বর্ডার

  // বর্ডার ও সফট শ্যাডো
  static const Color lightBorder = Color(0xFFE2E8F0); // অত্যন্ত সূক্ষ্ম ফ্রেম
  static Color lightCardShadow = const Color(0xFF0F172A)
      .withValues(alpha: 0.05); // সফট ফ্লোটিং শ্যাডো
  static const Color lightScaffoldBg = Color(0xFFF8FAFC);

  // ৫. ডার্ক মোড (কসমিক নেভি/স্লেট প্যালেট)
  static const Color darkBgTop = Color(0xFF0F172A);
  static const Color darkBgBottom = Color(0xFF090D16);
  static const Color darkScaffoldBg = Color(0xFF0B1120);
  static const Color darkCardBg = Color(0xFF1E293B);
  static const Color darkInputBg = Color(0xFF0F172A);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // lib/constants/app_colors.dart এর ভেতরে যোগ করুন:
  static BoxDecoration cardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? AppColors.darkCardBg : Colors.white, // খাঁটি সাদা
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark
            ? AppColors.darkBorder
            : const Color(0xFFCBD5E1)
                  .withValues(alpha: 0.6), // সফট ক্লিয়ার বর্ডার
        width: 1,
      ),
      boxShadow: isDark
          ? []
          : [
              BoxShadow(
                color: const Color(0xFF0F172A)
                    .withValues(alpha: 0.07), // একটু গভীর শ্যাডো
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }
}
