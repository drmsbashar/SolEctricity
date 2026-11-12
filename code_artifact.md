# সূর্য বিদ্যুৎ (SolEctricity Suite) — আর্কিটেকচার ও পূর্ণ গাণিতিক স্পেসিফিকেশন

---

## ১. হাই-লেভেল সিস্টেম আর্কিটেকচার (Layered Clean Architecture)

```
┌────────────────────────────────────────────────────────────────────────┐
│                   ১. Presentation Layer (ইউজার ইন্টারফেস)               │
│   • DashboardScreen (সেন্ট্রাল হাব ও ন্যাভিগেশন)                       │
│   • LandBasedSolarScreen (ম্যাপ পলিগন ও বাউন্ডারি ড্রয়িং)              │
│   • LandSolarResultScreen (৪টি বিস্তারিত ট্যাব ও হোম বাটন)            │
│   • CostBasedSolarScreen / CapacityBasedSolarScreen                    │
│   • FinancialAnalysisScreen (LCOE, NPV ও ESG মডেল)                     │
│   • Reusable Widgets: ClimateCharts, WiringPainters, CustomStatCard    │
└───────────────────────────────────▲────────────────────────────────────┘
                                    │ (Events / State Updates)
┌───────────────────────────────────┴────────────────────────────────────┐
│              ২. Business Logic / Domain Services Layer (মূল ইঞ্জিন)    │
│   • SolarGeometryEngine (কার্টেসিয়ান প্রজেকশন, পিচ স্পেসিং ও গ্রিড)  │
│   • SolarCalculationService (টেম্পারেচার ডিরেট, PR ও ব্যাটারি সাইজিং)  │
│   • FinancialCalculationEngine (LCOE, NPV, IRR, পে-ব্যাক ও ক্যাশফ্লো)  │
│   • LandPdfExportService (ক্যানভাস রেন্ডারিং ও হাই-রেজোলিউশন PDF)      │
│   • LocationSearchService (নমিনেটিম জিওকোডিং ও সার্চিং)                │
└───────────────────────────────────▲────────────────────────────────────┘
                                    │ (DTOs / Pure Models)
┌───────────────────────────────────┴────────────────────────────────────┐
│                    ৩. Data & Model Layer (ডেটা ও মডেল)                  │
│   • SystemSizingParams, SolarCalculationResult, CashFlowRow            │
│   • Enums: BatteryChemistry (LeadAcid, Tubular, Lithium)               │
│   • Enums: SolarSystemType (GridTied, Hybrid, OffGrid)                 │
│   • TariffConfig (BERC স্ল্যাব রেট)                                    │
└───────────────────────────────────▲────────────────────────────────────┘
                                    │ (Network Requests & Hardware Access)
┌───────────────────────────────────┴────────────────────────────────────┐
│               ৪. Infrastructure / External Integrations                │
│   • NASA POWER API (সৌর বিকিরণ/PSH, তাপমাত্রা, বাতাসের গতিবেগ)         │
│   • OpenStreetMap / ArcGIS World Imagery (স্যাটেলাইট ম্যাপ টাইলস)       │
│   • BERC ট্যারিফ ও রেগুলেটরি প্যারামিটার                               │
│   • ডিভাইস হার্ডওয়্যার (জিপিএস / Geolocator, ক্যানভাস ইমেজ প্রসেসিং)  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## ২. ডিরেক্টরি কাঠামো (Project File Structure)

```text
lib/
├── constants/
│   ├── app_colors.dart                 # ডার্ক ও লাইট থিমের কালার প্যালেট
│   ├── app_constants.dart              # টেকনিক্যাল ডিফল্ট কনস্ট্যান্ট
│   └── app_assets.dart                 # লোগো ও ব্র্যান্ডিং ভেক্টর
├── models/
│   ├── battery_chemistry.dart          # ব্যাটারি কেমিস্ট্রি Enums
│   ├── solar_system_type.dart          # অন-গ্রিড, হাইব্রিড, অফ-গ্রিড Enums
│   ├── system_sizing_params.dart       # সাইজিং ইনপুট প্যারামিটার
│   ├── solar_calculation_result.dart   # সিস্টেম সাইজিং আউটপুট স্পেক্স
│   ├── cash_flow_row.dart              # ২৫ বছরের প্রো-ফরমা ক্যাশফ্লো
│   └── place_search_result.dart        # ম্যাপ সার্চ রেজাল্ট মডেল
├── services/
│   ├── solar_geometry_engine.dart      # পিচ, টিল্ট ও ডিসক্রিট গ্রিড হিসাব
│   ├── solar_calculation_service.dart  # টেম্পারেচার ডিরেট ও সিস্টেম সাইজিং
│   ├── financial_calculation_engine.dart # LCOE, NPV, IRR ও ক্যাশফ্লো ইঞ্জিন
│   ├── solar_radiation_service.dart    # নাসা ক্লাইমেট ডেটা ও ক্যাশিং
│   ├── location_search_service.dart    # জিওকোডিং ও প্লেস সার্চ
│   └── land_pdf_export_service.dart    # ক্যানভাস A4 হাই-রেজোলিউশন PDF ইঞ্জিন
├── views/
│   ├── dashboard_screen.dart           # মূল ড্যাশবোর্ড
│   ├── land_based_solar_screen.dart    # ম্যাপ ইন্টারফেস ও বাউন্ডারি ড্রয়িং
│   ├── land_solar_result_screen.dart   # ৪টি ট্যাবের বিস্তারিত রেজাল্ট স্ক্রিন
│   ├── capacity_based_solar_screen.dart# ইউনিট ও লোড ভিত্তিক সাইজিং
│   ├── cost_based_solar_screen.dart    # বাজেট ভিত্তিক সাইজিং
│   └── financial_analysis_screen.dart  # ব্যাংক-গ্রেড আর্থিক ও পরিবেশগত বিশ্লেষণ
└── widgets/
    ├── climate_charts.dart             # Temperature ও SolarPsh চার্ট
    ├── wiring_painters.dart            # স্কিম্যাটিক ও বাস্তব জাম্পার ড্রয়িং
    └── custom_stat_card.dart           # মেট্রিক কার্ড উইজেট
```

---

## ৩. গাণিতিক সূত্রাবলী ও প্রকৌশল হিসাব (Mathematical Engines)

### ক. লোকাল কার্টেসিয়ান প্রজেকশন ও ক্ষেত্রফল (Shoelace Formula)
ম্যাপের গোলীয় স্থানাঙ্ক ($Lat, Lon$) থেকে মিটারে রূপান্তর:
$$x = (\lambda - \lambda_0) \times 111412.84 \times \cos(\phi_0)$$
$$y = (\phi - \phi_0) \times 111132.954$$

বহুভুজের নিট ক্ষেত্রফল ($A_{net}$):
$$A_{net} = A_{boundary} - A_{obstacles} = \frac{1}{2} \left| \sum_{i=0}^{n-1} (x_i y_{i+1} - x_{i+1} y_i) \right| - \sum A_{obs}$$

---

### খ. শীতকালীন ছায়ামুক্ত সারি দূরত্ব (Winter Solstice Row Pitch)
২১ ডিসেম্বরের সর্বনিম্ন সৌর উচ্চতা কোণ ($\alpha_{dec21}$):
$$\alpha_{dec21} = 90^\circ - \text{Latitude} - 23.45^\circ$$

মডিউল টিল্ট কোণ ($\beta$) এবং দৈর্ঘ্য ($L$)-এর ভিত্তিতে আন্তঃসারি ফাঁকা দূরত্ব ($D_{pitch}$):
$$h = L \times \sin(\beta)$$
$$D_{pitch} = L \times \cos(\beta) + \frac{h}{\tan(\alpha_{dec21})}$$

---

### গ. ডিসক্রিট গ্রিড বিন্যাস ও মোট প্যানেল সংখ্যা
$$Rows = \left\lfloor \frac{\text{North-South Span}}{D_{pitch}} \right\rfloor, \quad Cols = \left\lfloor \frac{\text{East-West Span}}{W_{module}} \right\rfloor$$
$$\text{Total Modules} = Rows \times Cols$$
$$P_{DC} (\text{kWp}) = \frac{\text{Total Modules} \times W_{module}}{1000}$$

---

### ঘ. তাপমাত্রাজনিত ডিরেটিং ও সিস্টেম পারফরম্যান্স রেশিও (PR)
সিলিকন সেলের তাপমাত্রা সহগ ($\gamma = -0.004 / ^\circ\text{C}$):
$$f_{temp} = 1.0 + (\gamma \times (T_{ambient} - 25^\circ\text{C}))$$

ব্যাটারি কেমিস্ট্রি অনুযায়ী বেস পারফরম্যান্স রেশিও ($PR_{base}$):
- অন-গ্রিড (Grid-Tied): $0.80$
- হাইব্রিড / অফ-গ্রিড (Lithium LiFePO₄): $0.80$
- হাইব্রিড / অফ-গ্রিড (Tubular Deep-Cycle): $0.74$
- হাইব্রিড / অফ-গ্রিড (Lead-Acid): $0.70$

কার্যকর পারফরম্যান্স রেশিও ($PR_{effective}$):
$$PR_{effective} = PR_{base} \times f_{temp}$$

---

### ঙ. বিদ্যুৎ উৎপাদন প্রাক্কলন
$$E_{daily} (\text{kWh}) = P_{DC} \times PSH \times PR_{effective}$$
$$E_{monthly} (\text{kWh}) = E_{daily} \times 30$$
$$E_{annual, Yr1} (\text{kWh}) = E_{daily} \times 365$$

২৫ বছরের মোট উৎপাদন ($0.5\%$ বার্ষিক অবক্ষয় বিবেচনা করে):
$$E_{lifetime, 25yr} \approx E_{annual, Yr1} \times 25 \times 0.94$$

---

### চ. আর্থিক ও পরিবেশগত বিশ্লেষণ (Financial & ESG Metrics)
- সিস্টেমের মোট বাজেট:
$$\text{Estimated Cost} = P_{DC} \times 1000 \times \text{PricePerWatt}$$
- বার্ষিক কার্বন নির্গমন হ্রাস:
$$\text{CO}_2 \text{ Avoided (kg/yr)} = E_{annual} \times 0.62$$
- সমতুল্য বৃক্ষরোপণ:
$$\text{Equivalent Trees} = \frac{\text{CO}_2 \text{ Avoided}}{20}$$