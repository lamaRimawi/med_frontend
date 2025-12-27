import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/vlm_service.dart';
import '../config/api_config.dart';
import '../models/extracted_report_data.dart';

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
        setState(() {
          _selectedFiles = result.files;
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to pick files: $e';
      });
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        final int imageSize = await image.length();
        final Uint8List imageBytes = await image.readAsBytes();
        setState(() {
          _selectedFiles.add(
            PlatformFile(
              name: image.name,
              size: imageSize,
              path: image.path,
              bytes: imageBytes,
            ),
          );
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to capture image: $e';
      });
    }
  }

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
            });

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Report processed successfully!'),
                backgroundColor: const Color(0xFF10B981),
                duration: const Duration(seconds: 2),
              ),
            );

            // Close after a moment
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                widget.onClose?.call();
              }
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

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: widget.isDarkMode
            ? const Color(0xFF121212)
            : const Color(0xFFF9FAFB),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildUploadArea(),
                        if (_error != null) ...[
                          const SizedBox(height: 24),
                          _buildError(),
                        ],
                        if (_isUploading) ...[
                          const SizedBox(height: 32),
                          _buildProcessingIndicator(),
                        ],
                        if (_selectedFiles.isNotEmpty && !_isUploading) ...[
                          const SizedBox(height: 32),
                          _buildFileList(),
                          const SizedBox(height: 32),
                          _buildUploadButton(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onClose,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  LucideIcons.arrowLeft,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Upload Medical Report',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(60),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey[300]!,
              width: 2,
              style: BorderStyle.solid,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF39A4E6).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.upload,
                  size: 48,
                  color: Color(0xFF39A4E6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Upload Medical Reports',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Select images or PDF files from your device',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    'Choose Files',
                    LucideIcons.folder,
                    _pickFiles,
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    'Take Photo',
                    LucideIcons.camera,
                    _pickFromCamera,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Supported formats: JPG, PNG, PDF',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF39A4E6).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertCircle, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: GoogleFonts.outfit(color: Colors.red, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
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
    final isImage =
        fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.png');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF39A4E6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isImage ? LucideIcons.image : LucideIcons.fileText,
              color: const Color(0xFF39A4E6),
              size: 24,
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
                    fontWeight: FontWeight.w600,
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  file.size > 0
                      ? '${(file.size / 1024 / 1024).toStringAsFixed(2)} MB'
                      : 'File selected',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _removeFile(index),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(LucideIcons.x, size: 18, color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isUploading ? null : _uploadFiles,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF39A4E6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isUploading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Uploading...',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.upload, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Upload ${_selectedFiles.length} ${_selectedFiles.length == 1 ? 'File' : 'Files'}',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: _processingProgress / 100,
              strokeWidth: 6,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF39A4E6),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _processingStatus,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_processingProgress.toInt()}%',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
