import 'dart:math' as math;
import 'package:flutter/material.dart';

/// PlatelySplashScreen — Unified circular launch loading screen with
/// iconic orangish loading animation around the Plate logo.
/// Once loading completes, plays a sleek disappearance animation and reveals the next screen.
class PlatelySplashScreen extends StatefulWidget {
  final Future<void> loadingFuture;
  final VoidCallback onFinish;

  const PlatelySplashScreen({
    super.key,
    required this.loadingFuture,
    required this.onFinish,
  });

  @override
  State<PlatelySplashScreen> createState() => _PlatelySplashScreenState();
}

class _PlatelySplashScreenState extends State<PlatelySplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _pulseController;
  late AnimationController _exitController;

  late Animation<double> _exitOpacity;
  late Animation<double> _exitScaleLogo;
  late Animation<double> _exitScaleRing;

  @override
  void initState() {
    super.initState();

    // 1. Spinning orange ring animation (continuous until exit)
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    // 2. Pulsing glow animation around the circle
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // 3. Exit disappearance animation
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.1, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _exitScaleLogo = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    _exitScaleRing = Tween<double>(begin: 1.0, end: 1.45).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutQuart),
      ),
    );

    _startLoadingAndTransition();
  }

  Future<void> _startLoadingAndTransition() async {
    // Ensure the user gets to enjoy the glowing orangish loading ring for at least 1.8 seconds
    // alongside whatever background initialization checks are occurring.
    await Future.wait([
      widget.loadingFuture,
      Future.delayed(const Duration(milliseconds: 1800)),
    ]);

    if (!mounted) return;

    await _exitController.forward();

    if (mounted) {
      widget.onFinish();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFF6B00);
    const accentOrange = Color(0xFFFF8533);
    const bgColor = Color(0xFF0D1117);

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _exitController,
          builder: (context, child) {
            final opacity = _exitOpacity.value;
            final scaleLogo = _exitScaleLogo.value;
            final scaleRing = _exitScaleRing.value;

            return Opacity(
              opacity: opacity,
              child: SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. Pulsing orangish background glow
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        final pulseScale = 0.9 + (_pulseController.value * 0.2);
                        final pulseAlpha = 0.12 + (_pulseController.value * 0.15);
                        return Transform.scale(
                          scale: pulseScale * scaleRing,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  primaryOrange.withValues(alpha: pulseAlpha),
                                  primaryOrange.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // 2. Spinning orangish loading ring around the circular logo
                    Transform.scale(
                      scale: scaleRing,
                      child: AnimatedBuilder(
                        animation: _spinController,
                        builder: (context, _) {
                          return Transform.rotate(
                            angle: _spinController.value * 2 * math.pi,
                            child: CustomPaint(
                              size: const Size(160, 160),
                              painter: _OrangishRingPainter(
                                primaryColor: primaryOrange,
                                accentColor: accentOrange,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // 3. Central round iconic Plate logo (no borders)
                    Transform.scale(
                      scale: scaleLogo,
                      child: Container(
                        width: 116,
                        height: 116,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/icon/splash_icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: Colors.white,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.restaurant,
                                color: primaryOrange,
                                size: 50,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Custom painter that draws the sleek glowing orangish loading arc/ring around the center plate.
class _OrangishRingPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  _OrangishRingPainter({
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;

    // Subtle background track arc
    final trackPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(center, radius, trackPaint);

    // Glowing active orange arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: 0.0,
      endAngle: math.pi * 1.5,
      colors: [
        primaryColor.withValues(alpha: 0.0),
        primaryColor.withValues(alpha: 0.7),
        accentColor,
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final arcPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0.0, math.pi * 1.5, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _OrangishRingPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.accentColor != accentColor;
}
