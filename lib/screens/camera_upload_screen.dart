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
import 'dart:ui'; // For ImageFilter
import 'processing_screen.dart';
import 'success_screen.dart';

import 'package:health_track/models/uploaded_file.dart';

enum ViewMode { camera, review, viewer, processing, success }
enum ImageQuality { low, medium, high }

class CameraUploadScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback? onClose;

  const CameraUploadScreen({super.key, required this.isDarkMode, this.onClose});

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
  
  // New State Variables
  bool showSettings = false;
  bool gridEnabled = false;
  ImageQuality imageQuality = ImageQuality.high;
  String? settingsToast;
  Timer? _toastTimer;

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
      'description': 'Access flash, grid lines, camera direction, and quality settings from the toolbar.',
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
    _toastTimer?.cancel();
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
      _showToast('Switched to front camera');
    } else {
      newCamera = cameras!.firstWhere((c) => c.lensDirection == CameraLensDirection.back);
      _showToast('Switched to back camera');
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
        _showToast('Flash disabled');
      } else {
        await cameraController!.setFlashMode(FlashMode.torch);
        _showToast('Flash enabled');
      }
      setState(() => flashEnabled = !flashEnabled);
    } catch (e) {
      print('Error toggling flash: $e');
    }
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() => settingsToast = message);
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => settingsToast = null);
    });
  }

  Future<void> _capturePhoto() async {
    if (cameraController == null || !cameraController!.value.isInitialized || isCapturing) {
      return;
    }

    setState(() => isCapturing = true);

    try {
      final image = await cameraController!.takePicture();
      final file = File(image.path);
      
      // Simulate quality adjustment (in real app, use flutter_image_compress)
      // For now, we just use the file as is
      
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
          onClose: widget.onClose ?? () => Navigator.of(context).maybePop(),
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

          // Grid Overlay
          if (gridEnabled) _buildGridOverlay(),

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

          // Settings Panel
          if (showSettings) _buildSettingsPanel(),

          // Top Toolbar
          _buildTopToolbar(),

          // Bottom Controls
          _buildBottomControls(),

          // Settings Toast
          if (settingsToast != null) _buildSettingsToast(),
        ],
      ),
    );
  }

  Widget _buildSettingsToast() {
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.checkCircle, color: Color(0xFF39A4E6), size: 20),
              const SizedBox(width: 8),
              Text(
                settingsToast!,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: -0.5, end: 0),
      ),
    );
  }

  Widget _buildGridOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Vertical Lines
            Row(
              children: [
                const Spacer(),
                Container(width: 1, color: Colors.white.withOpacity(0.3)),
                const Spacer(),
                Container(width: 1, color: Colors.white.withOpacity(0.3)),
                const Spacer(),
              ],
            ),
            // Horizontal Lines
            Column(
              children: [
                const Spacer(),
                Container(height: 1, color: Colors.white.withOpacity(0.3)),
                const Spacer(),
                Container(height: 1, color: Colors.white.withOpacity(0.3)),
                const Spacer(),
              ],
            ),
          ],
        ).animate().fadeIn(),
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return GestureDetector(
      onTap: () => setState(() => showSettings = false),
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping panel
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF111827), Colors.black],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 16),
                        width: 48,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Camera Settings',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Customize your camera experience',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => setState(() => showSettings = false),
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white12),
                    
                    // Settings Content
                    SizedBox(
                      height: 400,
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          // Flash
                          _buildSettingItem(
                            icon: flashEnabled ? LucideIcons.zap : LucideIcons.zapOff,
                            iconColor: flashEnabled ? Colors.yellow : Colors.grey,
                            title: 'Flash',
                            subtitle: flashEnabled ? 'Enabled' : 'Disabled',
                            trailing: Switch(
                              value: flashEnabled,
                              onChanged: (_) => _toggleFlash(),
                              activeColor: Colors.yellow,
                              activeTrackColor: Colors.yellow.withOpacity(0.3),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Grid
                          _buildSettingItem(
                            icon: LucideIcons.grid,
                            iconColor: gridEnabled ? const Color(0xFF39A4E6) : Colors.grey,
                            title: 'Grid Lines',
                            subtitle: gridEnabled ? 'Showing' : 'Hidden',
                            trailing: Switch(
                              value: gridEnabled,
                              onChanged: (val) {
                                setState(() => gridEnabled = val);
                                _showToast(val ? 'Grid lines enabled' : 'Grid lines disabled');
                              },
                              activeColor: const Color(0xFF39A4E6),
                              activeTrackColor: const Color(0xFF39A4E6).withOpacity(0.3),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Camera Direction
                          _buildSettingItem(
                            icon: LucideIcons.switchCamera,
                            iconColor: const Color(0xFF39A4E6),
                            title: 'Camera',
                            subtitle: cameraController?.description.lensDirection == CameraLensDirection.back
                                ? 'Back Camera'
                                : 'Front Camera',
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildDirectionButton('Back', CameraLensDirection.back),
                                const SizedBox(width: 8),
                                _buildDirectionButton('Front', CameraLensDirection.front),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Quality
                          _buildSettingItem(
                            icon: LucideIcons.sparkles,
                            iconColor: Colors.purpleAccent,
                            title: 'Image Quality',
                            subtitle: '${imageQuality.name[0].toUpperCase()}${imageQuality.name.substring(1)} quality',
                            trailing: Container(), // Custom layout below
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: ImageQuality.values.map((q) {
                              final isSelected = imageQuality == q;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => imageQuality = q);
                                    _showToast('Quality set to ${q.name}');
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.purpleAccent : Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? Colors.purpleAccent : Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (isSelected)
                                          const Padding(
                                            padding: EdgeInsets.only(right: 4),
                                            child: Icon(LucideIcons.check, size: 14, color: Colors.white),
                                          ),
                                        Text(
                                          '${q.name[0].toUpperCase()}${q.name.substring(1)}',
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.grey,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          
                          const SizedBox(height: 24),
                          // Tips
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF39A4E6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF39A4E6).withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.info, color: Color(0xFF39A4E6), size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Tips for Best Results',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '• Use good lighting\n• Keep documents flat\n• High quality recommended',
                                        style: TextStyle(
                                          color: Colors.grey[300],
                                          fontSize: 12,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 1, end: 0, curve: Curves.easeOutQuart, duration: 400.ms);
  }

  Widget _buildDirectionButton(String label, CameraLensDirection dir) {
    final isSelected = cameraController?.description.lensDirection == dir;
    return GestureDetector(
      onTap: () {
        if (!isSelected) _toggleCameraLens();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF39A4E6) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildTutorialOverlay() {
    final step = tutorialSteps[tutorialStep];
    return Stack(
      children: [
        // Dimmed Background
        Positioned.fill(
          child: Container(color: Colors.black.withOpacity(0.8))
              .animate()
              .fadeIn(),
        ),
        
        // Spotlight (Simplified implementation using positioned holes or just overlay logic)
        // For simplicity in Flutter, we'll just highlight the area with a border/glow
        
        // Tutorial Card
        Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF39A4E6).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(LucideIcons.info, color: Colors.white, size: 32),
                ).animate(onPlay: (c) => c.repeat()).shake(delay: 2.seconds),
                const SizedBox(height: 24),
                Text(
                  step['title']!,
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  step['description']!,
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(tutorialSteps.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: index == tutorialStep ? 32 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index == tutorialStep ? const Color(0xFF39A4E6) : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _completeTutorial,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: widget.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _nextTutorialStep,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF39A4E6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: const Color(0xFF39A4E6).withOpacity(0.4),
                        ),
                        child: Text(
                          tutorialStep < tutorialSteps.length - 1 ? 'Next' : 'Got It!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        ),
      ],
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
              onTap: widget.onClose ?? () => Navigator.of(context).maybePop(),
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
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Icon(LucideIcons.switchCamera, color: Colors.white, size: 20),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => showSettings = true),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: showSettings ? const Color(0xFF39A4E6) : Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: showSettings ? const Color(0xFF39A4E6) : Colors.white.withOpacity(0.1),
                      ),
                      boxShadow: showSettings ? [
                        BoxShadow(
                          color: const Color(0xFF39A4E6).withOpacity(0.5),
                          blurRadius: 10,
                        )
                      ] : [],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(LucideIcons.settings, color: Colors.white, size: 20),
                        if ((gridEnabled || imageQuality != ImageQuality.high) && !showSettings)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF39A4E6),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
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
                              top: -6,
                              right: -6,
                              child: GestureDetector(
                                onTap: () => _handleRemoveItem(item.id),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(LucideIcons.x, size: 10, color: Colors.white),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF39A4E6),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn().slideX(begin: 0.5, end: 0);
                  },
                ),
              ),

            // Process Button
            if (capturedItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: ElevatedButton(
                  onPressed: () => setState(() => viewMode = ViewMode.review),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    shadowColor: const Color(0xFF39A4E6).withOpacity(0.5),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.eye, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Review & Process (${capturedItems.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: 0.5, end: 0),
              ),

            // Controls Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Gallery
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
                            color: const Color(0xFF39A4E6).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF39A4E6), width: 4),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isCapturing ? 40 : 60,
                            height: isCapturing ? 40 : 60,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Upload Button (Same as gallery for now, or could be file picker)
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

  Widget _buildReviewScreen() {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: widget.isDarkMode ? Colors.white : Colors.black),
          onPressed: () => setState(() => viewMode = ViewMode.camera),
        ),
        title: Text(
          'Review Items',
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.download, color: Color(0xFF39A4E6)),
            onPressed: _saveAllFiles,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
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
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF39A4E6).withOpacity(0.5), style: BorderStyle.solid),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.plus, size: 32, color: Color(0xFF39A4E6)),
                          SizedBox(height: 8),
                          Text(
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
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: widget.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
                          ),
                          color: widget.isDarkMode ? Colors.grey[900] : Colors.grey[100],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: item.type.startsWith('image/')
                              ? Image.file(File(item.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(LucideIcons.fileText, size: 48, color: Color(0xFF39A4E6)),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          item.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: widget.isDarkMode ? Colors.white : Colors.black,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _handleRemoveItem(item.id),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.trash2, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.2, end: 0);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: _handleProcess,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                shadowColor: const Color(0xFF39A4E6).withOpacity(0.5),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.send, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Process ${capturedItems.length} Items',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
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
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => setState(() => viewMode = ViewMode.review),
        ),
        title: Column(
          children: [
            const Text('View Item', style: TextStyle(color: Colors.white, fontSize: 16)),
            Text(
              item.name,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.download),
            onPressed: () => _saveFile(item),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: item.type.startsWith('image/')
                ? Image.file(File(item.path))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.fileText, size: 64, color: Color(0xFF39A4E6)),
                      const SizedBox(height: 16),
                      Text(
                        item.name,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      Text(
                        _formatFileSize(item.size),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withOpacity(0.8),
              padding: const EdgeInsets.all(24),
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
                    ),
                  ),
                  Text(
                    '${viewerItemIndex + 1} / ${capturedItems.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  IconButton(
                    onPressed: viewerItemIndex < capturedItems.length - 1
                        ? () => setState(() => viewerItemIndex++)
                        : null,
                    icon: Icon(
                      LucideIcons.chevronRight,
                      color: viewerItemIndex < capturedItems.length - 1 ? Colors.white : Colors.grey,
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

  // ... Helper methods for saving files ...
  Future<void> _saveFile(UploadedFile file) async {
    try {
      if (file.type.startsWith('image/')) {
        final hasAccess = await Gal.hasAccess();
        if (!hasAccess) await Gal.requestAccess();
        await Gal.putImage(file.path);
        _showToast('Saved to Gallery');
      } else {
        await Share.shareXFiles([XFile(file.path)], text: 'Save ${file.name}');
      }
    } catch (e) {
      debugPrint('Error saving file: $e');
      _showToast('Error saving file');
    }
  }

  Future<void> _saveAllFiles() async {
    if (capturedItems.isEmpty) return;
    
    int successCount = 0;
    List<XFile> filesToShare = [];

    try {
      for (var i = 0; i < capturedItems.length; i++) {
        var file = capturedItems[i];
        if (file.type.startsWith('image/')) {
          try {
            final hasAccess = await Gal.hasAccess();
            if (!hasAccess) await Gal.requestAccess();
            await Gal.putImage(file.path);
            successCount++;
          } catch (e) {
            filesToShare.add(XFile(file.path));
          }
        } else {
          filesToShare.add(XFile(file.path));
        }
        if (i < capturedItems.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (filesToShare.isNotEmpty) {
        await Share.shareXFiles(filesToShare, text: 'Save ${filesToShare.length} files');
      }

      if (successCount > 0) {
        _showToast('Saved $successCount images to Gallery');
      }
    } catch (e) {
      debugPrint('Error saving files: $e');
      _showToast('Error saving files');
    }
  }
}
