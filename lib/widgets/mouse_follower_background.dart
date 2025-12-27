import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as dart_ui;

class MouseFollowerBackground extends StatefulWidget {
  final bool isDark;
  const MouseFollowerBackground({super.key, required this.isDark});

  @override
  State<MouseFollowerBackground> createState() => _MouseFollowerBackgroundState();
}

class _MouseFollowerBackgroundState extends State<MouseFollowerBackground> with SingleTickerProviderStateMixin {
  Offset _mousePos = Offset.zero;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (details) {
        setState(() {
          _mousePos = details.localPosition;
        });
      },
      child: Stack(
        children: [
          // Base
          Container(
            color: widget.isDark ? const Color(0xFF050505) : const Color(0xFFFAFAFA),
          ),
          
          // Moving Orbs
          _buildOrb(
            context, 
            Alignment.topLeft, 
            const Color(0xFF39A4E6), 
            const Offset(50, 50),
            0.05
          ),
          _buildOrb(
            context, 
            Alignment.bottomRight, 
            const Color(0xFF1A73E8), 
            const Offset(-50, -50),
            0.08
          ),
           _buildOrb(
            context, 
            Alignment.centerRight, 
            const Color(0xFF00C6FF), 
            const Offset(-100, 100),
            0.03
          ),
          
          // Grid Overlay
          CustomPaint(
            painter: GridPainter(
               color: widget.isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
            ),
            size: Size.infinite,
          ),
        ],
      ),
    );
  }

  Widget _buildOrb(BuildContext context, Alignment align, Color color, Offset offset, double speed) {
    final size = MediaQuery.of(context).size;
    final moveX = (_mousePos.dx - size.width / 2) * speed;
    final moveY = (_mousePos.dy - size.height / 2) * speed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      transform: Matrix4.identity()..translate(moveX, moveY),
      child: Align(
        alignment: align,
        child: Container(
          width: 500,
          height: 500,
          margin: EdgeInsets.only(left: offset.dx, top: offset.dy),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withOpacity(0.3),
                color.withOpacity(0.0),
              ],
            ),
          ),
          child: BackdropFilter(
            filter: dart_ui.ImageFilter.blur(sigmaX: 100, sigmaY: 100),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const spacing = 40.0;

    for (var i = 0.0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (var i = 0.0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
