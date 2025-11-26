import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

class AlertBanner extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback? onDismiss;
  final bool autoDismiss;

  const AlertBanner({
    super.key,
    required this.message,
    this.isError = true,
    this.onDismiss,
    this.autoDismiss = false,
  });

  @override
  State<AlertBanner> createState() => _AlertBannerState();
}

class _AlertBannerState extends State<AlertBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _controller.forward();

    if (widget.autoDismiss && !widget.isError) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _dismiss();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    if (widget.onDismiss != null && mounted) {
      widget.onDismiss!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      )),
      child: FadeTransition(
        opacity: _controller,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.isError
                    ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                    : const Color(0xFF10B981).withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isError
                        ? [
                            const Color(0xFFFEF2F2).withValues(alpha: 0.95),
                            const Color(0xFFFEE2E2).withValues(alpha: 0.95),
                          ]
                        : [
                            const Color(0xFFF0FDF4).withValues(alpha: 0.95),
                            const Color(0xFFDCFCE7).withValues(alpha: 0.95),
                          ],
                  ),
                  border: Border.all(
                    color: widget.isError
                        ? const Color(0xFFFECACA).withValues(alpha: 0.5)
                        : const Color(0xFFBBF7D0).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    // Animated Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.isError
                              ? [
                                  const Color(0xFFEF4444).withValues(alpha: 0.2),
                                  const Color(0xFFDC2626).withValues(alpha: 0.1),
                                ]
                              : [
                                  const Color(0xFF10B981).withValues(alpha: 0.2),
                                  const Color(0xFF059669).withValues(alpha: 0.1),
                                ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.isError
                                ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                                : const Color(0xFF10B981).withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                        color: widget.isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        size: 24,
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.1, 1.1),
                          duration: 1.5.seconds,
                        )
                        .then()
                        .shimmer(duration: 2.seconds, color: Colors.white.withValues(alpha: 0.3)),

                    const SizedBox(width: 14),

                    // Message
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isError ? 'Error' : 'Success',
                            style: TextStyle(
                              color: widget.isError ? const Color(0xFF991B1B) : const Color(0xFF166534),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.message,
                            style: TextStyle(
                              color: widget.isError ? const Color(0xFF991B1B) : const Color(0xFF166534),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Close Button
                    if (widget.onDismiss != null)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _dismiss,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: widget.isError
                                  ? const Color(0xFF991B1B).withValues(alpha: 0.6)
                                  : const Color(0xFF166534).withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
