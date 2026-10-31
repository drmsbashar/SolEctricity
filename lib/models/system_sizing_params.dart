class SystemSizingParams {
  // ১. সিস্টেম ভোল্টেজ (V)
  double systemVoltage;

  // ২-৫. সোলার প্যানেল স্পেসিফিকেশন (Wp, V, A)
  double panelPmax; // Pmax
  double panelVoc; // Voc
  double panelImp; // Imp
  double panelIsc; // Isc

  // ৬-৯. ব্যাটারি ব্যাংক স্পেসিফিকেশন
  double batteryCapacityAh; // ধারণ ক্ষমতা (Ah)
  double batteryEfficiency; // কর্মক্ষমতা (% যেমন: 80)
  double batteryDod; // ব্যবহারের অংশ বা DoD (% যেমন: 70)
  int autonomyDays; // মেঘলা দিনের সংখ্যা (দিন)

  // ১০. গড়পড়তা সৌর-সময় (Peak Sun Hours)
  double peakSunHours;

  // ১১-১২. ইনভার্টার স্পেসিফিকেশন
  double inverterEfficiency; // কর্মক্ষমতা (% যেমন: 90)
  double inverterPowerFactor; // পাওয়ার ফ্যাক্টর (যেমন: 0.85)

  SystemSizingParams({
    required this.systemVoltage,
    required this.panelPmax,
    required this.panelVoc,
    required this.panelImp,
    required this.panelIsc,
    required this.batteryCapacityAh,
    required this.batteryEfficiency,
    required this.batteryDod,
    required this.autonomyDays,
    required this.peakSunHours,
    required this.inverterEfficiency,
    required this.inverterPowerFactor,
  });

  // দৈনিক লোডের ওপর ভিত্তি করে স্বয়ংক্রিয় ডিফল্ট ভ্যালু জেনারেটর
  factory SystemSizingParams.defaultForLoad(
    double dailyTotalWh, [
    double acPeakWatt = 0,
  ]) {
    double recommendedVoltage;

    // পিক ওয়াট অথবা দৈনিক Wh যেটি বড় ভোল্টেজ নির্দেশ করে সেটি নেওয়া
    if (dailyTotalWh <= 1500 && acPeakWatt <= 1000) {
      recommendedVoltage = 12.0;
    } else if (dailyTotalWh <= 3000 && acPeakWatt <= 2500) {
      recommendedVoltage = 24.0;
    } else {
      recommendedVoltage =
          48.0; // আবাসিক অফ-গ্রিডের জন্য ৪৮V সর্বোচ্চ আদর্শ মান
    }

    return SystemSizingParams(
      systemVoltage: recommendedVoltage,
      panelPmax: 150.0,
      panelVoc: 22.70,
      panelImp: 8.20,
      panelIsc: 8.80,
      batteryCapacityAh: 100.0,
      batteryEfficiency: 80.0,
      batteryDod: 70.0,
      autonomyDays: 2,
      peakSunHours: 5.5,
      inverterEfficiency: 90.0,
      inverterPowerFactor: 0.85,
    );
  }
}
