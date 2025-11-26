import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import 'dart:io';
import 'camera_upload_screen.dart'; // For UploadedFile model

class ProcessingScreen extends StatelessWidget {
  final bool isDarkMode;
  final String processingStatus;
  final double processingProgress;
  final List<UploadedFile> capturedItems;

  const ProcessingScreen({
    super.key,
    required this.isDarkMode,
    required this.processingStatus,
    required this.processingProgress,
    required this.capturedItems,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [const Color(0xFF0F172A), const Color(0xFF111827), const Color(0xFF0F172A)]
                : [const Color(0xFFF8FAFC), Colors.white, const Color(0xFFF8FAFC)],
          ),
        ),
        child: Stack(
          children: [
            // Background Animations
            _buildBackgroundAnimations(),

            // Content
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Circular Progress
                    _buildCircularProgress(),

                    const SizedBox(height: 40),

                    // Status Text
                    Text(
                      processingStatus,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ).animate(key: ValueKey(processingStatus)).fadeIn().slideY(begin: 0.2, end: 0),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Analyzing your medical reports with AI',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Files Card
                    _buildFilesCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundAnimations() {
    return Stack(
      children: [
        // Large Orbs
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [const Color(0xFF39A4E6).withOpacity(0.2), Colors.transparent],
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .move(duration: 12.seconds, begin: Offset.zero, end: const Offset(50, -30)),
        ),
        Positioned(
          bottom: -100,
          right: -100,
          child: Container(
            width: 600,
            height: 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [const Color(0xFF2D7FBA).withOpacity(0.2), Colors.transparent],
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .move(duration: 15.seconds, begin: Offset.zero, end: const Offset(-40, 40)),
        ),

        // Floating Icons
        _buildFloatingIcon(top: 120, right: 80, icon: LucideIcons.stethoscope, delay: 0),
        _buildFloatingIcon(bottom: 180, left: 60, icon: LucideIcons.pill, delay: 1),
        _buildFloatingIcon(top: 200, left: 60, icon: LucideIcons.clipboard, delay: 2),
        _buildFloatingIcon(bottom: 250, right: 60, icon: LucideIcons.shield, delay: 3),
        _buildFloatingIcon(top: 300, right: 100, icon: LucideIcons.heart, delay: 4),
        _buildFloatingIcon(top: 500, left: 100, icon: LucideIcons.activity, delay: 5),
      ],
    );
  }

  Widget _buildFloatingIcon({double? top, double? bottom, double? left, double? right, required IconData icon, required int delay}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Icon(
        icon,
        size: 40,
        color: const Color(0xFF39A4E6).withOpacity(0.1),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .moveY(duration: 8.seconds, begin: 0, end: -20, delay: (delay * 500).ms)
       .rotate(duration: 10.seconds, begin: 0, end: 0.1),
    );
  }

  Widget _buildCircularProgress() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Glow
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF39A4E6).withOpacity(0.1),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),

          // Progress Indicator
          SizedBox(
            width: 180,
            height: 180,
            child: CircularProgressIndicator(
              value: processingProgress / 100,
              strokeWidth: 12,
              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF39A4E6)),
              strokeCap: StrokeCap.round,
            ),
          ),

          // Center Content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.sparkles, color: Color(0xFF39A4E6), size: 32),
              ).animate(onPlay: (c) => c.repeat()).rotate(duration: 3.seconds),
              const SizedBox(height: 8),
              Text(
                '${processingProgress.toInt()}%',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF39A4E6),
                ),
              ),
            ],
          ),

          // Orbiting Dots
          ...List.generate(3, (index) {
            return Positioned.fill(
              child: Transform.rotate(
                angle: index * (2 * math.pi / 3),
                child: Center(
                  child: Container(
                    width: 180, // Orbit diameter
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFF39A4E6),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Color(0xFF39A4E6), blurRadius: 8)],
                      ),
                    ),
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat())
               .rotate(duration: 4.seconds, begin: 0, end: 1),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilesCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF39A4E6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(LucideIcons.fileText, color: Color(0xFF39A4E6)),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${capturedItems.length}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        'File${capturedItems.length == 1 ? '' : 's'} Processing',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Icon(LucideIcons.loader2, color: Color(0xFF39A4E6))
                  .animate(onPlay: (c) => c.repeat())
                  .rotate(duration: 2.seconds),
            ],
          ),
          const SizedBox(height: 24),
          
          // Progress Bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 300),
                  widthFactor: processingProgress / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF39A4E6), Color(0xFF2D7FBA)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Thumbnails
          if (capturedItems.isNotEmpty)
            Row(
              children: [
                ...capturedItems.take(5).map((item) {
                  return Expanded(
                    child: Container(
                      height: 50,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                        ),
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: item.type.startsWith('image/')
                            ? Image.file(
                                File(item.path),
                                fit: BoxFit.cover,
                              )
                            : const Center(
                                child: Icon(LucideIcons.fileText, size: 20, color: Color(0xFF39A4E6)),
                              ),
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.5, end: 0);
                }),
                if (capturedItems.length > 5)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                      border: Border.all(
                        color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '+${capturedItems.length - 5}',
                        style: const TextStyle(
                          color: Color(0xFF39A4E6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    ).animate().slideY(begin: 0.2, end: 0, delay: 200.ms).fadeIn();
  }
}

// Helper for File import since I used java.io.File in the code above which is wrong for Dart
// Actually I'll just fix the import in the file content
