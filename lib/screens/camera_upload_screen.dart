import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediScan/services/document_scanner_service.dart';
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

import 'package:mediScan/models/extracted_report_data.dart';

import 'package:mediScan/models/uploaded_file.dart';
import 'package:mediScan/config/api_config.dart';
import 'package:mediScan/services/vlm_service.dart';

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
  int viewerItemIndex = 0;

  // Toast State
  String? messageToast;
  Timer? _toastTimer;

  final DocumentScannerService _scannerService = DocumentScannerService();
  final ImagePicker _picker = ImagePicker();

  // Processing state
  double processingProgress = 0;
  String processingStatus = '';
  ExtractedReportData? extractedData;



  @override
  void initState() {
    super.initState();
    // _initializeCamera(); // Removed for native scanner
    // _checkTutorial(); // Removed tutorial
  }

  @override
  void dispose() {
    // cameraController?.dispose();
    _toastTimer?.cancel();
    super.dispose();
  }



  Future<void> _launchScanner() async {
    if (capturedItems.any((item) => item.type == 'application/pdf')) {
      _showToast('Cannot add images when a PDF is selected');
      return;
    }

    try {
      final pictures = await _scannerService.scanDocument();
      if (pictures.isEmpty) return;

      for (var path in pictures) {
        final file = File(path);
        // Ensure path is valid and file exists
        if (!await file.exists()) continue;

        final newItem = UploadedFile(
          id: DateTime.now().millisecondsSinceEpoch.toString() + path,
          name: 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg',
          size: await file.length(),
          type: 'image/jpeg',
          path: path,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );

        setState(() {
          capturedItems.add(newItem);
        });
      }
      
      // If we captured something, we might want to switch to review mode or stay to capture more?
      // Usually scanners allow batch, so we might have multiple.
      // Let's show a toast.
      if (pictures.isNotEmpty) {
        _showToast('Added ${pictures.length} pages');
      }

    } catch (e) {
      debugPrint('Error launching scanner: $e');
      _showToast('Failed to launch scanner');
    }
  }

  // Pick images only from gallery
  Future<void> _pickImages() async {
    if (capturedItems.any((item) => item.type == 'application/pdf')) {
      _showToast('Cannot add images when a PDF is selected');
      return;
    }
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
    // If we already have ANY items (Images or PDF), and we try to pick a PDF...
    // The requirement says "either images or just ONE pdf".
    // So if I have images, I can't pick PDF.
    // If I have PDF, I can't pick another PDF.

    if (capturedItems.isNotEmpty) {
       // If existing items are images, we can't add PDF.
       // If existing item is PDF, we can't add another PDF.
       // So basically if list is not empty, we can't add a PDF.
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text(
               'You can only upload one PDF file OR multiple images. Please clear existing items to upload a PDF.',
             ),
           ),
         );
       }
       return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final fileObj = File(file.path!);

        // Double check (redundant but safe)
        if (capturedItems.isNotEmpty) {
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



  void _handleProcess() {
    setState(() {
      viewMode = ViewMode.processing;
      processingProgress = 0;
      processingStatus = 'Preparing documents...';
    });

    // Backend doesn't support streaming yet, use regular upload with simulated progress
    if (capturedItems.isNotEmpty) {
      debugPrint('Starting extraction for file: ${capturedItems.first.path}');
      
      // Simulate progress while backend processes
      Timer.periodic(const Duration(milliseconds: 200), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        
        setState(() {
          if (processingProgress < 90) {
            processingProgress += 3;
            
            // Update status based on progress
            if (processingProgress < 20) {
              processingStatus = 'Uploading document...';
            } else if (processingProgress < 40) {
              processingStatus = 'Analyzing images...';
            } else if (processingProgress < 60) {
              processingStatus = 'Extracting text data...';
            } else if (processingProgress < 80) {
              processingStatus = 'Processing medical information...';
            } else {
              processingStatus = 'Generating report...';
            }
          }
        });
      });
      
      // Call backend
      VlmService.extractFromImages(capturedItems.map((e) => e.path).toList())
          .then((result) {
        debugPrint('Backend extraction successful!');
        if (!mounted) return;
        
        setState(() {
          extractedData = result;
          processingProgress = 100;
          processingStatus = 'Complete!';
        });
        
        // Wait a moment then show success
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              viewMode = ViewMode.success;
            });
          }
        });
      }).catchError((e) {
        debugPrint('Backend extraction error: $e');
        if (!mounted) return;
        
        // Check for duplicate report
        if (e.toString().contains('DUPLICATE_REPORT')) {
          setState(() {
            processingProgress = 0;
            viewMode = ViewMode.review;
          });
          
          // Show modern duplicate report dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF39A4E6).withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Primary blue header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF39A4E6),
                            const Color(0xFF2B8FD9),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              LucideIcons.copy,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Duplicate Detected',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This report already exists',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'We found an identical report in your account. Would you like to view it instead?',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      viewMode = ViewMode.camera;
                                      capturedItems.clear();
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: BorderSide(
                                      color: widget.isDarkMode 
                                          ? Colors.grey[700]! 
                                          : Colors.grey[300]!,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Go Back',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    // Navigate to the existing report
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Row(
                                          children: [
                                            Icon(LucideIcons.fileText, color: Colors.white, size: 20),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Navigating to existing report...',
                                                style: TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: const Color(0xFF39A4E6),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                    
                                    // Pop all screens until we reach home, then the home screen will show reports tab
                                    Navigator.of(context).popUntil((route) => route.isFirst);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF39A4E6),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(LucideIcons.eye, size: 18),
                                  label: const Text(
                                    'View Report',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          return;
        }
        
        if (e.toString().contains('Unauthorized')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expired. Please login again.')),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Processing failed: $e')),
          );
          setState(() {
            viewMode = ViewMode.review;
            processingProgress = 0;
          });
        }
      });
    }
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
                  final data = extractedData!;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (navContext) => ExtractedReportScreen(
                        isDarkMode: widget.isDarkMode,
                        onClose: () {
                          // Pop the ExtractedReportScreen
                          Navigator.of(navContext).pop();
                          // Then execute the parent's onClose if provided
                          if (widget.onClose != null) {
                            widget.onClose!();
                          } else {
                            // Pop the camera upload screen as well
                            Navigator.of(context).maybePop();
                          }
                        },
                        onBack: () {
                          // Just pop the ExtractedReportScreen to go back to success screen
                          Navigator.of(navContext).pop();
                        },
                        extractedData: data,
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

  Widget _buildTopToolbar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              // Empty Container to balance the row if needed, or other icons
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background/Prompt
          Center(
             child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(LucideIcons.scanLine, size: 80, color: Colors.white.withOpacity(0.5)),
                   const SizedBox(height: 16),
                   Text("Tap the capture button to start scanning", style: TextStyle(color: Colors.white.withOpacity(0.5))),
                ],
             ),
          ),

          // Top Toolbar (Close button only)
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

  void _showToast(String message) {
    setState(() {
      messageToast = message;
    });
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          messageToast = null;
        });
      }
    });
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
                    onTap: _launchScanner,
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
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF39A4E6),
                              width: 4,
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.scanLine,
                            color: Color(0xFF39A4E6),
                            size: 32,
                          ),
                        ),
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
