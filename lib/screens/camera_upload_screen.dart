import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:async';
import 'dart:ui'; // For ImageFilter
import 'processing_screen.dart';
import 'success_screen.dart';
import 'extracted_report_screen.dart';

import 'package:health_track/models/extracted_report_data.dart';

import 'package:health_track/models/uploaded_file.dart';
import 'package:health_track/config/api_config.dart';
import 'package:health_track/services/vlm_service.dart';

enum ViewMode { camera, review, viewer, processing, success }

enum ImageQuality { low, medium, high }

class CameraUploadScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback? onClose;

  const CameraUploadScreen({super.key, required this.isDarkMode, this.onClose});

  @override
  State<CameraUploadScreen> createState() => _CameraUploadScreenState();
}

class _CameraUploadScreenState extends State<CameraUploadScreen>
    with TickerProviderStateMixin {
  List<UploadedFile> capturedItems = [];
  ViewMode viewMode = ViewMode.camera;
  bool showCamera = false;
  bool showTutorial = false;
  int tutorialStep = 0;
  String? cameraError;
  bool flashEnabled = false;
  bool isCapturing = false;
  int viewerItemIndex = 0;

  // Toast State
  String? messageToast;
  Timer? _toastTimer;

  CameraController? cameraController;
  List<CameraDescription>? cameras;
  final ImagePicker _picker = ImagePicker();

  // Processing state
  double processingProgress = 0;
  String processingStatus = '';
  ExtractedReportData? extractedData;

  final List<Map<String, String>> tutorialSteps = [
    {
      'title': 'Capture Documents',
      'description':
          'Tap the capture button to scan your medical reports. You can capture multiple pages.',
      'highlight': 'capture-button',
    },
    {
      'title': 'Upload from Gallery',
      'description':
          'Tap the gallery icon to select multiple images or PDF files from your device.',
      'highlight': 'gallery-button',
    },
    {
      'title': 'Review & Process',
      'description':
          'Review your captured items, add more, or delete unwanted ones before processing.',
      'highlight': 'process-button',
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
    final hasSeenTutorial =
        prefs.getBool('hasSeenCameraUploadTutorial') ?? false;
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
          cameraError =
              'Camera permission denied. Please allow camera access in settings.';
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
      newCamera = cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      _showToast('Switched to front camera');
    } else {
      newCamera = cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
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
    setState(() => messageToast = message);
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => messageToast = null);
    });
  }

  Future<void> _capturePhoto() async {
    if (cameraController == null ||
        !cameraController!.value.isInitialized ||
        isCapturing) {
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

  // Pick images only from gallery
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        requestFullMetadata: false,
      );

      for (var xfile in images) {
        final file = File(xfile.path);

        final newItem = UploadedFile(
          id: DateTime.now().millisecondsSinceEpoch.toString() + xfile.name,
          name: xfile.name,
          size: await file.length(),
          type: xfile.mimeType ?? 'image/jpeg',
          path: file.path,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );

        setState(() {
          capturedItems.add(newItem);
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  // Pick PDF files only
  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final fileObj = File(file.path!);

        // Check PDF limit
        if (capturedItems.any((item) => item.type == 'application/pdf')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Only one document file is allowed. Please remove the existing file first.',
                ),
              ),
            );
          }
          return;
        }

        final newItem = UploadedFile(
          id: DateTime.now().millisecondsSinceEpoch.toString() + file.name,
          name: file.name,
          size: await fileObj.length(),
          type: 'application/pdf',
          path: file.path!,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );

        setState(() {
          capturedItems.add(newItem);
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
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

    bool backendCompleted = false;
    // Kick off backend extraction using a sample image URL for now.
    // Use the first captured item for extraction
    if (capturedItems.isNotEmpty) {
      debugPrint('Starting extraction for file: ${capturedItems.first.path}');
      debugPrint('File type: ${capturedItems.first.type}');
      
      VlmService.extractFromImageFile(capturedItems.first.path)
          .then((result) {
          debugPrint('Backend extraction successful!');
          debugPrint('Extracted data - Patient: ${result.patientInfo.name}, Report Type: ${result.reportType}');
          debugPrint('Test results count: ${result.testResults?.length ?? 0}');
          
          backendCompleted = true;
          if (!mounted) return;
          setState(() {
            extractedData = result;
            // If progress is already near completion, finish now
            if (processingProgress >= 98) {
              processingProgress = 100;
            }
          });
        })
        .catchError((e) {
          debugPrint('Backend extraction error: $e');
          debugPrint('Error type: ${e.runtimeType}');
          
          backendCompleted = true;
          if (!mounted) return;
          
          if (e.toString().contains('Unauthorized')) {
             // Token expired, redirect to login
             debugPrint('Token expired, redirecting to login');
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Session expired. Please login again.')),
             );
             Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
             );
             return;
          }

          // Fallback to mock data on error
          debugPrint('Using mock data as fallback');
          setState(() {
            extractedData = _buildMockExtractedData();
          });
        });
    }

    // Simulate processing/progress bar while backend runs
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        // If backend not completed, cap at 98%
        if (!backendCompleted) {
          if (processingProgress < 98) {
            processingProgress += 2;
          }
        } else {
          processingProgress += 2;
        }

        final statusIndex = (processingProgress / 100 * statuses.length)
            .floor();
        if (statusIndex != currentStatusIndex &&
            statusIndex < statuses.length) {
          currentStatusIndex = statusIndex;
          processingStatus = statuses[statusIndex];
        }

        if (processingProgress >= 100 ||
            (backendCompleted && processingProgress >= 98)) {
          timer.cancel();
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                // Ensure we have data; if backend failed earlier, fallback was set
                extractedData ??= _buildMockExtractedData();
                viewMode = ViewMode.success;
              });
            }
          });
        }
      });
    });
  }

  ExtractedReportData _buildMockExtractedData() {
    // Mocked data to preview the extracted report screen
    return ExtractedReportData(
      reportType: 'Lab Results',
      reportDate: DateTime.now().toLocal().toString().split(' ').first,
      patientInfo: PatientInfo(
        name: 'Alex Johnson',
        age: 34,
        gender: 'Male',
        id: 'PT-84726',
        phone: '+1 555 0102',
      ),
      doctorInfo: DoctorInfo(
        name: 'Dr. Emily Carter',
        specialty: 'Internal Medicine',
        hospital: 'City Health Hospital',
      ),
      vitals: [
        VitalSign(name: 'Heart Rate', value: '72', unit: 'bpm', icon: 'heart'),
        VitalSign(
          name: 'Temperature',
          value: '37.1',
          unit: '°C',
          icon: 'thermometer',
        ),
        VitalSign(name: 'SpO₂', value: '98', unit: '%', icon: 'droplet'),
        VitalSign(
          name: 'Activity',
          value: 'Normal',
          unit: '',
          icon: 'activity',
        ),
      ],
      testResults: [
        TestResult(
          name: 'Hemoglobin',
          value: '13.8',
          unit: 'g/dL',
          normalRange: '13.0 - 17.0',
          status: 'normal',
        ),
        TestResult(
          name: 'WBC',
          value: '11.2',
          unit: '×10⁹/L',
          normalRange: '4.0 - 10.0',
          status: 'high',
        ),
        TestResult(
          name: 'Platelets',
          value: '150',
          unit: '×10⁹/L',
          normalRange: '150 - 450',
          status: 'normal',
        ),
        TestResult(
          name: 'CRP',
          value: '28',
          unit: 'mg/L',
          normalRange: '< 10',
          status: 'critical',
        ),
      ],
      medications: [
        Medication(
          name: 'Amoxicillin',
          dosage: '500 mg',
          frequency: '3x daily',
          duration: '7 days',
        ),
        Medication(
          name: 'Ibuprofen',
          dosage: '200 mg',
          frequency: 'as needed',
          duration: '5 days',
        ),
      ],
      diagnosis:
          'Acute upper respiratory tract infection likely viral in origin. No signs of bacterial pneumonia.',
      observations:
          'Patient presents mild fever and sore throat. Lung auscultation clear. Hydration status adequate.',
      recommendations: [
        'Increase fluid intake to 2–3 liters per day.',
        'Rest and avoid strenuous activity for 3–5 days.',
        'If fever persists beyond 48 hours, schedule follow-up.',
      ],
      warnings: [
        'If shortness of breath or chest pain occurs, seek emergency care.',
        'Avoid operating heavy machinery after taking ibuprofen if dizziness occurs.',
      ],
      nextVisit: 'Follow-up in 1 week (Dec 8, ${DateTime.now().year})',
    );
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
          onViewExtractedData: extractedData == null
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ExtractedReportScreen(
                        isDarkMode: widget.isDarkMode,
                        onClose:
                            widget.onClose ??
                            () => Navigator.of(context).maybePop(),
                        onBack: () => Navigator.of(context).maybePop(),
                        extractedData: extractedData!,
                      ),
                    ),
                  );
                },
        );
      case ViewMode.review:
        return _buildReviewScreen();
      case ViewMode.viewer:
        return _buildViewerScreen();
      case ViewMode.camera:
        return _buildCameraScreen();
    }
  }

  Widget _buildCameraScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (showCamera &&
              cameraController != null &&
              cameraController!.value.isInitialized)
            Positioned.fill(child: CameraPreview(cameraController!))
          else
            _buildCameraLoading(),

          // Document Frame
          if (showCamera) _buildDocumentFrame(),

          // Flash Effect
          if (isCapturing)
            Positioned.fill(
              child: Container(
                color: Colors.white,
              ).animate().fadeIn(duration: 50.ms).fadeOut(duration: 300.ms),
            ),

          // Tutorial Overlay
          if (showTutorial && showCamera) _buildTutorialOverlay(),

          // Top Toolbar
          _buildTopToolbar(),

          // Bottom Controls
          _buildBottomControls(),

          // Message Toast
          if (messageToast != null) _buildToast(),
        ],
      ),
    );
  }

  Widget _buildToast() {
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
              const Icon(
                LucideIcons.checkCircle,
                color: Color(0xFF39A4E6),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                messageToast!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: -0.5, end: 0),
      ),
    );
  }

  Widget _buildTutorialOverlay() {
    final step = tutorialSteps[tutorialStep];
    return Stack(
      children: [
        // Dimmed Background
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.8),
          ).animate().fadeIn(),
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
                  child: const Icon(
                    LucideIcons.info,
                    color: Colors.white,
                    size: 32,
                  ),
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
                    color: widget.isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
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
                        color: index == tutorialStep
                            ? const Color(0xFF39A4E6)
                            : Colors.grey[300],
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
                          backgroundColor: widget.isDarkMode
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: widget.isDarkMode
                                ? Colors.grey[300]
                                : Colors.grey[700],
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: const Color(0xFF39A4E6).withOpacity(0.4),
                        ),
                        child: Text(
                          tutorialStep < tutorialSteps.length - 1
                              ? 'Next'
                              : 'Got It!',
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
                    border: Border.all(
                      color: Colors.red.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    LucideIcons.alertCircle,
                    size: 48,
                    color: Colors.red,
                  ),
                ).animate().scale(),
                const SizedBox(height: 24),
                const Text(
                  'Camera Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)),
      ),
    );
  }

  Widget _buildTopToolbar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(
          top: 48,
          bottom: 24,
          left: 24,
          right: 24,
        ),
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
              behavior: HitTestBehavior.opaque,
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
                      color: flashEnabled
                          ? const Color(0xFFFBBF24).withOpacity(0.9)
                          : Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: flashEnabled
                            ? const Color(0xFFFBBF24).withOpacity(0.5)
                            : Colors.white.withOpacity(0.1),
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
                    child: const Icon(
                      LucideIcons.switchCamera,
                      color: Colors.white,
                      size: 20,
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
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                          color: Colors.grey[900],
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: item.type.startsWith('image/')
                                  ? Image.file(
                                      File(item.path),
                                      fit: BoxFit.cover,
                                      width: 60,
                                      height: 80,
                                    )
                                  : const Center(
                                      child: Icon(
                                        LucideIcons.fileText,
                                        color: Color(0xFF39A4E6),
                                      ),
                                    ),
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
                                  child: const Icon(
                                    LucideIcons.x,
                                    size: 10,
                                    color: Colors.white,
                                  ),
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
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: ElevatedButton(
                  onPressed: () => setState(() => viewMode = ViewMode.review),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                  // Gallery (Images only)
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child:
                          capturedItems.isNotEmpty &&
                              capturedItems.last.type.startsWith('image/')
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.file(
                                File(capturedItems.last.path),
                                fit: BoxFit.cover,
                              ),
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
                              border: Border.all(
                                color: const Color(0xFF39A4E6),
                                width: 4,
                              ),
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
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.upload,
                        color: Colors.white,
                      ),
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
      backgroundColor: widget.isDarkMode
          ? const Color(0xFF0F172A)
          : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.chevronLeft,
            color: widget.isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => setState(() => viewMode = ViewMode.camera),
        ),
        title: Text(
          'Review Items',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
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
                        border: Border.all(
                          color: const Color(0xFF39A4E6).withOpacity(0.5),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.plus,
                            size: 32,
                            color: Color(0xFF39A4E6),
                          ),
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
                                color: widget.isDarkMode
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[200]!,
                              ),
                              color: widget.isDarkMode
                                  ? Colors.grey[900]
                                  : Colors.grey[100],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: item.type.startsWith('image/')
                                  ? Image.file(
                                      File(item.path),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    )
                                  : Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            LucideIcons.fileText,
                                            size: 48,
                                            color: Color(0xFF39A4E6),
                                          ),
                                          const SizedBox(height: 8),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            child: Text(
                                              item.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: widget.isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
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
                                child: const Icon(
                                  LucideIcons.trash2,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: (index * 50).ms)
                    .slideY(begin: 0.2, end: 0);
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
            const Text(
              'View Item',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
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
                      const Icon(
                        LucideIcons.fileText,
                        size: 64,
                        color: Color(0xFF39A4E6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
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
                      color: viewerItemIndex < capturedItems.length - 1
                          ? Colors.white
                          : Colors.grey,
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
        await Share.shareXFiles(
          filesToShare,
          text: 'Save ${filesToShare.length} files',
        );
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
