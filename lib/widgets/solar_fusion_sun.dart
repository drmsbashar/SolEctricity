import 'dart:math' as math;

import 'package:flutter/material.dart';

/// বাস্তব সূর্যের অগ্নিকুণ্ড ও আগুনের ঝলকানির অ্যানিমেটেড সোলার ফিউশন উইজেট
class SolarFusionSun extends StatefulWidget {
  final double size;
  final bool isMini;

  const SolarFusionSun({super.key, this.size = 64, this.isMini = false});

  @override
  State<SolarFusionSun> createState() => _SolarFusionSunState();
}

class _SolarFusionSunState extends State<SolarFusionSun>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse =
            1.0 + 0.05 * math.sin(_controller.value * 2 * math.pi * 4);

        return Transform.scale(
          scale: widget.isMini ? 1.0 : pulse,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ১. দূরবর্তী লালচে-কমলা অগ্নিরশ্মি
                Transform.rotate(
                  angle: _controller.value * 2 * math.pi,
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _SolarFlamePainter(
                      animValue: _controller.value,
                      flareColor: const Color(0xFFEA580C),
                      flameCount: widget.isMini ? 8 : 12,
                      scaleFactor: 1.0,
                    ),
                  ),
                ),

                // ২. অভ্যন্তরীণ সোনালি-হলুদ শিখা স্তর
                Transform.rotate(
                  angle: -_controller.value * 2 * math.pi * 0.7,
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _SolarFlamePainter(
                      animValue: _controller.value + 0.3,
                      flareColor: const Color(0xFFFBBF24),
                      flameCount: widget.isMini ? 6 : 10,
                      scaleFactor: 0.86,
                    ),
                  ),
                ),

                // ৩. প্লাজমা করোনা আভা
                Container(
                  width: widget.size * 0.70,
                  height: widget.size * 0.70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFF59E0B).withValues(alpha: 0.7),
                        const Color(0xFFDC2626).withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                      stops: const [0.35, 0.75, 1.0],
                    ),
                  ),
                ),

                // ৪. জ্বলন্ত কেন্দ্রীয় পারমাণবিক ফিউশন কোর
                Container(
                  width: widget.size * 0.46,
                  height: widget.size * 0.46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Colors.white,
                        Color(0xFFFEF08A),
                        Color(0xFFF59E0B),
                        Color(0xFFDC2626),
                      ],
                      stops: [0.12, 0.45, 0.80, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
                        blurRadius: widget.size * 0.35,
                        spreadRadius: widget.size * 0.06,
                      ),
                      BoxShadow(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.6),
                        blurRadius: widget.size * 0.55,
                        spreadRadius: widget.size * 0.12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SolarFlamePainter extends CustomPainter {
  final double animValue;
  final Color flareColor;
  final int flameCount;
  final double scaleFactor;

  _SolarFlamePainter({
    required this.animValue,
    required this.flareColor,
    required this.flameCount,
    required this.scaleFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (size.width * 0.22) * scaleFactor;
    final maxRadius = (size.width * 0.48) * scaleFactor;

    for (int i = 0; i < flameCount; i++) {
      final angle = (i * 2 * math.pi) / flameCount;

      final flicker = math.sin((animValue * 2 * math.pi * 3) + (i * 1.5));
      final flameLength = maxRadius + (flicker * (size.width * 0.04));

      final path = Path();

      final startX = center.dx + baseRadius * math.cos(angle - 0.16);
      final startY = center.dy + baseRadius * math.sin(angle - 0.16);

      final tipX = center.dx + flameLength * math.cos(angle);
      final tipY = center.dy + flameLength * math.sin(angle);

      final endX = center.dx + baseRadius * math.cos(angle + 0.16);
      final endY = center.dy + baseRadius * math.sin(angle + 0.16);

      final ctrlDist = flameLength * 0.65;
      final ctrlX1 = center.dx + ctrlDist * math.cos(angle - 0.28);
      final ctrlY1 = center.dy + ctrlDist * math.sin(angle - 0.28);

      final ctrlX2 = center.dx + ctrlDist * math.cos(angle + 0.10);
      final ctrlY2 = center.dy + ctrlDist * math.sin(angle + 0.10);

      path.moveTo(startX, startY);
      path.quadraticBezierTo(ctrlX1, ctrlY1, tipX, tipY);
      path.quadraticBezierTo(ctrlX2, ctrlY2, endX, endY);
      path.close();

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            flareColor.withValues(alpha: 0.85),
            flareColor.withValues(alpha: 0.15),
            Colors.transparent,
          ],
          stops: const [0.2, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SolarFlamePainter oldDelegate) => true;
}
