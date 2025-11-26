import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'camera_upload_screen.dart'; // For UploadedFile model

class SuccessScreen extends StatefulWidget {
  final bool isDarkMode;
  final List<UploadedFile> capturedItems;
  final VoidCallback onClose;
  final Function(String) setViewMode;

  const SuccessScreen({
    super.key,
    required this.isDarkMode,
    required this.capturedItems,
    required this.onClose,
    required this.setViewMode,
  });

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  bool isShareModalOpen = false;
  bool isCopied = false;
  final String shareLink = 'https://healthtrack.app/reports/${DateTime.now().millisecondsSinceEpoch}';

  Future<void> _handleShare() async {
    await Share.share('View my medical reports: $shareLink');
  }

  Future<void> _handleCopyLink() async {
    await Clipboard.setData(ClipboardData(text: shareLink));
    setState(() => isCopied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => isCopied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.isDarkMode
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Success Icon
                          _buildSuccessIcon(),

                          const SizedBox(height: 40),

                          // Title & Description
                          Text(
                            'Success!',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF39A4E6),
                            ),
                          ).animate().fadeIn().slideY(begin: 0.2, end: 0),

                          const SizedBox(height: 12),

                          Text(
                            'Your ${widget.capturedItems.length} medical report${widget.capturedItems.length == 1 ? '' : 's have'} been successfully processed and are ready to view',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ).animate().fadeIn(delay: 200.ms),

                          const SizedBox(height: 40),

                          // Stats Cards
                          _buildStatsCards(),

                          const SizedBox(height: 40),

                          // Action Buttons
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Share Modal
          if (isShareModalOpen) _buildShareModal(),
        ],
      ),
    );
  }

  Widget _buildBackgroundAnimations() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 600,
            height: 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [const Color(0xFF39A4E6).withOpacity(0.15), Colors.transparent],
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(duration: 15.seconds, begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
        ),
        // Floating Icons
        _buildFloatingIcon(top: 100, right: 50, icon: LucideIcons.checkCircle2),
        _buildFloatingIcon(bottom: 150, left: 50, icon: LucideIcons.shield),
        _buildFloatingIcon(top: 300, left: 30, icon: LucideIcons.heart),
      ],
    );
  }

  Widget _buildFloatingIcon({double? top, double? bottom, double? left, double? right, required IconData icon}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Icon(
        icon,
        size: 32,
        color: const Color(0xFF39A4E6).withOpacity(0.1),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .moveY(duration: 6.seconds, begin: 0, end: -20),
    );
  }

  Widget _buildSuccessIcon() {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Rings
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF39A4E6).withOpacity(0.1),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),

          // Main Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF39A4E6), Color(0xFF2D7FBA)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF39A4E6).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(LucideIcons.check, color: Colors.white, size: 64),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final stats = [
      {'icon': LucideIcons.fileCheck, 'value': '${widget.capturedItems.length}', 'label': 'Files'},
      {'icon': LucideIcons.zap, 'value': 'Fast', 'label': 'Speed'},
      {'icon': LucideIcons.checkCircle2, 'value': '100%', 'label': 'Success'},
    ];

    return Row(
      children: stats.asMap().entries.map((entry) {
        final index = entry.key;
        final stat = entry.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF39A4E6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(stat['icon'] as IconData, color: const Color(0xFF39A4E6), size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  stat['value'] as String,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  stat['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.2, end: 0),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onClose,
            icon: const Icon(LucideIcons.home),
            label: const Text('Go to Home'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF39A4E6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: const Color(0xFF39A4E6).withOpacity(0.4),
            ),
          ),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => widget.setViewMode('review'),
                icon: const Icon(LucideIcons.eye),
                label: const Text('View Files'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: widget.isDarkMode ? Colors.white : Colors.black,
                  side: BorderSide(
                    color: widget.isDarkMode ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.3),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => isShareModalOpen = true),
                icon: const Icon(LucideIcons.share2),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: widget.isDarkMode ? Colors.white : Colors.black,
                  side: BorderSide(
                    color: widget.isDarkMode ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.3),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }

  Widget _buildShareModal() {
    return GestureDetector(
      onTap: () => setState(() => isShareModalOpen = false),
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping content
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40), // Spacer for centering
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF39A4E6).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.share2, color: Color(0xFF39A4E6), size: 32),
                      ),
                      IconButton(
                        onPressed: () => setState(() => isShareModalOpen = false),
                        icon: const Icon(LucideIcons.x),
                        color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Share Reports',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Share your medical reports securely',
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Link Copy
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: widget.isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.link, size: 20, color: Color(0xFF39A4E6)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            shareLink,
                            style: TextStyle(
                              color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _handleCopyLink,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF39A4E6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isCopied ? LucideIcons.check : LucideIcons.copy,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isCopied ? 'Copied' : 'Copy',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _handleShare,
                      icon: const Icon(LucideIcons.share),
                      label: const Text('Share via...'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: widget.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        foregroundColor: widget.isDarkMode ? Colors.white : Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}
