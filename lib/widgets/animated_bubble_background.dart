import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

import 'package:lucide_icons/lucide_icons.dart';

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

        // 1. Small Floating Bubbles (Reduced to 15 for cleaner look)
        ...List.generate(15, (i) => _buildFloatingBubble(context, i)),

        // 2. Tiny Sparkle Bubbles (Reduced to 10)
        ...List.generate(10, (i) => _buildSparkleBubble(context, i)),

        // 3. Ambient Bubbles (Reduced to 8)
        ...List.generate(8, (i) => _buildAmbientBubble(context, i)),

        // 4. Floating Medical Icons (New Layer)
        ...List.generate(12, (i) => _buildMedicalIcon(context, i)),
      ],
    );
  }

  Widget _buildFloatingBubble(BuildContext context, int i) {
    final size = 10.0 + (i % 5) * 5;
    final left = (i * 100 / 15) + ((i % 3) * 2); 
    // Fix: Start at random vertical positions across the screen, not just at the bottom
    final top = (i * 123) % 100.0; 

    final duration = (15 + (i % 5) * 2).seconds;
    final delay = (i * 0.2).seconds; // Reduced delay for faster initial appearance

    return Positioned(
      left: MediaQuery.of(context).size.width * (left / 100),
      top: MediaQuery.of(context).size.height * (top / 100),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF39A4E6).withOpacity(0.3), // Increased opacity
            width: 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF39A4E6).withOpacity(0.1), // Increased opacity
              const Color(0xFF39A4E6).withOpacity(0.02),
            ],
          ),
        ),
      )
      .animate(onPlay: (c) => c.repeat())
      .moveY(
        begin: 0, 
        end: -200, // Move up a reasonable amount then reset
        duration: duration, 
        delay: delay, 
        curve: Curves.easeInOutSine,
      )
      .moveX(
        begin: 0, 
        end: (i % 2 == 0 ? 30.0 : -30.0), 
        duration: duration * 0.5, 
        delay: delay, 
        curve: Curves.easeInOutSine,
      )
      .then()
      .moveX(
        begin: 0, 
        end: (i % 2 == 0 ? -30.0 : 30.0), 
        duration: duration * 0.5, 
        curve: Curves.easeInOutSine,
      )
      // Fade in/out to mask the reset
      .fadeIn(duration: 2.seconds, delay: delay)
      .fadeOut(duration: 2.seconds, delay: delay + duration - 2.seconds),
    );
  }

  Widget _buildSparkleBubble(BuildContext context, int i) {
    const size = 4.0; // Slightly larger
    final left = (i * 100 / 10) + ((i % 4) * 5);
    final top = (i * 97) % 100.0; // Random vertical

    final duration = (4 + (i % 3)).seconds;
    final delay = (i * 0.3).seconds;

    return Positioned(
      left: MediaQuery.of(context).size.width * (left / 100),
      top: MediaQuery.of(context).size.height * (top / 100),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF39A4E6).withOpacity(0.4), // Higher opacity for visibility
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF39A4E6).withOpacity(0.4),
              blurRadius: 6,
            ),
          ],
        ),
      )
      .animate(onPlay: (c) => c.repeat(reverse: true))
      .scale(
        begin: const Offset(0.5, 0.5), 
        end: const Offset(1.5, 1.5), 
        duration: duration, 
        delay: delay,
        curve: Curves.easeInOutSine,
      )
      .fade(
        begin: 0.2, 
        end: 0.6, 
        duration: duration, 
        delay: delay,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  Widget _buildAmbientBubble(BuildContext context, int i) {
    final size = 40.0 + (i % 3) * 20;
    final left = (i * 100 / 8);
    final top = (i * 67) % 100.0; // Random vertical

    final duration = (12 + (i % 3) * 5).seconds;
    final delay = (i * 0.5).seconds;

    return Positioned(
      left: MediaQuery.of(context).size.width * (left / 100),
      top: MediaQuery.of(context).size.height * (top / 100),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF39A4E6).withOpacity(0.03), // Subtle but visible
        ),
      )
      .animate(onPlay: (c) => c.repeat(reverse: true))
      .scale(
        begin: const Offset(1, 1), 
        end: const Offset(1.15, 1.15), 
        duration: duration, 
        delay: delay,
        curve: Curves.easeInOutSine,
      )
      .moveY(
        begin: 0,
        end: -30,
        duration: duration,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  Widget _buildMedicalIcon(BuildContext context, int i) {
    final icons = [
      LucideIcons.stethoscope,
      LucideIcons.heartPulse,
      LucideIcons.pill,
      LucideIcons.activity,
      LucideIcons.plus,
      LucideIcons.thermometer,
    ];

    final icon = icons[i % icons.length];
    final size = 18.0 + (i % 3) * 6; // 18, 24, 30
    
    final left = (i * 100 / 12) + ((i * 7) % 10); 
    // Fix: Start distributed across screen
    final top = (i * 43) % 90.0 + 10; 

    final duration = (15 + (i % 5) * 3).seconds;
    final delay = (i * 0.5).seconds;

    return Positioned(
      left: MediaQuery.of(context).size.width * (left / 100),
      top: MediaQuery.of(context).size.height * (top / 100),
      child: Icon(
        icon,
        size: size,
        color: const Color(0xFF39A4E6).withOpacity(0.15), // Increased opacity for visibility
      )
      .animate(onPlay: (c) => c.repeat())
      .moveY(
        begin: 0, 
        end: -100, // Gentle float up
        duration: duration, 
        delay: delay, 
        curve: Curves.easeInOutSine,
      )
      .rotate(
        begin: 0, 
        end: (i % 2 == 0 ? 0.15 : -0.15), 
        duration: duration, 
        curve: Curves.easeInOutSine,
      )
      .fade(
        begin: 0,
        end: 1,
        duration: 3.seconds,
      )
      .then()
      .fade(
        begin: 1,
        end: 0,
        duration: 3.seconds,
        delay: duration - 6.seconds,
      ),
    );
  }
}
