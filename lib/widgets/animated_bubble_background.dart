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
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
        ),

        // 1. Small floating bubbles (40)
        ...List.generate(40, (i) => _buildSmallBubble(context, i)),

        // 2. Tiny sparkle bubbles (25)
        ...List.generate(25, (i) => _buildSparkleBubble(context, i)),

        // 3. Additional ambient bubbles (20)
        ...List.generate(20, (i) => _buildAmbientBubble(context, i)),
      ],
    );
  }

  Widget _buildSmallBubble(BuildContext context, int i) {
    final size = 12.0 + (i % 6) * 6;
    final left = (i * 5) % 100.0;
    final top = (i * 13) % 100.0;
    final duration = 8.0 + (i % 4) * 2.0; // Slower duration
    final delay = i * 0.2;

    final moveY = -120.0 - (i % 4) * 60;
    final moveX = ((i % 2 == 0 ? 20.0 : -20.0) + (i % 3) * 10);

    return Positioned(
      left: MediaQuery.of(context).size.width * (left / 100),
      top: MediaQuery.of(context).size.height * (top / 100),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF39A4E6).withOpacity(0.25),
            width: 2,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF39A4E6).withOpacity(0.15), // Slightly more visible
              const Color(0xFF39A4E6).withOpacity(0.08),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF39A4E6).withOpacity(0.1),
              blurRadius: 10,
            ),
          ],
        ),
      )
      .animate(
        onPlay: (controller) => controller.repeat(),
      )
      .moveY(
        begin: 0,
        end: moveY,
        duration: duration.seconds,
        delay: delay.seconds,
        curve: Curves.easeInOut,
      )
      .moveX(
        begin: 0,
        end: moveX,
        duration: duration.seconds,
        delay: delay.seconds,
        curve: Curves.easeInOut,
      )
      .fade(
        begin: 0,
        end: 0.7,
        duration: (duration * 0.5).seconds,
        delay: delay.seconds,
      )
      .fadeOut(
        begin: 0.7,
        duration: (duration * 0.5).seconds,
        delay: (delay + duration * 0.5).seconds,
      )
      .scale(
        begin: const Offset(0.7, 0.7),
        end: const Offset(1.2, 1.2),
        duration: duration.seconds,
        delay: delay.seconds,
      ),
    );
  }

  Widget _buildSparkleBubble(BuildContext context, int i) {
    const size = 5.0;
    final left = (i * 10 + 3) % 97.0;
    final top = (i * 17) % 100.0;
    final duration = 6.0 + (i % 3) * 1.5; // Slower sparkles
    final delay = i * 0.25;

    final moveY = -180.0 - (i % 5) * 40;
    final moveX = (i % 2 == 0 ? 15.0 : -15.0);

    return Positioned(
      left: MediaQuery.of(context).size.width * (left / 100),
      top: MediaQuery.of(context).size.height * (top / 100),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF39A4E6).withOpacity(0.4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF39A4E6).withOpacity(0.4),
              blurRadius: 8,
            ),
          ],
        ),
      )
      .animate(
        onPlay: (controller) => controller.repeat(),
      )
      .moveY(
        begin: 0,
        end: moveY,
        duration: duration.seconds,
        delay: delay.seconds,
        curve: Curves.easeOut,
      )
      .moveX(
        begin: 0,
        end: moveX,
        duration: duration.seconds,
        delay: delay.seconds,
        curve: Curves.easeOut,
      )
      .fade(
        begin: 0,
        end: 1,
        duration: (duration * 0.5).seconds,
        delay: delay.seconds,
      )
      .fadeOut(
        begin: 1,
        duration: (duration * 0.5).seconds,
        delay: (delay + duration * 0.5).seconds,
      )
      .scale(
        begin: const Offset(0, 0),
        end: const Offset(1.2, 1.2),
        duration: (duration * 0.5).seconds,
        delay: delay.seconds,
      )
      .scale(
        begin: const Offset(1.2, 1.2),
        end: const Offset(0, 0),
        duration: (duration * 0.5).seconds,
        delay: (delay + duration * 0.5).seconds,
      ),
    );
  }

  Widget _buildAmbientBubble(BuildContext context, int i) {
    final size = 8.0 + (i % 4) * 5;
    final left = (i * 11) % 100.0;
    final top = (i * 19) % 100.0;
    final duration = 7.0 + (i % 3) * 2;
    final delay = i * 0.25;

    final moveY = (i % 2 == 0 ? -80.0 : 80.0);
    final moveX = (i % 3 == 0 ? 60.0 : -60.0);

    return Positioned(
      left: MediaQuery.of(context).size.width * (left / 100),
      top: MediaQuery.of(context).size.height * (top / 100),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF39A4E6).withOpacity(0.15),
            width: 1,
          ),
          color: const Color(0xFF39A4E6).withOpacity(0.05),
        ),
      )
      .animate(
        onPlay: (controller) => controller.repeat(reverse: true),
      )
      .moveY(
        begin: 0,
        end: moveY,
        duration: duration.seconds,
        delay: delay.seconds,
        curve: Curves.easeInOut,
      )
      .moveX(
        begin: 0,
        end: moveX,
        duration: duration.seconds,
        delay: delay.seconds,
        curve: Curves.easeInOut,
      )
      .fade(
        begin: 0,
        end: 0.5,
        duration: (duration * 0.5).seconds,
        delay: delay.seconds,
      )
      .scale(
        begin: const Offset(0.8, 0.8),
        end: const Offset(1.1, 1.1),
        duration: duration.seconds,
        delay: delay.seconds,
      ),
    );
  }
}
