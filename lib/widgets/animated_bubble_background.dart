import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedBubbleBackground extends StatelessWidget {
  const AnimatedBubbleBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Small floating bubbles
        ...List.generate(20, (i) {
          final size = 12.0 + (i % 6) * 6;
          final left = (i * 5) % 100;
          final top = (i * 13) % 100;
          final delay = i * 0.12;
          final duration = 5 + (i % 4) * 1.5;

          return Positioned(
            left: MediaQuery.of(context).size.width * (left / 100),
            top: MediaQuery.of(context).size.height * (top / 100),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF39A4E6).withValues(alpha: 0.25),
                  width: 2,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF39A4E6).withValues(alpha: 0.1),
                    const Color(0xFF39A4E6).withValues(alpha: 0.05),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF39A4E6).withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .moveY(
                  begin: 0,
                  end: -120 - (i % 4) * 60,
                  duration: duration.seconds,
                  curve: Curves.easeInOut,
                  delay: delay.seconds,
                )
                .moveX(
                  begin: 0,
                  end: (i % 2 == 0 ? 20 : -20) + (i % 3) * 10,
                  duration: duration.seconds,
                  curve: Curves.easeInOut,
                )
                .fadeIn(duration: (duration * 0.2).seconds)
                .fadeOut(
                  delay: (duration * 0.8).seconds,
                  duration: (duration * 0.2).seconds,
                )
                .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1.2, 1.2),
                  duration: duration.seconds,
                ),
          );
        }),

        // Tiny sparkle bubbles
        ...List.generate(15, (i) {
          final left = (i * 10 + 3) % 97;
          final top = (i * 17) % 100;
          final delay = i * 0.18;
          final duration = 4 + (i % 3);

          return Positioned(
            left: MediaQuery.of(context).size.width * (left / 100),
            top: MediaQuery.of(context).size.height * (top / 100),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF39A4E6).withValues(alpha: 0.4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF39A4E6).withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .moveY(
                  begin: 0,
                  end: -180 - (i % 5) * 40,
                  duration: duration.seconds,
                  curve: Curves.easeOut,
                  delay: delay.seconds,
                )
                .moveX(
                  begin: 0,
                  end: (i % 2 == 0 ? 15.0 : -15.0),
                  duration: duration.seconds,
                )
                .fadeIn(duration: (duration * 0.2).seconds)
                .fadeOut(
                  delay: (duration * 0.8).seconds,
                  duration: (duration * 0.2).seconds,
                )
                .scale(
                  begin: Offset.zero,
                  end: const Offset(1.2, 1.2),
                  duration: (duration * 0.5).seconds,
                ),
          );
        }),

        // Ambient bubbles
        ...List.generate(10, (i) {
          final size = 8.0 + (i % 4) * 5;
          final left = (i * 11) % 100;
          final top = (i * 19) % 100;
          final delay = i * 0.25;
          final duration = 7 + (i % 3) * 2;

          return Positioned(
            left: MediaQuery.of(context).size.width * (left / 100),
            top: MediaQuery.of(context).size.height * (top / 100),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF39A4E6).withValues(alpha: 0.15),
                ),
                color: const Color(0xFF39A4E6).withValues(alpha: 0.05),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .moveY(
                  begin: 0,
                  end: (i % 2 == 0 ? -80 : 80),
                  duration: duration.seconds,
                  curve: Curves.easeInOut,
                  delay: delay.seconds,
                )
                .moveX(
                  begin: 0,
                  end: (i % 3 == 0 ? 60 : -60),
                  duration: duration.seconds,
                  curve: Curves.easeInOut,
                )
                .fade(
                  begin: 0.2,
                  end: 0.5,
                  duration: duration.seconds,
                )
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.1, 1.1),
                  duration: duration.seconds,
                ),
          );
        }),
      ],
    );
  }
}
