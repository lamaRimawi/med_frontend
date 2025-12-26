import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/document_scanner_service.dart';

import '../models/patient_data.dart';
import '../widgets/medical_background.dart';

class AddRecordScreen extends StatefulWidget {
  final VoidCallback onBack;
  final void Function(PatientData) onSave;

  const AddRecordScreen({
    super.key,
    required this.onBack,
    required this.onSave,
  });

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  String _gender = "Female";
  int _age = 26;
  int _weight = 75;
  int _height = 178;
  String _bloodType = "AB+";
  
  String? _scanPdfPath;
  final _scannerService = DocumentScannerService();

  Future<void> _scanDocument() async {
    final images = await _scannerService.scanDocument();
    if (images.isNotEmpty) {
      final pdfPath = await _scannerService.generatePdf(images);
      if (pdfPath != null) {
        setState(() {
          _scanPdfPath = pdfPath;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(LucideIcons.checkCircle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Document scanned successfully',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              elevation: 8,
            ),
          );
        }
      }
    }
  }

  void _viewDocument() {
    if (_scanPdfPath != null) {
      _scannerService.openFile(_scanPdfPath!);
    }
  }

  final List<String> _bloodTypes = const [
    "A+",
    "A-",
    "B+",
    "B-",
    "AB+",
    "AB-",
    "O+",
    "O-",
  ];

  void _handleSave() {
    widget.onSave(
      PatientData(
        gender: _gender,
        age: _age,
        weight: _weight,
        height: _height,
        bloodType: _bloodType,
      ),
    );
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: Stack(
        children: [
          const MedicalBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('What is your gender', isDark),
                        const SizedBox(height: 12),
                        Row(
                          children: ["Male", "Female", "Other"].map((gender) {
                            final selected = _gender == gender;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    gradient: selected
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF39A4E6),
                                              Color(0xFF2B8FD9),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          )
                                        : null,
                                    color: selected
                                        ? null
                                        : (isDark
                                            ? const Color(0xFF1E1E1E)
                                            : Colors.white),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: const Color(0xFF39A4E6),
                                    ),
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF39A4E6,
                                              ).withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 8),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(30),
                                      onTap: () =>
                                          setState(() => _gender = gender),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        child: Center(
                                          child: Text(
                                            gender,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: selected
                                                  ? Colors.white
                                                  : const Color(0xFF39A4E6),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                        _buildSliderSection(
                          label: 'How old are you',
                          minLabel: '0',
                          maxLabel: '100',
                          displayValue: '$_age years',
                          value: _age.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 100,
                          onChanged: (value) =>
                              setState(() => _age = value.round()),
                        ),
                        const SizedBox(height: 32),
                        _buildSliderSection(
                          label: 'What is your weight',
                          minLabel: '0',
                          maxLabel: '200',
                          displayValue: '$_weight kg',
                          value: _weight.toDouble(),
                          min: 0,
                          max: 200,
                          divisions: 200,
                          onChanged: (value) =>
                              setState(() => _weight = value.round()),
                        ),
                        const SizedBox(height: 32),
                        _buildSliderSection(
                          label: 'What is your height',
                          minLabel: '0',
                          maxLabel: '250',
                          displayValue: '$_height cm',
                          value: _height.toDouble(),
                          min: 0,
                          max: 250,
                          divisions: 250,
                          onChanged: (value) =>
                              setState(() => _height = value.round()),
                        ),
                        const SizedBox(height: 32),
                        _buildSectionTitle('What is your blood type', isDark),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.6,
                              ),
                          itemCount: _bloodTypes.length,
                          itemBuilder: (context, index) {
                            final type = _bloodTypes[index];
                            final selected = _bloodType == type;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                gradient: selected
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF39A4E6),
                                          Color(0xFF2B8FD9),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      )
                                    : null,
                                color: selected
                                    ? null
                                    : (isDark
                                        ? const Color(0xFF1E1E1E)
                                        : const Color(0xFFE9F6FE)),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF39A4E6,
                                          ).withOpacity(0.25),
                                          blurRadius: 10,
                                          offset: const Offset(0, 6),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () =>
                                      setState(() => _bloodType = type),
                                  child: Center(
                                    child: Text(
                                      type,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? Colors.white
                                            : const Color(0xFF39A4E6),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        
                        const SizedBox(height: 32),
                        
                        _buildSectionTitle('Medical Document', isDark),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E1E)
                                : const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFF39A4E6).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: _scanPdfPath == null ? _scanDocument : _viewDocument,
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: [
                                  Icon(
                                    _scanPdfPath == null ? LucideIcons.scanLine : LucideIcons.fileCheck,
                                    size: 32,
                                    color: const Color(0xFF39A4E6),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _scanPdfPath == null ? 'Scan Document' : 'View Scanned PDF',
                                    style: const TextStyle(
                                      color: Color(0xFF39A4E6),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (_scanPdfPath != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap to open • Long press to rescan',
                                      style: TextStyle(
                                        color: const Color(0xFF39A4E6).withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            onLongPress: _scanPdfPath != null ? _scanDocument : null,
                          ),
                        ),

                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                              backgroundColor: const Color(0xFF39A4E6),
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              shadowColor: const Color(
                                0xFF39A4E6,
                              ).withOpacity(0.4),
                              elevation: 8,
                            ),
                            onPressed: _handleSave,
                            child: const Text('Save Record'),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
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

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : null,
        gradient: isDark
            ? null
            : const LinearGradient(
                colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(
                  LucideIcons.chevronLeft,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Expanded(
                child: Text(
                  'Add Record',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildSliderSection({
    required String label,
    required String minLabel,
    required String maxLabel,
    required String displayValue,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(label, isDark),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
            overlayShape: SliderComponentShape.noOverlay,
            thumbColor: Colors.white,
            activeTrackColor: const Color(0xFF39A4E6),
            inactiveTrackColor:
                isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE9F6FE),
            valueIndicatorTextStyle: const TextStyle(color: Color(0xFF39A4E6)),
          ),
          child: Slider(
            min: min,
            max: max,
            divisions: divisions,
            value: value,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(minLabel, style: const TextStyle(color: Colors.grey)),
            Text(
              displayValue,
              style: const TextStyle(
                color: Color(0xFF39A4E6),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            Text(maxLabel, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}
