import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool isInteractive;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(24),
    this.onTap,
    this.isInteractive = true,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: 300.ms,
          width: widget.width,
          height: widget.height,
          transform: Matrix4.identity()..scale(_isHovered && widget.isInteractive ? 1.02 : 1.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withOpacity(_isHovered ? 0.08 : 0.05)
                      : Colors.white.withOpacity(_isHovered ? 0.7 : 0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark 
                        ? Colors.white.withOpacity(_isHovered ? 0.2 : 0.1)
                        : Colors.white.withOpacity(_isHovered ? 0.8 : 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    if (_isHovered && widget.isInteractive)
                      BoxShadow(
                        color: const Color(0xFF39A4E6).withOpacity(isDark ? 0.15 : 0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 0),
                        spreadRadius: 5,
                      ),
                  ],
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
