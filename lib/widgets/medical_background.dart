import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MedicalBackground extends StatelessWidget {
  final bool showBlurCircles;

  const MedicalBackground({super.key, this.showBlurCircles = true});

  static const List<_MedicalIconData> _icons = [
    _MedicalIconData(icon: LucideIcons.stethoscope, delay: 0, duration: 20, x: 20, y: 10),
    _MedicalIconData(icon: LucideIcons.syringe, delay: 2, duration: 25, x: 70, y: 20),
    _MedicalIconData(icon: LucideIcons.pill, delay: 4, duration: 22, x: 85, y: 60),
    _MedicalIconData(icon: LucideIcons.heart, delay: 1, duration: 28, x: 10, y: 70),
    _MedicalIconData(icon: LucideIcons.activity, delay: 3, duration: 24, x: 90, y: 85),
    _MedicalIconData(icon: LucideIcons.thermometer, delay: 5, duration: 26, x: 15, y: 40),
    _MedicalIconData(icon: LucideIcons.clipboard, delay: 1.5, duration: 23, x: 50, y: 80),
    _MedicalIconData(icon: LucideIcons.testTube, delay: 3.5, duration: 27, x: 65, y: 30),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: [
            ..._icons.map((icon) => _AnimatedMedicalIcon(data: icon, parentSize: size)).toList(),
            if (showBlurCircles) ...[
              _BlurCircle(
                left: 20,
                top: 25,
                size: 160,
                color: const Color(0xFF39A4E6).withOpacity(0.25),
                horizontalShift: 80,
                verticalShift: -60,
              ),
              _BlurCircle(
                right: 20,
                bottom: 120,
                size: 190,
                color: const Color(0xFF39A4E6).withOpacity(0.22),
                horizontalShift: -90,
                verticalShift: 80,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnimatedMedicalIcon extends StatelessWidget {
  final _MedicalIconData data;
  final Size parentSize;

  const _AnimatedMedicalIcon({required this.data, required this.parentSize});

  @override
  Widget build(BuildContext context) {
    final left = parentSize.width * (data.x / 100);
    final top = parentSize.height * (data.y / 100);

    return Positioned(
      left: left,
      top: top,
      child: Animate(
        delay: Duration(milliseconds: (data.delay * 1000).round()),
        onPlay: (controller) => controller.repeat(reverse: true),
        effects: [
          MoveEffect(
            begin: Offset.zero,
            end: const Offset(0, -40),
            duration: Duration(seconds: data.duration),
            curve: Curves.easeInOut,
          ),
          RotateEffect(
            begin: 0,
            end: 2 * math.pi,
            duration: Duration(seconds: data.duration + 5),
            curve: Curves.linear,
          ),
          FadeEffect(
            begin: 0.08,
            end: 0.15,
            duration: Duration(seconds: data.duration),
            curve: Curves.easeInOut,
          ),
        ],
        child: Icon(
          data.icon,
          size: 96,
          color: const Color(0xFF39A4E6).withOpacity(0.1),
        ),
      ),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  final double size;
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final Color color;
  final double horizontalShift;
  final double verticalShift;

  const _BlurCircle({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.size,
    required this.color,
    required this.horizontalShift,
    required this.verticalShift,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Animate(
        onPlay: (controller) => controller.repeat(reverse: true),
        effects: [
          MoveEffect(
            begin: Offset.zero,
            end: Offset(horizontalShift, verticalShift),
            duration: 25.seconds,
            curve: Curves.easeInOut,
          ),
          FadeEffect(
            begin: 0.06,
            end: 0.12,
            duration: 20.seconds,
          ),
        ],
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color,
                blurRadius: size / 2,
                spreadRadius: size / 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicalIconData {
  final IconData icon;
  final double delay;
  final int duration;
  final double x;
  final double y;

  const _MedicalIconData({
    required this.icon,
    required this.delay,
    required this.duration,
    required this.x,
    required this.y,
  });
}

