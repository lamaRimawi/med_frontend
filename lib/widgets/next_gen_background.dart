import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

class NextGenBackground extends StatelessWidget {
  final Widget child;
  final bool isDarkMode;

  const NextGenBackground({
    super.key,
    required this.child,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkMode 
      ? const Color(0xFF0F172A) 
      : const Color(0xFFF8FAFC);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: bgColor,
      child: Stack(
        children: [
          // Animated Blobs
          Positioned(
            top: -100,
            right: -100,
            child: _buildAnimatedBlob(
              size: 600,
              color: const Color(0xFF2193b0).withOpacity(0.2),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: _buildAnimatedBlob(
              size: 700,
              color: const Color(0xFF6dd5ed).withOpacity(0.15),
            ),
          ),
          Positioned(
            top: 200,
            left: 200,
            child: _buildAnimatedBlob(
              size: 400,
              color: const Color(0xFF39A4E6).withOpacity(0.1),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .moveY(begin: 0, end: 50, duration: 5.seconds, curve: Curves.easeInOut),
          ),

          // Backdrop Blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Main Content
          child,
        ],
      ),
    );
  }

  Widget _buildAnimatedBlob({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 50,
          ),
        ],
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
     .scale(
       begin: const Offset(1, 1),
       end: const Offset(1.1, 1.1),
       duration: 4.seconds,
       curve: Curves.easeInOut,
     );
  }
}
