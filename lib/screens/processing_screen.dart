import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:io';
import 'package:health_track/models/uploaded_file.dart';

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
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Modern Circular Progress
              _buildModernProgress(),
              
              const SizedBox(height: 48),
              
              // Status Text
              Text(
                processingStatus,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ).animate(key: ValueKey(processingStatus)).fadeIn().slideY(begin: 0.1, end: 0),
              
              const Spacer(),
              
              // File Processing Card
              _buildFileCard(),
              
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernProgress() {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Ring (Static)
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                width: 12,
              ),
            ),
          ),
          
          // Progress Ring
          SizedBox(
            width: 220,
            height: 220,
            child: CircularProgressIndicator(
              value: processingProgress / 100,
              strokeWidth: 12,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF39A4E6)),
              strokeCap: StrokeCap.round,
            ),
          ),
          
          // Inner Glow/Shadow
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDarkMode ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF39A4E6).withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${processingProgress.toInt()}%',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF39A4E6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(LucideIcons.fileText, color: Color(0xFF39A4E6), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Processing ${capturedItems.length} file${capturedItems.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  capturedItems.isNotEmpty ? capturedItems.first.name : 'Preparing...',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 20,
            height: 20,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF39A4E6)),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.2, end: 0, delay: 200.ms).fadeIn();
  }
}
