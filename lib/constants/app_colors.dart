import 'package:flutter/material.dart';

class AppColors {
  // ১. মূল ব্র্যান্ড অ্যাকসেন্ট (প্রিসিশন ক্লিন-টেক ও হাই-কনট্রাস্ট গ্রিন)
  static const Color primaryGreen = Color(
    0xFF063A24,
  ); // ডিপ বটানিক্যাল পাইন গ্রিন
  static const Color energyGreen = Color(
    0xFF059669,
  ); // ভাইব্রেন্ট এমারেল্ড গ্রিন
  static const Color accentCyan = Color(0xFF06B6D4); // ক্রিস্টাল নিয়ন সায়ান
  static const Color solarGold = Color(0xFFF59E0B); // সানবার্স্ট অ্যাম্বার
  static const Color alertRed = Color(0xFFE11D48); // পিওর রুবি রেড
  static const Color skyBlue = Color(0xFF38BDF8); // ইলেকট্রিক স্কাই ব্লু

  // ২. উইজেট ও মেনুর জন্য নির্দিষ্ট রং
  static const Color fabGreen = Color(0xFF059669);
  static const Color textMuted = Color(0xFF64748B);

  // ৩. ড্যাশবোর্ড ব্যানার ও টাইটেল কনস্ট্যান্ট
  static const Color titleRed = Color(0xFFE11D48);
  static const Color textDark = Color(0xFF0F172A);

  // ৪. লাইট মোড (ল্যাবরেটরি ক্লিন স্লেট ও হাই-কনট্রাস্ট)
  static const Color lightBgTop = Color(
    0xFFE2E8F0,
  ); // সফিস্টিকেটেড লাইট মেটালিক টিন্ট
  static const Color lightBgBottom = Color(0xFFF8FAFC); // পিওর ল্যাবরেটরি স্লেট
  static const Color lightScaffoldBg = Color(0xFFF8FAFC);

  // লাইট কার্ড ও ইনপুট
  static const Color lightCardBg = Color(0xFFFFFFFF); // পিওর হোয়াইট
  static const Color lightInputBg = Color(0xFFF1F5F9); // খাঁজ বা রিসেসড ফিল

  // সোলার অ্যাম্বার (অ্যাকসেন্ট)
  static const Color solarAmber = Color(0xFFD97706);
  static const Color solarAmberLight = Color(0xFFFEF3C7);

  // লাইট টেক্সট
  static const Color lightTextPrimary = Color(
    0xFF0B132B,
  ); // শার্প ডিপ ওলেড ব্ল্যাক
  static const Color lightTextSecondary = Color(
    0xFF334155,
  ); // স্পষ্ট মেটালিক স্লেট গ্রে
  static const Color lightBorderSoft = Color(0xFFCBD5E1);
  static const Color lightBorder = Color(0xFFCBD5E1);
  static Color lightCardShadow = const Color(0xFF0F172A)
      .withValues(alpha: 0.08);

  // ৫. ডার্ক মোড (ডিপ ওলেড ও কসমিক স্লেট প্যালেট)
  static const Color darkBgTop = Color(0xFF0D1526);
  static const Color darkBgBottom = Color(0xFF050B14); // ডিপ ওলেড স্লেট
  static const Color darkScaffoldBg = Color(0xFF050B14);
  static const Color darkCardBg = Color(0xFF0F172A);
  static const Color darkInputBg = Color(0xFF080D1A);
  static const Color darkBorder = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // ৬. ৩ডি টেকটাইল কার্ড ডেকোরেশন (Chiseled Bevel Contour & Tactile Depth)
  static BoxDecoration cardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? AppColors.darkCardBg : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark
            ? AppColors.darkBorder
            : const Color(0xFFCBD5E1).withValues(alpha: 0.8),
        width: 1.2,
      ),
      boxShadow: isDark
          ? [
              // ডার্কে সূক্ষ্ম গ্লো ও ডেপথ
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: AppColors.energyGreen.withValues(alpha: 0.04),
                blurRadius: 1,
                offset: const Offset(0, -1),
              ),
            ]
          : [
              // লাইটে মেটালিক ফিজিক্যাল শ্যাডো
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
              const BoxShadow(
                color: Colors.white,
                blurRadius: 0,
                spreadRadius: 1,
                offset: Offset(0, -1),
              ),
            ],
    );
  }

  // ৭. রিসেসড / খাঁজকাটা ইনপুট ডেকোরেশন (Sunken Cavity)
  static BoxDecoration recessedDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        width: 1.0,
      ),
    );
  }
}
