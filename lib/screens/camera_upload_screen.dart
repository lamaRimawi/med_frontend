import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:async';
import 'processing_screen.dart';
import 'success_screen.dart';

// Export the model so other screens can use it
class UploadedFile {
  final String id;
  final String name;
  final int size;
  final String type;
  final String path;
  final int timestamp;

  UploadedFile({
    required this.id,
    required this.name,
    required this.size,
    required this.type,
    required this.path,
    required this.timestamp,
  });
}

enum ViewMode { camera, review, viewer, processing, success }

class CameraUploadScreen extends StatefulWidget {
  final bool isDarkMode;

  const CameraUploadScreen({super.key, required this.isDarkMode});

  @override
  State<CameraUploadScreen> createState() => _CameraUploadScreenState();
}

class _CameraUploadScreenState extends State<CameraUploadScreen> with TickerProviderStateMixin {
  List<UploadedFile> capturedItems = [];
  ViewMode viewMode = ViewMode.camera;
  bool showCamera = false;
  bool showTutorial = false;
  int tutorialStep = 0;
  String? cameraError;
  bool flashEnabled = false;
  bool isCapturing = false;
  int viewerItemIndex = 0;
  
  CameraController? cameraController;
  List<CameraDescription>? cameras;
  final ImagePicker _picker = ImagePicker();
  
  // Processing state
  double processingProgress = 0;
  String processingStatus = '';

  final List<Map<String, String>> tutorialSteps = [
    {
      'title': 'Capture Documents',
      'description': 'Tap the capture button to scan your medical reports. You can capture multiple pages.',
      'highlight': 'capture-button',
    },
    {
      'title': 'Upload from Gallery',
      'description': 'Tap the gallery icon to select multiple images or PDF files from your device.',
      'highlight': 'gallery-button',
    },
    {
      'title': 'Review & Process',
      'description': 'Review your captured items, add more, or delete unwanted ones before processing.',
      'highlight': 'process-button',
    },
    {
      'title': 'Camera Settings',
      'description': 'Toggle flash or rotate camera using the top toolbar for better capture quality.',
      'highlight': 'settings',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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
    if (!hasSeenTutorial) {
      await Future.delayed(const Duration(seconds: 2));
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
          showCamera = false;
        });
        return;
      }

      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) {
        setState(() {
          cameraError = 'No camera found on this device.';
          showCamera = false;
        });
        return;
      }

      // Default to back camera
      final camera = cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras!.first,
      );

      cameraController = CameraController(
        camera,
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

  Future<void> _toggleCameraLens() async {
    if (cameras == null || cameras!.length < 2) return;
    
    final lensDirection = cameraController?.description.lensDirection;
    CameraDescription newCamera;
    
    if (lensDirection == CameraLensDirection.back) {
      newCamera = cameras!.firstWhere((c) => c.lensDirection == CameraLensDirection.front);
    } else {
      newCamera = cameras!.firstWhere((c) => c.lensDirection == CameraLensDirection.back);
    }
    
    if (cameraController != null) {
      await cameraController!.dispose();
    }
    
    cameraController = CameraController(
      newCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    
    try {
      await cameraController!.initialize();
      setState(() {});
    } catch (e) {
      print('Error switching camera: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (cameraController == null) return;
    
    try {
      if (flashEnabled) {
        await cameraController!.setFlashMode(FlashMode.off);
      } else {
        await cameraController!.setFlashMode(FlashMode.torch);
      }
      setState(() => flashEnabled = !flashEnabled);
    } catch (e) {
      print('Error toggling flash: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (cameraController == null || !cameraController!.value.isInitialized || isCapturing) {
      return;
    }

    setState(() => isCapturing = true);

    try {
      final image = await cameraController!.takePicture();
      final file = File(image.path);
      
      final newItem = UploadedFile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'medical-scan-${DateTime.now().millisecondsSinceEpoch}.jpg',
        size: await file.length(),
        type: 'image/jpeg',
        path: file.path,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      setState(() {
        capturedItems.add(newItem);
      });
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
      final List<XFile> files = await _picker.pickMultipleMedia();
      for (var xfile in files) {
        final file = File(xfile.path);
        final isPdf = xfile.path.toLowerCase().endsWith('.pdf');
        
        // Check PDF limit
        if (isPdf && capturedItems.any((item) => item.type == 'application/pdf')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Only one PDF file is allowed. Please remove the existing PDF first.')),
            );
          }
          continue;
        }

        final newItem = UploadedFile(
          id: DateTime.now().millisecondsSinceEpoch.toString() + xfile.name,
          name: xfile.name,
          size: await file.length(),
          type: isPdf ? 'application/pdf' : 'image/jpeg',
          path: file.path,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );

        setState(() {
          capturedItems.add(newItem);
        });
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
    }
  }

  void _handleRemoveItem(String id) {
    setState(() {
      capturedItems.removeWhere((item) => item.id == id);
      if (capturedItems.isEmpty && viewMode == ViewMode.review) {
        viewMode = ViewMode.camera;
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

  void _handleProcess() {
    setState(() {
      viewMode = ViewMode.processing;
      processingProgress = 0;
      processingStatus = 'Preparing documents...';
    });

    final statuses = [
      'Preparing documents...',
      'Analyzing images...',
      'Extracting text data...',
      'Processing medical information...',
      'Generating report...',
      'Finalizing results...',
    ];

    int currentStatusIndex = 0;
    
    // Simulate processing
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        processingProgress += 2;
        
        final statusIndex = (processingProgress / 100 * statuses.length).floor();
        if (statusIndex != currentStatusIndex && statusIndex < statuses.length) {
          currentStatusIndex = statusIndex;
          processingStatus = statuses[statusIndex];
        }

        if (processingProgress >= 100) {
          timer.cancel();
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() => viewMode = ViewMode.success);
            }
          });
        }
      });
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool isSaving = false;

  Future<void> _saveFile(UploadedFile file) async {
    setState(() => isSaving = true);
    try {
      if (file.type.startsWith('image/')) {
        final hasAccess = await Gal.hasAccess();
        if (!hasAccess) {
          await Gal.requestAccess();
        }
        await Gal.putImage(file.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(LucideIcons.checkCircle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Saved ${file.name} to Gallery')),
                ],
              ),
              backgroundColor: const Color(0xFF39A4E6),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        // For PDFs, use Share which allows "Save to Files"
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Save ${file.name}',
        );
      }
    } catch (e) {
      debugPrint('Error saving file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _saveAllFiles() async {
    if (capturedItems.isEmpty) return;
    
    setState(() => isSaving = true);
    int successCount = 0;
    List<XFile> filesToShare = [];

    try {
      // Loop through items with delay to match React implementation
      for (var i = 0; i < capturedItems.length; i++) {
        var file = capturedItems[i];
        
        if (file.type.startsWith('image/')) {
          try {
            final hasAccess = await Gal.hasAccess();
            if (!hasAccess) await Gal.requestAccess();
            await Gal.putImage(file.path);
            successCount++;
          } catch (e) {
            debugPrint('Error saving image to gallery: $e');
            // Fallback to share if gallery save fails
            filesToShare.add(XFile(file.path));
          }
        } else {
          filesToShare.add(XFile(file.path));
        }

        // Add a small delay between downloads to avoid issues (matching React example)
        if (i < capturedItems.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      // If we have files to share (PDFs or failed images), share them as a batch
      if (filesToShare.isNotEmpty) {
        await Share.shareXFiles(
          filesToShare,
          text: 'Save ${filesToShare.length} files',
        );
      }

      if (successCount > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Saved $successCount images to Gallery'),
              ],
            ),
            backgroundColor: const Color(0xFF39A4E6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (viewMode) {
      case ViewMode.processing:
        return ProcessingScreen(
          isDarkMode: widget.isDarkMode,
          processingStatus: processingStatus,
          processingProgress: processingProgress,
          capturedItems: capturedItems,
        );
      case ViewMode.success:
        return SuccessScreen(
          isDarkMode: widget.isDarkMode,
          capturedItems: capturedItems,
          onClose: () => Navigator.pop(context),
          setViewMode: (mode) {
            if (mode == 'review') {
              setState(() => viewMode = ViewMode.review);
            }
          },
        );
      case ViewMode.review:
        return _buildReviewScreen();
      case ViewMode.viewer:
        return _buildViewerScreen();
      case ViewMode.camera:
      default:
        return _buildCameraScreen();
    }
  }

  Widget _buildCameraScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (showCamera && cameraController != null && cameraController!.value.isInitialized)
            Positioned.fill(child: CameraPreview(cameraController!))
          else
            _buildCameraLoading(),

          // Document Frame
          if (showCamera) _buildDocumentFrame(),

          // Flash Effect
          if (isCapturing)
            Positioned.fill(
              child: Container(color: Colors.white)
                  .animate()
                  .fadeIn(duration: 50.ms)
                  .fadeOut(duration: 300.ms),
            ),

          // Tutorial Overlay
          if (showTutorial && showCamera) _buildTutorialOverlay(),

          // Top Toolbar
          _buildTopToolbar(),

          // Bottom Controls
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildCameraLoading() {
    return Center(
      child: cameraError != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
                  ),
                  child: const Icon(LucideIcons.alertCircle, size: 48, color: Colors.red),
                ).animate().scale(),
                const SizedBox(height: 24),
                const Text(
                  'Camera Error',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    cameraError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: _initializeCamera,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF39A4E6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Color(0xFF39A4E6)),
                    strokeWidth: 4,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Starting Camera...',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
    );
  }

  Widget _buildDocumentFrame() {
    return Positioned.fill(
      child: Padding(
        padding: EdgeInsets.only(
          top: 120,
          bottom: capturedItems.isNotEmpty ? 240 : 140,
          left: 32,
          right: 32,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF39A4E6), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF39A4E6).withOpacity(0.4),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Corner Markers
              ...List.generate(4, (index) {
                final isTop = index < 2;
                final isLeft = index % 2 == 0;
                return Positioned(
                  top: isTop ? -2 : null,
                  bottom: !isTop ? -2 : null,
                  left: isLeft ? -2 : null,
                  right: !isLeft ? -2 : null,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      border: Border(
                        top: isTop ? const BorderSide(color: Color(0xFF39A4E6), width: 4) : BorderSide.none,
                        bottom: !isTop ? const BorderSide(color: Color(0xFF39A4E6), width: 4) : BorderSide.none,
                        left: isLeft ? const BorderSide(color: Color(0xFF39A4E6), width: 4) : BorderSide.none,
                        right: !isLeft ? const BorderSide(color: Color(0xFF39A4E6), width: 4) : BorderSide.none,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: isTop && isLeft ? const Radius.circular(16) : Radius.zero,
                        topRight: isTop && !isLeft ? const Radius.circular(16) : Radius.zero,
                        bottomLeft: !isTop && isLeft ? const Radius.circular(16) : Radius.zero,
                        bottomRight: !isTop && !isLeft ? const Radius.circular(16) : Radius.zero,
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
                );
              }),
            ],
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .boxShadow(
            duration: 2.seconds,
            begin: BoxShadow(
              color: const Color(0xFF39A4E6).withOpacity(0.4),
              blurRadius: 40,
              spreadRadius: 5,
            ),
            end: BoxShadow(
              color: const Color(0xFF39A4E6).withOpacity(0.6),
              blurRadius: 50,
              spreadRadius: 8,
            ),
          ),
      ),
    );
  }

  Widget _buildTopToolbar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(top: 48, bottom: 24, left: 24, right: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Icon(LucideIcons.x, color: Colors.white),
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: _toggleFlash,
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: flashEnabled ? const Color(0xFFFBBF24).withOpacity(0.9) : Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: flashEnabled ? const Color(0xFFFBBF24).withOpacity(0.5) : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Icon(
                      flashEnabled ? LucideIcons.zap : LucideIcons.zapOff,
                      color: flashEnabled ? Colors.black : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _toggleCameraLens,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF39A4E6).withOpacity(0.9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF39A4E6)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF39A4E6).withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(LucideIcons.rotateCcw, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(bottom: 40, top: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thumbnails
            if (capturedItems.isNotEmpty)
              Container(
                height: 80,
                margin: const EdgeInsets.only(bottom: 20),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: capturedItems.length,
                  itemBuilder: (context, index) {
                    final item = capturedItems[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          viewerItemIndex = index;
                          viewMode = ViewMode.viewer;
                        });
                      },
                      child: Container(
                        width: 60,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                          color: Colors.grey[900],
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: item.type.startsWith('image/')
                                  ? Image.file(File(item.path), fit: BoxFit.cover, width: 60, height: 80)
                                  : const Center(child: Icon(LucideIcons.fileText, color: Color(0xFF39A4E6))),
                            ),
                            Positioned(
                              top: -8,
                              right: -8,
                              child: GestureDetector(
                                onTap: () => _handleRemoveItem(item.id),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(LucideIcons.x, size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              left: 2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF39A4E6),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().scale(duration: 200.ms);
                  },
                ),
              ),

            // Process Button
            if (capturedItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => viewMode = ViewMode.review),
                  icon: const Icon(LucideIcons.eye),
                  label: Text('Review & Process (${capturedItems.length})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF39A4E6),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    shadowColor: const Color(0xFF39A4E6).withOpacity(0.5),
                  ),
                ),
              ).animate().slideY(begin: 0.5, end: 0),

            // Controls Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Gallery Button
                  GestureDetector(
                    onTap: _pickFiles,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: capturedItems.isNotEmpty && capturedItems.last.type.startsWith('image/')
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.file(File(capturedItems.last.path), fit: BoxFit.cover),
                            )
                          : const Icon(LucideIcons.image, color: Colors.white),
                    ),
                  ),

                  // Capture Button
                  GestureDetector(
                    onTap: _capturePhoto,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF39A4E6).withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF39A4E6), width: 4),
                          ),
                          child: isCapturing
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.05, 1.05)),
                  ),

                  // Upload Button
                  GestureDetector(
                    onTap: _pickFiles,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Icon(LucideIcons.upload, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialOverlay() {
    final step = tutorialSteps[tutorialStep];
    return Stack(
      children: [
        Container(color: Colors.black.withOpacity(0.8)),
        
        // Spotlight (Simplified implementation using positioned containers)
        // In a real app, use a CustomPainter with blend modes for a true spotlight
        
        Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF39A4E6), Color(0xFF2D7FBA)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF39A4E6).withOpacity(0.5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Icon(LucideIcons.info, color: Colors.white, size: 32),
                ).animate(onPlay: (c) => c.repeat()).rotate(duration: 2.seconds, begin: -0.05, end: 0.05),
                const SizedBox(height: 24),
                Text(
                  step['title']!,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  step['description']!,
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(tutorialSteps.length, (index) {
                    return Container(
                      width: index == tutorialStep ? 32 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index == tutorialStep ? const Color(0xFF39A4E6) : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ).animate().scale();
                  }),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _completeTutorial,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _nextTutorialStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF39A4E6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(tutorialStep < tutorialSteps.length - 1 ? 'Next' : 'Got It!'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().slideY(begin: 0.2, end: 0).fadeIn(),
        ),
      ],
    );
  }

  Widget _buildReviewScreen() {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.x, color: widget.isDarkMode ? Colors.white : Colors.black, size: 20),
          ),
          onPressed: () => setState(() => viewMode = ViewMode.camera),
        ),
        title: Column(
          children: [
            Text(
              'Review Items',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${capturedItems.length} item(s) selected',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.download, color: widget.isDarkMode ? Colors.white : Colors.black, size: 20),
            ),
            onPressed: isSaving ? null : _saveAllFiles,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: capturedItems.length + 1,
              itemBuilder: (context, index) {
                if (index == capturedItems.length) {
                  // Add More Card
                  return GestureDetector(
                    onTap: () => setState(() => viewMode = ViewMode.camera),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF39A4E6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFF39A4E6).withOpacity(0.5),
                          style: BorderStyle.solid,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFF39A4E6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.plus, color: Colors.white, size: 32),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Add More',
                            style: TextStyle(
                              color: Color(0xFF39A4E6),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().scale();
                }

                final item = capturedItems[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      viewerItemIndex = index;
                      viewMode = ViewMode.viewer;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: widget.isDarkMode ? Colors.grey[900] : Colors.white,
                      border: Border.all(
                        color: widget.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(23),
                          child: item.type.startsWith('image/')
                              ? Image.file(File(item.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(LucideIcons.fileText, size: 48, color: Color(0xFF39A4E6)),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Text(
                                          item.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: widget.isDarkMode ? Colors.white : Colors.black,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _formatFileSize(item.size),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _handleRemoveItem(item.id),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                              ),
                              child: const Icon(LucideIcons.trash2, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.isDarkMode ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: widget.isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (index * 50).ms).scale();
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white,
              border: Border(top: BorderSide(color: widget.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey[200]!)),
            ),
            child: ElevatedButton.icon(
              onPressed: _handleProcess,
              icon: const Icon(LucideIcons.send),
              label: Text('Process ${capturedItems.length} Item${capturedItems.length == 1 ? '' : 's'}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39A4E6),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                shadowColor: const Color(0xFF39A4E6).withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewerScreen() {
    final item = capturedItems[viewerItemIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.x, color: Colors.white, size: 20),
          ),
          onPressed: () => setState(() => viewMode = ViewMode.review),
        ),
        title: Column(
          children: [
            const Text('View Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(
              item.name,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.download, color: Colors.white, size: 20),
            ),
            onPressed: isSaving ? null : () => _saveFile(item),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: item.type.startsWith('image/')
                      ? Image.file(File(item.path), fit: BoxFit.contain)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.fileText, size: 80, color: Color(0xFF39A4E6)),
                            const SizedBox(height: 16),
                            Text(
                              item.name,
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              _formatFileSize(item.size),
                              style: const TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.black.withOpacity(0.8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: viewerItemIndex > 0
                      ? () => setState(() => viewerItemIndex--)
                      : null,
                  icon: Icon(
                    LucideIcons.chevronLeft,
                    color: viewerItemIndex > 0 ? Colors.white : Colors.grey,
                    size: 32,
                  ),
                ),
                Text(
                  '${viewerItemIndex + 1} / ${capturedItems.length}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: viewerItemIndex < capturedItems.length - 1
                      ? () => setState(() => viewerItemIndex++)
                      : null,
                  icon: Icon(
                    LucideIcons.chevronRight,
                    color: viewerItemIndex < capturedItems.length - 1 ? Colors.white : Colors.grey,
                    size: 32,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _handleRemoveItem(item.id);
                    if (capturedItems.isNotEmpty) {
                      setState(() {
                        if (viewerItemIndex >= capturedItems.length) {
                          viewerItemIndex = capturedItems.length - 1;
                        }
                      });
                    } else {
                      setState(() => viewMode = ViewMode.camera);
                    }
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.trash2, color: Colors.red, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
