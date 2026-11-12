import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

/// তাপমাত্রা কার্ভ (সর্বোচ্চ, গড় ও সর্বনিম্ন তাপমাত্রা এনভেলপ)
class TemperatureEnvelopeWithAxis extends StatelessWidget {
  final Map<String, double> tempAvg;
  final Map<String, double> tempMax;
  final Map<String, double> tempMin;
  final bool isDark;

  const TemperatureEnvelopeWithAxis({
    super.key,
    required this.tempAvg,
    required this.tempMax,
    required this.tempMin,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (tempAvg.isEmpty) return const SizedBox();

    final double minVal = (tempMin.values.reduce(math.min) - 2).clamp(
      -10.0,
      50.0,
    );
    final double maxVal = (tempMax.values.reduce(math.max) + 2).clamp(
      10.0,
      60.0,
    );
    final double midVal = (maxVal + minVal) / 2.0;

    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${maxVal.toStringAsFixed(0)}°',
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
                  fontSize: 8.5,
                ),
              ),
              Text(
                '${midVal.toStringAsFixed(0)}°',
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
                  fontSize: 8.5,
                ),
              ),
              Text(
                '${minVal.toStringAsFixed(0)}°',
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
                  fontSize: 8.5,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: TemperatureEnvelopePainter(
                    tempAvg: tempAvg,
                    tempMax: tempMax,
                    tempMin: tempMin,
                    minVal: minVal,
                    maxVal: maxVal,
                    isDark: isDark,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: tempAvg.keys.map((m) {
                  return Text(
                    m.substring(0, 1),
                    style: TextStyle(
                      color: isDark
                          ? Colors.white38
                          : AppColors.lightTextSecondary,
                      fontSize: 9,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TemperatureEnvelopePainter extends CustomPainter {
  final Map<String, double> tempAvg;
  final Map<String, double> tempMax;
  final Map<String, double> tempMin;
  final double minVal;
  final double maxVal;
  final bool isDark;

  TemperatureEnvelopePainter({
    required this.tempAvg,
    required this.tempMax,
    required this.tempMin,
    required this.minVal,
    required this.maxVal,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (tempAvg.isEmpty) return;

    final double range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final Paint gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)
      ..strokeWidth = 1.0;
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), gridPaint);
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      gridPaint,
    );

    final double dx = size.width / (tempAvg.length - 1);

    final Path bandPath = Path();
    final Path avgLinePath = Path();

    final List<Offset> maxPoints = [];
    final List<Offset> minPoints = [];
    final List<Offset> avgPoints = [];

    int i = 0;
    for (var key in tempAvg.keys) {
      final double x = i * dx;
      final double yMax =
          size.height - ((tempMax[key]! - minVal) / range) * size.height;
      final double yMin =
          size.height - ((tempMin[key]! - minVal) / range) * size.height;
      final double yAvg =
          size.height - ((tempAvg[key]! - minVal) / range) * size.height;

      maxPoints.add(Offset(x, yMax));
      minPoints.add(Offset(x, yMin));
      avgPoints.add(Offset(x, yAvg));
      i++;
    }

    bandPath.moveTo(maxPoints.first.dx, maxPoints.first.dy);
    for (var pt in maxPoints) {
      bandPath.lineTo(pt.dx, pt.dy);
    }
    for (var pt in minPoints.reversed) {
      bandPath.lineTo(pt.dx, pt.dy);
    }
    bandPath.close();

    final Paint bandPaint = Paint()
      ..color = Colors.orangeAccent.withValues(alpha: isDark ? 0.18 : 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawPath(bandPath, bandPaint);

    avgLinePath.moveTo(avgPoints.first.dx, avgPoints.first.dy);
    for (var pt in avgPoints) {
      avgLinePath.lineTo(pt.dx, pt.dy);
    }

    final Paint avgPaint = Paint()
      ..color = AppColors.solarGold
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(avgLinePath, avgPaint);

    final Paint dotPaint = Paint()
      ..color = isDark ? Colors.white : Colors.black87;
    for (var pt in avgPoints) {
      canvas.drawCircle(pt, 2.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// ১২ মাসের নাসা সৌর বিকিরণ (PSH) বার চার্ট
class SolarPshChartWithAxis extends StatelessWidget {
  final Map<String, double> monthlyPsh;
  final double annualAvgPsh;
  final bool isDark;

  const SolarPshChartWithAxis({
    super.key,
    required this.monthlyPsh,
    required this.annualAvgPsh,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const double yMax = 7.0;

    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '6.0',
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
                  fontSize: 8,
                ),
              ),
              Text(
                '4.0',
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
                  fontSize: 8,
                ),
              ),
              Text(
                '2.0',
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
                  fontSize: 8,
                ),
              ),
              Text(
                '0.0',
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.lightTextSecondary,
                  fontSize: 8,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: PshGridAndAvgPainter(
                    annualAvgPsh: annualAvgPsh,
                    yMax: yMax,
                    isDark: isDark,
                  ),
                ),
              ),
              Column(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: monthlyPsh.entries.map((entry) {
                        final double barRatio = (entry.value / yMax).clamp(
                          0.05,
                          1.0,
                        );
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  entry.value.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.accentCyan
                                        : const Color(0xFF0284C7),
                                    fontSize: 8.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Container(
                                      height: 70 * barRatio,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: isDark
                                              ? [
                                                  AppColors.accentCyan,
                                                  Colors.blueAccent,
                                                ]
                                              : [
                                                  const Color(0xFF38BDF8),
                                                  const Color(0xFF0284C7),
                                                ],
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: monthlyPsh.keys.map((m) {
                      return Expanded(
                        child: Text(
                          m.substring(0, 1),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white60
                                : AppColors.lightTextSecondary,
                            fontSize: 9.5,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PshGridAndAvgPainter extends CustomPainter {
  final double annualAvgPsh;
  final double yMax;
  final bool isDark;

  PshGridAndAvgPainter({
    required this.annualAvgPsh,
    required this.yMax,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double chartHeight = size.height - 18;

    final Paint gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    for (double v = 2.0; v <= 6.0; v += 2.0) {
      final double y = chartHeight - (v / yMax) * chartHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final double avgY = chartHeight - (annualAvgPsh / yMax) * chartHeight;
    final Paint avgLinePaint = Paint()
      ..color = AppColors.solarGold.withValues(alpha: 0.8)
      ..strokeWidth = 1.2;

    const double dashWidth = 4.0;
    const double dashSpace = 3.0;
    double startX = 0.0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, avgY),
        Offset(startX + dashWidth, avgY),
        avgLinePaint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
