import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';

enum ScanMode { scan, upload }

enum UploadStatus { uploading, processing, completed, error }

class UploadedFile {
  final String id;
  final String name;
  final int size;
  final String type;
  final String path;
  double progress;
  UploadStatus status;

  UploadedFile({
    required this.id,
    required this.name,
    required this.size,
    required this.type,
    required this.path,
    this.progress = 0,
    this.status = UploadStatus.uploading,
  });
}

class CameraUploadScreen extends StatefulWidget {
  final bool isDarkMode;

  const CameraUploadScreen({super.key, required this.isDarkMode});

  @override
  State<CameraUploadScreen> createState() => _CameraUploadScreenState();
}

class _CameraUploadScreenState extends State<CameraUploadScreen> with TickerProviderStateMixin {
  List<UploadedFile> uploadedFiles = [];
  ScanMode scanMode = ScanMode.scan;
  bool showCamera = false;
  bool showTutorial = false;
  int tutorialStep = 0;
  String? cameraError;
  bool flashEnabled = false;
  bool isCapturing = false;
  bool showReview = false;
  
  CameraController? cameraController;
  List<CameraDescription>? cameras;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, String>> tutorialSteps = [
    {
      'title': 'Position Your Document',
      'description': 'Place your medical report inside the glowing frame',
      'highlight': 'document-frame',
    },
    {
      'title': 'Capture Multiple Documents',
      'description': 'Tap capture button multiple times to scan multiple pages',
      'highlight': 'capture-button',
    },
    {
      'title': 'Review & Process',
      'description': 'Review your captures, add more, or delete unwanted items before processing',
      'highlight': 'process-button',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (scanMode == ScanMode.scan) {
      _initializeCamera();
    }
    _checkTutorial();
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('hasSeenCameraUploadTutorial') ?? false;
    if (!hasSeenTutorial && scanMode == ScanMode.scan) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        setState(() => showTutorial = true);
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          cameraError = 'Camera permission denied. Please allow camera access in settings.';
        });
        return;
      }

      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) {
        setState(() {
          cameraError = 'No camera found on this device.';
        });
        return;
      }

      cameraController = CameraController(
        cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          showCamera = true;
          cameraError = null;
        });
      }
    } catch (e) {
      setState(() {
        cameraError = 'Unable to access camera: ${e.toString()}';
        showCamera = false;
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (cameraController == null || !cameraController!.value.isInitialized || isCapturing) {
      return;
    }

    setState(() => isCapturing = true);

    try {
      final image = await cameraController!.takePicture();
      _handleCapturedFile(File(image.path));
    } catch (e) {
      debugPrint('Error capturing photo: $e');
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() => isCapturing = false);
      }
    }
  }

  Future<void> _pickFiles() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      for (var image in images) {
        _handleCapturedFile(File(image.path));
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
    }
  }

  void _handleCapturedFile(File file) {
    final newFile = UploadedFile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: file.path.split('/').last,
      size: file.lengthSync(),
      type: file.path.endsWith('.pdf') ? 'application/pdf' : 'image/jpeg',
      path: file.path,
      status: UploadStatus.completed,
      progress: 100,
    );

    setState(() {
      uploadedFiles.add(newFile);
    });
  }

  void _removeFile(String fileId) {
    setState(() {
      uploadedFiles.removeWhere((f) => f.id == fileId);
      if (uploadedFiles.isEmpty) {
        showReview = false;
      }
    });
  }

  void _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenCameraUploadTutorial', true);
    setState(() {
      showTutorial = false;
      tutorialStep = 0;
    });
  }

  void _nextTutorialStep() {
    if (tutorialStep < tutorialSteps.length - 1) {
      setState(() => tutorialStep++);
    } else {
      _completeTutorial();
    }
  }

  void _processFiles() {
    // TODO: Implement actual processing logic
    Navigator.pop(context, uploadedFiles);
  }

  @override
  Widget build(BuildContext context) {
    if (showReview) {
      return _buildReviewScreen();
    }
    
    if (scanMode == ScanMode.upload) {
      return _buildUploadMode();
    }
    return _buildCameraMode();
  }

  Widget _buildReviewScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.isDarkMode
                ? [const Color(0xFF0F172A), Colors.black]
                : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => showReview = false),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: widget.isDarkMode
                                ? [const Color(0xFF1F2937), const Color(0xFF111827)]
                                : [const Color(0xFFF3F4F6), const Color(0xFFE5E7EB)],
                          ),
                        ),
                        child: Icon(
                          LucideIcons.arrowLeft,
                          color: widget.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ).animate().scale(delay: 100.ms),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Review Documents',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: widget.isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            '${uploadedFiles.length} ${uploadedFiles.length == 1 ? 'item' : 'items'} selected',
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Files Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: uploadedFiles.length,
                  itemBuilder: (context, index) {
                    final file = uploadedFiles[index];
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: widget.isDarkMode
                            ? Colors.white.withOpacity(0.05)
                            : Colors.white,
                        border: Border.all(
                          color: widget.isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Image Preview
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: file.type.startsWith('image/')
                                  ? Image.file(
                                      File(file.path),
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: const Color(0xFF00D9D9).withOpacity(0.1),
                                      child: const Center(
                                        child: Icon(
                                          LucideIcons.fileText,
                                          size: 48,
                                          color: Color(0xFF00D9D9),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          // Delete Button
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => _removeFile(file.id),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red.withOpacity(0.9),
                                ),
                                child: const Icon(
                                  LucideIcons.x,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                          // File Name
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                              child: Text(
                                file.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: (index * 50).ms).scale();
                  },
                ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: widget.isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: widget.isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => showReview = false),
                        icon: const Icon(LucideIcons.plus),
                        label: const Text('Add More'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: const BorderSide(color: Color(0xFF00D9D9)),
                          foregroundColor: const Color(0xFF00D9D9),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _processFiles,
                        icon: const Icon(LucideIcons.checkCircle2),
                        label: const Text('Process'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: const Color(0xFF00D9D9),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadMode() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.isDarkMode
                ? [const Color(0xFF0F172A), Colors.black]
                : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => scanMode = ScanMode.scan),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: widget.isDarkMode
                                ? [const Color(0xFF1F2937), const Color(0xFF111827)]
                                : [const Color(0xFFF3F4F6), const Color(0xFFE5E7EB)],
                          ),
                        ),
                        child: Icon(
                          LucideIcons.x,
                          color: widget.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ).animate().scale(delay: 100.ms),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload Files',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: widget.isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          'Images and PDFs supported',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Upload Area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickFiles,
                        child: Container(
                          padding: const EdgeInsets.all(64),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: widget.isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            color: widget.isDarkMode
                                ? Colors.white.withOpacity(0.05)
                                : Colors.white.withOpacity(0.5),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00D9D9), Color(0xFF00F5F5)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00D9D9).withOpacity(0.5),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(LucideIcons.upload, size: 48, color: Colors.white),
                              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                               .moveY(duration: 2.seconds, begin: 0, end: -10),
                              const SizedBox(height: 24),
                              Text(
                                'Choose Files',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: widget.isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Select images or PDFs from your device.\nMultiple files supported.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 32),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00D9D9), Color(0xFF00F5F5)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00D9D9).withOpacity(0.3),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Browse Files',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (uploadedFiles.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Selected Files (${uploadedFiles.length})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: widget.isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            TextButton(
                              onPressed: () => setState(() => uploadedFiles.clear()),
                              child: const Text(
                                'Clear All',
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...uploadedFiles.asMap().entries.map((entry) {
                          final file = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: widget.isDarkMode
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: widget.isDarkMode
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: const Color(0xFF00D9D9).withOpacity(0.2),
                                  ),
                                  child: file.type.startsWith('image/')
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.file(
                                            File(file.path),
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(LucideIcons.fileText, color: Color(0xFF00D9D9)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        file.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: widget.isDarkMode ? Colors.white : Colors.black,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${(file.size / 1024).toStringAsFixed(1)} KB',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _removeFile(file.id),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: (entry.key * 50).ms).slideX(begin: -0.2);
                        }).toList(),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => setState(() => showReview = true),
                            icon: const Icon(LucideIcons.checkCircle2),
                            label: const Text('Review & Process'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: const Color(0xFF00D9D9),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraMode() {
    return Scaffold(
      body: Stack(
        children: [
          // Camera Preview or Loading
          if (showCamera && cameraController != null && cameraController!.value.isInitialized)
            Positioned.fill(
              child: CameraPreview(cameraController!),
            )
          else
            Container(
              color: Colors.black,
              child: Center(
                child: cameraError != null
                    ? _buildCameraError()
                    : _buildCameraLoading(),
              ),
            ),

          // Document Frame Overlay
          if (showCamera && cameraController != null && cameraController!.value.isInitialized)
            _buildDocumentFrame(),

          // Flash Effect
          if (isCapturing)
            Positioned.fill(
              child: Container(
                color: Colors.white,
              ).animate().fadeIn(duration: 100.ms).fadeOut(duration: 200.ms),
            ),

          // Top Toolbar
          _buildTopToolbar(),

          // Bottom Mode Switcher
          _buildModeSwitcher(),

          // Capture Button
          _buildCaptureButton(),

          // Captured Counter & Process Button
          if (uploadedFiles.isNotEmpty)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D9D9), Color(0xFF00F5F5)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D9D9).withOpacity(0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.image, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${uploadedFiles.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => setState(() => showReview = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.checkCircle2, color: Color(0xFF00D9D9), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Review',
                              style: TextStyle(
                                color: Color(0xFF00D9D9),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.5),
            ),

          // Tutorial Overlay
          if (showTutorial)
            _buildTutorialOverlay(),
        ],
      ),
    );
  }

  Widget _buildCameraError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withOpacity(0.2),
            border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
          ),
          child: const Icon(LucideIcons.alertCircle, size: 48, color: Colors.red),
        ).animate().scale(),
        const SizedBox(height: 24),
        const Text(
          'Camera Error',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            cameraError ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _initializeCamera,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D9D9),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: () => setState(() => scanMode = ScanMode.upload),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Upload Instead', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCameraLoading() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF00D9D9)),
          ).animate(onPlay: (controller) => controller.repeat()).rotate(duration: 2.seconds),
        ),
        const SizedBox(height: 24),
        const Text(
          'Starting Camera...',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Please wait',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDocumentFrame() {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.only(top: 140, bottom: 280, left: 32, right: 32),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF00D9D9), width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D9D9).withOpacity(0.5),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Corner Markers
              ...List.generate(4, (index) {
                final positions = [
                  {'top': -1.0, 'left': -1.0, 'tl': true},
                  {'top': -1.0, 'right': -1.0, 'tr': true},
                  {'bottom': -1.0, 'left': -1.0, 'bl': true},
                  {'bottom': -1.0, 'right': -1.0, 'br': true},
                ];
                return Positioned(
                  top: positions[index]['top'] as double?,
                  left: positions[index]['left'] as double?,
                  right: positions[index]['right'] as double?,
                  bottom: positions[index]['bottom'] as double?,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border(
                        top: positions[index]['tl'] == true || positions[index]['tr'] == true
                            ? const BorderSide(color: Color(0xFF00D9D9), width: 4)
                            : BorderSide.none,
                        left: positions[index]['tl'] == true || positions[index]['bl'] == true
                            ? const BorderSide(color: Color(0xFF00D9D9), width: 4)
                            : BorderSide.none,
                        right: positions[index]['tr'] == true || positions[index]['br'] == true
                            ? const BorderSide(color: Color(0xFF00D9D9), width: 4)
                            : BorderSide.none,
                        bottom: positions[index]['bl'] == true || positions[index]['br'] == true
                            ? const BorderSide(color: Color(0xFF00D9D9), width: 4)
                            : BorderSide.none,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: positions[index]['tl'] == true ? const Radius.circular(16) : Radius.zero,
                        topRight: positions[index]['tr'] == true ? const Radius.circular(16) : Radius.zero,
                        bottomLeft: positions[index]['bl'] == true ? const Radius.circular(16) : Radius.zero,
                        bottomRight: positions[index]['br'] == true ? const Radius.circular(16) : Radius.zero,
                      ),
                    ),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                   .scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.1, 1.1), delay: (index * 500).ms),
                );
              }),
              
              // Center Guide
              Positioned(
                top: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Text(
                      'Align document within frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
         .shimmer(duration: 2.seconds, color: const Color(0xFF00D9D9).withOpacity(0.3)),
      ),
    );
  }

  Widget _buildTopToolbar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.3), Colors.transparent],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Icon(LucideIcons.x, color: Colors.white),
                ),
              ).animate().scale(delay: 100.ms),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => flashEnabled = !flashEnabled),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: flashEnabled
                            ? const Color(0xFFFBBF24).withOpacity(0.9)
                            : Colors.white.withOpacity(0.1),
                        border: Border.all(
                          color: flashEnabled
                              ? const Color(0xFFFBBF24).withOpacity(0.5)
                              : Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Icon(
                        LucideIcons.zap,
                        color: flashEnabled ? Colors.black : Colors.white,
                      ),
                    ),
                  ).animate().scale(delay: 200.ms),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        tutorialStep = 0;
                        showTutorial = true;
                      });
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withOpacity(0.1),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Icon(LucideIcons.info, color: Colors.white),
                    ),
                  ).animate().scale(delay: 300.ms),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSwitcher() {
    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.black.withOpacity(0.4),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModeButton(ScanMode.scan, LucideIcons.camera, 'Scan'),
              const SizedBox(width: 8),
              _buildModeButton(ScanMode.upload, LucideIcons.upload, 'Upload'),
            ],
          ),
        ),
      ).animate().slideY(begin: 0.5, duration: 500.ms),
    );
  }

  Widget _buildModeButton(ScanMode mode, IconData icon, String label) {
    final isActive = scanMode == mode;
    return GestureDetector(
      onTap: () => setState(() => scanMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF00D9D9), Color(0xFF00F5F5)],
                )
              : null,
          color: isActive ? null : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    ).animate().scale();
  }

  Widget _buildCaptureButton() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: showCamera && !isCapturing ? _capturePhoto : null,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFF00D9D9), width: 4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D9D9).withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: isCapturing
                ? const SizedBox()
                : Container(
                    margin: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.05, 1.05)),
        ),
      ),
    );
  }

  Widget _buildTutorialOverlay() {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.8),
          ).animate().fadeIn(),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: widget.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D9D9), Color(0xFF00F5F5)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D9D9).withOpacity(0.5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 32),
                ).animate(onPlay: (controller) => controller.repeat())
                 .rotate(duration: 2.seconds, begin: 0, end: 0.1, curve: Curves.easeInOut),
                const SizedBox(height: 24),
                Text(
                  tutorialSteps[tutorialStep]['title']!,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  tutorialSteps[tutorialStep]['description']!,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    tutorialSteps.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: index == tutorialStep ? 32 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: index == tutorialStep
                            ? const Color(0xFF00D9D9)
                            : Colors.grey[300],
                      ),
                    ).animate().scale(),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _completeTutorial,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(
                            color: widget.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _nextTutorialStep,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          backgroundColor: const Color(0xFF00D9D9),
                        ),
                        child: Text(
                          tutorialStep < tutorialSteps.length - 1 ? 'Next' : 'Got It!',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().scale(delay: 200.ms),
        ),
      ],
    );
  }
}
