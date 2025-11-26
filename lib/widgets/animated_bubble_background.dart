import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'dart:math' as math;

class AnimatedBubbleBackground extends StatelessWidget {
  final bool isDark;
  
  const AnimatedBubbleBackground({super.key, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient - Clean medical theme
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFF8FAFC), const Color(0xFFFFFFFF)],
            ),
          ),
        ),

        // Soft circular gradients - Medical blue/teal theme
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF0EA5E9).withOpacity(0.08),
                  const Color(0xFF0EA5E9).withOpacity(0.02),
                  Colors.transparent,
                ],
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scale(duration: 40.seconds, begin: const Offset(1, 1), end: const Offset(1.1, 1.1), curve: Curves.easeInOutSine),
        ),

        Positioned(
          bottom: -60,
          left: -60,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF06B6D4).withOpacity(0.06),
                  const Color(0xFF06B6D4).withOpacity(0.02),
                  Colors.transparent,
                ],
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scale(duration: 45.seconds, begin: const Offset(1, 1), end: const Offset(1.12, 1.12), curve: Curves.easeInOutSine),
        ),

        Positioned(
          top: 180,
          left: -40,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF14B8A6).withOpacity(0.05),
                  const Color(0xFF14B8A6).withOpacity(0.01),
                  Colors.transparent,
                ],
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scale(duration: 38.seconds, begin: const Offset(1, 1), end: const Offset(1.08, 1.08), curve: Curves.easeInOutSine),
        ),

        // Subtle accent shape
        Positioned(
          bottom: 120,
          right: 40,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF3B82F6).withOpacity(0.04),
                  const Color(0xFF3B82F6).withOpacity(0.01),
                  Colors.transparent,
                ],
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scale(duration: 42.seconds, begin: const Offset(1, 1), end: const Offset(1.1, 1.1), curve: Curves.easeInOutSine)
           .moveY(duration: 35.seconds, begin: 0, end: -10, curve: Curves.easeInOutSine),
        ),

        // Minimal shimmer particles
        ...List.generate(6, (index) {
          return Positioned(
            left: (index * 70.0 + 30) % MediaQuery.of(context).size.width,
            top: (index * 100.0 + 50) % MediaQuery.of(context).size.height,
            child: Container(
              width: 2,
              height: 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark 
                  ? Colors.white.withOpacity(0.25)
                  : const Color(0xFF0EA5E9).withOpacity(0.4),
                boxShadow: [
                  BoxShadow(
                    color: isDark 
                      ? Colors.white.withOpacity(0.15)
                      : const Color(0xFF0EA5E9).withOpacity(0.25),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ).animate(onPlay: (controller) => controller.repeat())
             .fadeIn(duration: 3.seconds, delay: (index * 0.5).seconds)
             .fadeOut(duration: 3.seconds, delay: (3 + index * 0.5).seconds),
          );
        }),
      ],
    );
  }
}
