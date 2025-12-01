import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class AnimatedBubbleBackground extends StatelessWidget {
  final bool isDark;

  const AnimatedBubbleBackground({super.key, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base background
        Container(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        ),

        // 1. Smooth Gradient Waves (Large radial gradients)
        _buildGradientWave(context, 
          alignment: const Alignment(-1.2, -1.2), 
          colors: [const Color(0xFF39A4E6), const Color(0xFF2B8FD9)],
          delay: 0,
        ),
        _buildGradientWave(context, 
          alignment: const Alignment(1.2, 1.2), 
          colors: [const Color(0xFF5BB5ED), const Color(0xFF39A4E6)],
          delay: 2,
        ),
        _buildGradientWave(context, 
          alignment: const Alignment(0, 0), 
          colors: [const Color(0xFF39A4E6), Colors.transparent],
          delay: 4,
          scale: 0.8,
          opacity: 0.02,
        ),

        // 2. Floating Particles (Bubbles)
        ...List.generate(15, (i) => _buildFloatingParticle(context, i)),

        // 3. Smooth Wave Lines
        ...List.generate(3, (i) => _buildWaveLine(context, i)),

        // 4. Pulsing Rings
        ...List.generate(4, (i) => _buildPulsingRing(context, i)),

        // 5. Medical Cross Icons
        ...List.generate(5, (i) => _buildCrossIcon(context, i)),

        // 6. Heartbeat Line
        _buildHeartbeatLine(context),
      ],
    );
  }

  Widget _buildGradientWave(BuildContext context, {
    required Alignment alignment, 
    required List<Color> colors,
    required double delay,
    double scale = 1.0,
    double opacity = 0.03,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 400 * scale,
        height: 400 * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [...colors, Colors.transparent],
            stops: const [0.0, 0.5, 0.7],
          ),
        ),
      )
      .animate(onPlay: (c) => c.repeat(reverse: true))
      .scale(
        begin: const Offset(1, 1), 
        end: const Offset(1.2, 1.2), 
        duration: 10.seconds,
        curve: Curves.easeInOut,
      )
      .rotate(
        begin: 0, 
        end: 0.1, 
        duration: 15.seconds,
        curve: Curves.easeInOut,
      )
      .fade(begin: opacity, end: opacity * 1.5, duration: 8.seconds),
    );
  }

  Widget _buildFloatingParticle(BuildContext context, int i) {
    final size = 4.0 + (i % 4);
    final left = 5.0 + (i * 6.5) % 90;
    final top = 10.0 + (i * 5) % 70;
    final color = i % 3 == 0 
        ? const Color(0xFF39A4E6).withOpacity(0.3)
        : i % 3 == 1 
        ? const Color(0xFF5BB5ED).withOpacity(0.25)
        : const Color(0xFF2B8FD9).withOpacity(0.2);

    return Positioned(
      left: MediaQuery.of(context).size.width * (left / 100),
      top: MediaQuery.of(context).size.height * (top / 100),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      )
      .animate(onPlay: (c) => c.repeat())
      .moveY(
        begin: 0, 
        end: -150, 
        duration: (12 + i * 2).seconds,
        delay: (i * 0.6).seconds,
        curve: Curves.easeInOut,
      )
      .moveX(
        begin: 0, 
        end: math.sin(i) * 80, 
        duration: (12 + i * 2).seconds,
        delay: (i * 0.6).seconds,
        curve: Curves.easeInOut,
      )
      .fade(
        begin: 0, 
        end: 0.4, 
        duration: (6 + i).seconds,
      )
      .fadeOut(
        delay: (6 + i).seconds,
        duration: (6 + i).seconds,
      )
      .scale(
        begin: const Offset(0.5, 0.5), 
        end: const Offset(1, 1), 
        duration: (6 + i).seconds,
      ),
    );
  }

  Widget _buildWaveLine(BuildContext context, int i) {
    return Positioned(
      top: MediaQuery.of(context).size.height * (0.3 + i * 0.2),
      left: 0,
      right: 0,
      height: 1,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFF39A4E6).withOpacity(0.1),
              Colors.transparent,
            ],
          ),
        ),
      )
      .animate(onPlay: (c) => c.repeat())
      .moveX(
        begin: -200, 
        end: 200, 
        duration: (15 + i * 3).seconds,
        delay: (i * 2).seconds,
      )
      .fade(
        begin: 0, 
        end: 0.1, 
        duration: (7 + i).seconds,
      )
      .fadeOut(
        delay: (7 + i).seconds,
        duration: (7 + i).seconds,
      ),
    );
  }

  Widget _buildPulsingRing(BuildContext context, int i) {
    final left = 20.0 + (i * 20) % 80;
    final top = 15.0 + (i * 20) % 60;
    
    return Positioned(
      left: MediaQuery.of(context).size.width * (left / 100),
      top: MediaQuery.of(context).size.height * (top / 100),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF39A4E6).withOpacity(0.1)),
        ),
      )
      .animate(onPlay: (c) => c.repeat())
      .scale(
        begin: const Offset(1, 1), 
        end: const Offset(2.5, 2.5), 
        duration: (8 + i * 2).seconds,
        delay: (i * 2).seconds,
        curve: Curves.easeOut,
      )
      .fade(
        begin: 0.08, 
        end: 0, 
        duration: (8 + i * 2).seconds,
        delay: (i * 2).seconds,
        curve: Curves.easeOut,
      ),
    );
  }

  Widget _buildCrossIcon(BuildContext context, int i) {
    final left = 15.0 + (i * 18) % 85;
    
    return Positioned(
      left: MediaQuery.of(context).size.width * (left / 100),
      bottom: 0,
      child: SizedBox(
        width: 20,
        height: 20,
        child: Stack(
          children: [
            Center(child: Container(width: 2, height: 20, color: const Color(0xFF39A4E6).withOpacity(0.2))),
            Center(child: Container(width: 20, height: 2, color: const Color(0xFF39A4E6).withOpacity(0.2))),
          ],
        ),
      )
      .animate(onPlay: (c) => c.repeat())
      .moveY(
        begin: 100, 
        end: -100, 
        duration: (15 + i * 2).seconds,
        delay: (i * 3).seconds,
      )
      .rotate(
        begin: 0, 
        end: 0.5, 
        duration: (15 + i * 2).seconds,
      )
      .fade(
        begin: 0, 
        end: 0.15, 
        duration: 5.seconds,
      )
      .fadeOut(
        delay: 10.seconds,
        duration: 5.seconds,
      ),
    );
  }

  Widget _buildHeartbeatLine(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.5,
      left: 0,
      right: 0,
      height: 40,
      child: CustomPaint(
        painter: HeartbeatPainter(color: const Color(0xFF39A4E6).withOpacity(0.3)),
      )
      .animate(onPlay: (c) => c.repeat())
      .moveX(
        begin: -300, 
        end: 300, 
        duration: 10.seconds,
      )
      .fade(
        begin: 0, 
        end: 0.15, 
        duration: 2.seconds,
      )
      .fadeOut(
        delay: 8.seconds,
        duration: 2.seconds,
      ),
    );
  }
}

class HeartbeatPainter extends CustomPainter {
  final Color color;

  HeartbeatPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height / 2);
    path.lineTo(size.width * 0.2, size.height / 2);
    path.lineTo(size.width * 0.225, size.height * 0.25);
    path.lineTo(size.width * 0.25, size.height * 0.75);
    path.lineTo(size.width * 0.275, size.height / 2);
    path.lineTo(size.width, size.height / 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
