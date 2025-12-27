import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui';
import '../services/vlm_service.dart';
import '../config/api_config.dart';
import '../models/extracted_report_data.dart';

enum WebUploadMode { initial, review, processing, success }

class WebCameraUploadView extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback? onClose;

  const WebCameraUploadView({
    super.key,
    required this.isDarkMode,
    this.onClose,
  });

  @override
  State<WebCameraUploadView> createState() => _WebCameraUploadViewState();
}

class _WebCameraUploadViewState extends State<WebCameraUploadView> {
  WebUploadMode _viewMode = WebUploadMode.initial;
  List<PlatformFile> _selectedFiles = [];
  bool _isUploading = false;
  String? _error;
  String _processingStatus = '';
  double _processingProgress = 0.0;
  ExtractedReportData? _extractedData;

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: true,
      );

    if (result != null && result.files.isNotEmpty) {
      if (mounted) {
        setState(() {
          _selectedFiles = result.files;
          _error = null;
          _viewMode = WebUploadMode.review;
        });
      }
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _error = 'Failed to pick files: $e';
      });
    }
  }
}

  Future<void> _pickFromCamera() async {}

  Future<void> _uploadFiles() async {
    if (_selectedFiles.isEmpty) {
      setState(() {
        _error = 'Please select at least one file';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
      _processingStatus = 'Initializing...';
      _processingProgress = 0.0;
    });

    try {
      // Get file paths - on web, FilePicker should provide paths
      final filePaths = _selectedFiles
          .where((file) => file.path != null && file.path!.isNotEmpty)
          .map((file) => file.path!)
          .toList();

      if (filePaths.isEmpty) {
        setState(() {
          _error =
              'No valid file paths found. Please try selecting files again.';
          _isUploading = false;
        });
        return;
      }

      // Use streaming API for progress updates
      VlmService.extractFromImagesStreamed(
        filePaths,
        onProgress: (status, percent) {
          if (mounted) {
            setState(() {
              _processingStatus = status;
              _processingProgress = percent;
            });
          }
        },
        onComplete: (data) {
          if (mounted) {
            setState(() {
              _extractedData = data;
              _processingProgress = 100.0;
              _processingStatus = 'Complete!';
              _isUploading = false;
              _viewMode = WebUploadMode.success;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _error = error;
              _isUploading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to upload files: $e';
          _isUploading = false;
        });
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: widget.isDarkMode
            ? const Color(0xFF0A1929)
            : const Color(0xFFF9FAFB),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _buildCurrentView(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_viewMode) {
      case WebUploadMode.initial:
        return _buildInitialView();
      case WebUploadMode.review:
        return _buildReviewView();
      case WebUploadMode.processing:
        return _buildProcessingView();
      case WebUploadMode.success:
        return _buildSuccessView();
    }
  }

  Widget _buildHeader() {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 50),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF0F2137) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: (widget.isDarkMode ? Colors.white : Colors.black).withOpacity(0.05),
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF39A4E6).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.filePlus,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Report Analysis',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
        ],
      ),
    ),
    ),
    );
  }

  Widget _buildInitialView() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildUploadArea(),
              if (_error != null) ...[
                const SizedBox(height: 16),
                _buildError(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewView() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Review Reports',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  if (!_selectedFiles.any((f) => f.name.toLowerCase().endsWith('.pdf')))
                    TextButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: const Text('Add More'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF39A4E6),
                        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildFileList(),
              const SizedBox(height: 32),
              _buildUploadButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: _buildProcessingIndicator(),
    );
  }

  Widget _buildSuccessView() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? const Color(0xFF0F2137) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.05),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.checkCircle,
                  color: Color(0xFF10B981),
                  size: 48,
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 24),
              Text(
                'Analysis Complete!',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your medical report has been successfully processed and analyzed by our AI.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: (widget.isDarkMode ? Colors.white : Colors.black).withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: _buildActionButton(
                  'View Full Report',
                  LucideIcons.eye,
                  () {
                     widget.onClose?.call();
                  },
                  gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadArea() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _pickFiles,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 30),
          decoration: BoxDecoration(
            color: (widget.isDarkMode ? Colors.black : Colors.white).withOpacity(widget.isDarkMode ? 0.2 : 0.6),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                children: [
                   Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF39A4E6).withOpacity(0.1),
                          const Color(0xFF2B8FD9).withOpacity(0.05),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFF39A4E6).withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF39A4E6).withOpacity(0.05),
                        ),
                        child: const Icon(
                          LucideIcons.uploadCloud,
                          size: 26,
                          color: Color(0xFF39A4E6),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                       .moveY(begin: -3, end: 3, duration: 2.seconds, curve: Curves.easeInOut),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Upload or Drag & Drop',
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Analyze your medical reports with AI',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: (widget.isDarkMode ? Colors.white : Colors.black).withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Supported file formats:',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: (widget.isDarkMode ? Colors.white : Colors.black).withOpacity(0.3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFormatBadge('JPG'),
                      const SizedBox(width: 8),
                      _buildFormatBadge('PNG'),
                      const SizedBox(width: 8),
                      _buildFormatBadge('PDF'),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF39A4E6).withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.fileSearch, color: Colors.white, size: 18),
                        const SizedBox(width: 12),
                        Text(
                          'Choose Files',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ).animate(onPlay: (c) => c.repeat())
                   .shimmer(delay: 3.seconds, duration: 2.seconds),
                ],
              ),
            ),
          ),
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 600.ms)
    .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildFormatBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.isDarkMode 
            ? Colors.white.withOpacity(0.05) 
            : const Color(0xFF39A4E6).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isDarkMode 
              ? Colors.white.withOpacity(0.1) 
              : const Color(0xFF39A4E6).withOpacity(0.15),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: widget.isDarkMode 
              ? Colors.white.withOpacity(0.5) 
              : const Color(0xFF39A4E6).withOpacity(0.8),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap, {List<Color>? gradient}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient ?? [const Color(0xFF39A4E6), const Color(0xFF2B8FD9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (gradient?.first ?? const Color(0xFF39A4E6)).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF7F1D1D).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle, color: Color(0xFFEF4444), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _error!,
              style: GoogleFonts.outfit(
                color: const Color(0xFFEF4444),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _error = null),
            icon: const Icon(LucideIcons.x, color: Color(0xFFEF4444), size: 18),
          ),
        ],
      ),
    ).animate().shake();
  }

  Widget _buildFileList() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF0F2137) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Files (${_selectedFiles.length})',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ..._selectedFiles.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            return _buildFileItem(file, index);
          }),
        ],
      ),
    );
  }

  Widget _buildFileItem(PlatformFile file, int index) {
    final fileName = file.name;
    final isImage = fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.png');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (widget.isDarkMode ? Colors.white : const Color(0xFF39A4E6)).withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF39A4E6).withOpacity(0.1),
                  const Color(0xFF2B8FD9).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isImage ? LucideIcons.image : LucideIcons.fileText,
              color: const Color(0xFF39A4E6),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      file.size > 0
                          ? '${(file.size / 1024 / 1024).toStringAsFixed(2)} MB'
                          : 'Selected',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: (widget.isDarkMode ? Colors.white : Colors.black).withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              _removeFile(index);
              if (_selectedFiles.isEmpty) {
                setState(() => _viewMode = WebUploadMode.initial);
              }
            },
            icon: const Icon(LucideIcons.trash2, size: 18, color: Color(0xFFEF4444)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      child: _buildActionButton(
        'Generate AI Report',
        LucideIcons.zap,
        () {
           setState(() => _viewMode = WebUploadMode.processing);
           _uploadFiles();
        },
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF0F2137) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (widget.isDarkMode ? Colors.white : Colors.black).withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: _processingProgress / 100,
                  strokeWidth: 6,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF39A4E6)),
                  backgroundColor: (widget.isDarkMode ? Colors.white : Colors.black).withOpacity(0.05),
                ),
              ),
              Text(
                '${_processingProgress.toInt()}%',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 2.seconds),
          const SizedBox(height: 32),
          Text(
            _processingStatus,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Analyzing medical data using secure AI...',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: (widget.isDarkMode ? Colors.white : Colors.black).withOpacity(0.4),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
