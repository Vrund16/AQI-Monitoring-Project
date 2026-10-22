import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/sensor_reading.dart';

class AqiHeroGauge extends StatefulWidget {
  final SensorReading reading;

  const AqiHeroGauge({super.key, required this.reading});

  @override
  State<AqiHeroGauge> createState() => _AqiHeroGaugeState();
}

class _AqiHeroGaugeState extends State<AqiHeroGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnim;
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    final target = (widget.reading.compositeScore / 300.0).clamp(0.0, 1.0);
    _progressAnim = Tween<double>(
      begin: 0.0,
      end: target,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _currentProgress = target;
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant AqiHeroGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reading.compositeScore != widget.reading.compositeScore) {
      final target = (widget.reading.compositeScore / 300.0).clamp(0.0, 1.0);
      _progressAnim = Tween<double>(
        begin: _currentProgress,
        end: target,
      ).animate(CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ));
      _currentProgress = target;
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final aqiColor = widget.reading.aqiColor;
    final category = widget.reading.aqiCategory;
    final score = widget.reading.compositeScore;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: aqiColor.withOpacity(isDark ? 0.35 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: aqiColor.withOpacity(isDark ? 0.15 : 0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Device ID & Live Sensor Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.router_rounded,
                      size: 14,
                      color: isDark ? Colors.cyanAccent : Colors.teal,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.reading.deviceId,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? Colors.white70 : const Color(0xFF334155),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: aqiColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: aqiColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: aqiColor.withOpacity(0.8),
                            blurRadius: 6,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE MONITOR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: aqiColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Custom Arc Gauge with Safe AnimatedBuilder and child reuse
          SizedBox(
            height: 180,
            width: 250,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, staticChild) {
                return CustomPaint(
                  painter: _GaugePainter(
                    progress: _progressAnim.value,
                    color: aqiColor,
                    isDark: isDark,
                  ),
                  child: staticChild,
                );
              },
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AIR QUALITY INDEX',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white38 : const Color(0xFF64748B),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Category Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  aqiColor.withOpacity(0.2),
                  aqiColor.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: aqiColor.withOpacity(0.5),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  score <= 100
                      ? Icons.check_circle_rounded
                      : (score <= 150
                          ? Icons.warning_amber_rounded
                          : Icons.emergency_rounded),
                  size: 18,
                  color: aqiColor,
                ),
                const SizedBox(width: 8),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: aqiColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Short descriptive guideline
          Text(
            widget.reading.healthSummary,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  _GaugePainter({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.78);
    final radius = size.width * 0.44;

    const startAngle = math.pi * 0.85;
    const sweepAngle = math.pi * 1.30;

    // Track Background
    final trackPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Active Progress Arc with Gradient
    final activeAngle = sweepAngle * progress;
    if (activeAngle > 0.005) {
      final activePaint = Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: [
            const Color(0xFF10B981),
            color,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      // Glow effect
      final glowPaint = Paint()
        ..color = color.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        activeAngle,
        false,
        glowPaint,
      );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        activeAngle,
        false,
        activePaint,
      );

      // Needle Bead at Arc End
      final currentEndAngle = startAngle + activeAngle;
      final needleX = center.dx + radius * math.cos(currentEndAngle);
      final needleY = center.dy + radius * math.sin(currentEndAngle);

      final beadOuterPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final beadInnerPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(needleX, needleY), 7, beadOuterPaint);
      canvas.drawCircle(Offset(needleX, needleY), 4.5, beadInnerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark;
  }
}
