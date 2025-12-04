import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _heartbeatController;

  @override
  void initState() {
    super.initState();
    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Check for login status
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Wait for animation minimum duration
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (mounted) {
      if (token != null && token.isNotEmpty) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    }
  }

  @override
  void dispose() {
    _heartbeatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF39A4E6),
              Color(0xFF2B8FD9),
              Color(0xFF1B7AC9),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background Elements
            ..._buildBackgroundElements(),

            // Main Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Container
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer Glow Ring
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF39A4E6).withValues(alpha: 0.0),
                                const Color(0xFF39A4E6).withValues(alpha: 0.25),
                              ],
                            ),
                          ),
                        )
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.15, 1.15),
                              duration: const Duration(seconds: 2),
                            ),

                        // Rotating Dashed Ring
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: CustomPaint(
                            painter: DashedRingPainter(),
                          ),
                        )
                            .animate(onPlay: (controller) => controller.repeat())
                            .rotate(duration: const Duration(seconds: 6)),

                        // White Circle Background with Shadow
                        Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            gradient: const RadialGradient(
                              colors: [
                                Colors.white,
                                Color(0xFFFAFAFA),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF39A4E6).withValues(alpha: 0.4),
                                blurRadius: 45,
                                spreadRadius: 8,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .scale(
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.elasticOut,
                            )
                            .shimmer(
                              duration: const Duration(seconds: 2),
                              delay: const Duration(milliseconds: 900),
                            ),

                        // Pulse Rings
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF39A4E6).withValues(alpha: 0.4),
                              width: 3,
                            ),
                          ),
                        )
                            .animate(onPlay: (controller) => controller.repeat())
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.6, 1.6),
                              duration: const Duration(milliseconds: 2000),
                            )
                            .fadeOut(duration: const Duration(milliseconds: 2000)),

                        // Logo Image with Modern Effects
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF39A4E6).withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo_2.png',
                              width: 140,
                              height: 140,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: const Duration(milliseconds: 500))
                            .scale(
                              begin: const Offset(0.6, 0.6),
                              end: const Offset(1, 1),
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.elasticOut,
                            ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Animated Heartbeat Line - Below Logo
                  Container(
                    width: 160,
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.25),
                          Colors.white.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF39A4E6).withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      painter: HeartbeatWavePainter(
                        animation: _heartbeatController,
                        color: Colors.white,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: const Duration(milliseconds: 1200))
                      .slideY(
                        begin: 0.3,
                        end: 0,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                      ),

                  const SizedBox(height: 32),

                  // App Name
                  const Text(
                    'MediScan',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  )
                      .animate(delay: const Duration(milliseconds: 1400))
                      .fadeIn(duration: const Duration(milliseconds: 800))
                      .moveY(begin: 20, end: 0, duration: const Duration(milliseconds: 800)),

                  const SizedBox(height: 8),

                  // Tagline
                  Text(
                    'Your Medical Records, Simplified',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 1.1,
                    ),
                  )
                      .animate(delay: const Duration(milliseconds: 1800))
                      .fadeIn(duration: const Duration(milliseconds: 600)),

                  const SizedBox(height: 64),

                  // Loading Indicator
                  _buildLoadingIndicator()
                      .animate(delay: const Duration(milliseconds: 2200))
                      .fadeIn(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBackgroundElements() {
    return [
      // DNA Helix Top Right
      Positioned(
        top: 40,
        right: 40,
        child: Opacity(
          opacity: 0.1,
          child: const Icon(LucideIcons.dna, size: 60, color: Colors.white)
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: const Duration(seconds: 20))
              .moveY(begin: 0, end: 10, duration: const Duration(seconds: 3), curve: Curves.easeInOut)
              .then()
              .moveY(begin: 10, end: 0, duration: const Duration(seconds: 3), curve: Curves.easeInOut),
        ),
      ),

      // DNA Helix Bottom Left
      Positioned(
        bottom: 40,
        left: 40,
        child: Opacity(
          opacity: 0.1,
          child: const Icon(LucideIcons.dna, size: 60, color: Colors.white)
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(begin: 0, end: -1, duration: const Duration(seconds: 20))
              .moveY(begin: 0, end: -10, duration: const Duration(seconds: 3), curve: Curves.easeInOut)
              .then()
              .moveY(begin: -10, end: 0, duration: const Duration(seconds: 3), curve: Curves.easeInOut),
        ),
      ),

      // Floating Bubbles
      ...List.generate(8, (index) {
        final random = math.Random(index + 100);
        final size = 40.0 + random.nextDouble() * 80;
        return Positioned(
          left: random.nextDouble() * 400,
          top: random.nextDouble() * 800,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
                delay: Duration(milliseconds: (random.nextDouble() * 2000).toInt()),
              )
              .moveY(
                begin: 0,
                end: -50 - random.nextDouble() * 50,
                duration: Duration(milliseconds: 3000 + (random.nextDouble() * 2000).toInt()),
                curve: Curves.easeInOut,
              )
              .fadeIn(duration: Duration(milliseconds: 1000 + (random.nextDouble() * 1000).toInt()))
              .then()
              .fadeOut(duration: Duration(milliseconds: 1000 + (random.nextDouble() * 1000).toInt())),
        );
      }),

      // Floating Icons
      Positioned(
        top: 80,
        left: '10%'.toPercent(300),
        child: _buildFloatingIcon(LucideIcons.stethoscope, 48, 0),
      ),
      Positioned(
        top: '15%'.toPercent(600),
        right: '15%'.toPercent(300),
        child: _buildFloatingIcon(LucideIcons.activity, 64, 500),
      ),
      Positioned(
        bottom: '20%'.toPercent(600),
        left: '20%'.toPercent(300),
        child: _buildFloatingIcon(LucideIcons.pill, 40, 1000),
      ),
      Positioned(
        bottom: '25%'.toPercent(600),
        right: '12%'.toPercent(300),
        child: _buildFloatingIcon(LucideIcons.cross, 56, 1500),
      ),

      // Particles
      ...List.generate(15, (index) {
        final random = math.Random(index);
        return Positioned(
          left: random.nextDouble() * 400,
          top: random.nextDouble() * 800,
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(),
                delay: Duration(milliseconds: (random.nextDouble() * 3000).toInt()),
              )
              .moveY(begin: 0, end: -200, duration: Duration(milliseconds: (random.nextDouble() * 3000 + 2000).toInt()))
              .fadeOut(duration: Duration(milliseconds: (random.nextDouble() * 3000 + 2000).toInt()))
              .scale(begin: const Offset(0, 0), end: const Offset(1, 1)),
        );
      }),
    ];
  }

  Widget _buildFloatingIcon(IconData icon, double size, int delayMs) {
    return Opacity(
      opacity: 0.2,
      child: Icon(icon, size: size, color: Colors.white)
          .animate(
            onPlay: (controller) => controller.repeat(reverse: true),
            delay: Duration(milliseconds: delayMs),
          )
          .moveY(begin: 0, end: -20, duration: const Duration(seconds: 4), curve: Curves.easeInOut)
          .rotate(begin: -0.05, end: 0.05, duration: const Duration(seconds: 5)),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSequentialDot(0),
          const SizedBox(width: 20),
          _buildSequentialDot(1),
          const SizedBox(width: 20),
          _buildSequentialDot(2),
        ],
      ),
    );
  }

  Widget _buildSequentialDot(int index) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          colors: [
            Colors.white,
            Color(0xFFE8E8E8),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.7),
            blurRadius: 15,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: const Color(0xFF39A4E6).withValues(alpha: 0.4),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(),
          delay: Duration(milliseconds: index * 400),
        )
        .fadeIn(duration: const Duration(milliseconds: 600))
        .scaleXY(
          begin: 0.5,
          end: 1.2,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
        )
        .then()
        .scaleXY(
          begin: 1.2,
          end: 1.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeIn,
        )
        .then(delay: Duration(milliseconds: 300 * (2 - index)))
        .fadeOut(duration: const Duration(milliseconds: 600));
  }
}

class DashedRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    const dashWidth = 10.0;
    const dashSpace = 10.0;
    double startAngle = 0;

    while (startAngle < 2 * math.pi) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashWidth / radius,
        false,
        paint,
      );
      startAngle += (dashWidth + dashSpace) / radius;
    }
    
    // Draw dots
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(center + Offset(0, -radius), 5, dotPaint);
    canvas.drawCircle(center + Offset(0, radius), 5, dotPaint);
    canvas.drawCircle(center + Offset(radius, 0), 5, dotPaint);
    canvas.drawCircle(center + Offset(-radius, 0), 5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Animated Heartbeat Wave Painter
class HeartbeatWavePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  HeartbeatWavePainter({
    required this.animation,
    required this.color,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final centerY = size.height / 2;
    final waveWidth = size.width * 1.5;
    final offset = animation.value * waveWidth;

    // Create ECG-style heartbeat wave
    for (double x = -waveWidth; x < size.width + waveWidth; x += 1) {
      final adjustedX = x - offset;
      double y = centerY;

      // Create heartbeat pattern
      final normalizedX = (adjustedX % 200) / 200;
      
      if (normalizedX < 0.1) {
        // Flat line
        y = centerY;
      } else if (normalizedX < 0.15) {
        // Small dip
        y = centerY + 8;
      } else if (normalizedX < 0.25) {
        // Sharp spike up
        y = centerY - 25 * math.sin((normalizedX - 0.15) * math.pi / 0.1);
      } else if (normalizedX < 0.35) {
        // Sharp spike down
        y = centerY + 15 * math.sin((normalizedX - 0.25) * math.pi / 0.1);
      } else if (normalizedX < 0.45) {
        // Return to baseline
        y = centerY - 8 * math.sin((normalizedX - 0.35) * math.pi / 0.1);
      } else {
        // Flat line
        y = centerY;
      }

      if (x == -waveWidth) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Add glow effect
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(HeartbeatWavePainter oldDelegate) => true;
}

// Heart Shape Clipper
class HeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;
    
    // Create a heart shape path
    path.moveTo(width / 2, height * 0.35);
    
    // Left curve
    path.cubicTo(
      width * 0.2, height * 0.1,
      -width * 0.25, height * 0.6,
      width / 2, height,
    );
    
    // Right curve
    path.moveTo(width / 2, height * 0.35);
    path.cubicTo(
      width * 0.8, height * 0.1,
      width * 1.25, height * 0.6,
      width / 2, height,
    );
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

extension StringExtension on String {
  double toPercent(double total) {
    // Simple helper to parse "10%" to pixels
    if (endsWith('%')) {
      final percentage = double.tryParse(replaceAll('%', '')) ?? 0;
      return total * (percentage / 100);
    }
    return 0;
  }
}
