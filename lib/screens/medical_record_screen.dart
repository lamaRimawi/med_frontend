import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../widgets/medical_background.dart';
import '../widgets/theme_toggle.dart';
import '../models/patient_data.dart';
import 'add_record_screen.dart';
import 'allergies_screen.dart';
import 'analysis_detail_screen.dart';
import 'analysis_screen.dart';
import 'medical_history_screen.dart';
import 'vaccinations_screen.dart';

class MedicalRecordScreen extends StatefulWidget {
  final VoidCallback onBack;

  const MedicalRecordScreen({super.key, required this.onBack});

  @override
  State<MedicalRecordScreen> createState() => _MedicalRecordScreenState();
}

class _MedicalRecordScreenState extends State<MedicalRecordScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool get _isDarkMode =>
      ThemeProvider.of(context)?.themeMode == ThemeMode.dark ?? false;

  PatientData _patient = const PatientData(
    gender: 'Female',
    age: 26,
    weight: 65,
    height: 170,
    bloodType: 'AB +',
  );

  final List<_MedicalCategory> _categories = const [
    _MedicalCategory(
      label: 'Allergies',
      icon: LucideIcons.alertCircle,
      colors: [Color(0xFF39A4E6), Color(0xFF5BB5ED)],
      type: MedicalCategoryType.allergies,
    ),
    _MedicalCategory(
      label: 'Analysis',
      icon: LucideIcons.activity,
      colors: [Color(0xFF39A4E6), Color(0xFF5BB5ED)],
      type: MedicalCategoryType.analysis,
    ),
    _MedicalCategory(
      label: 'Vaccinations',
      icon: LucideIcons.syringe,
      colors: [Color(0xFF39A4E6), Color(0xFF5BB5ED)],
      type: MedicalCategoryType.vaccinations,
    ),
    _MedicalCategory(
      label: 'Medical History',
      icon: LucideIcons.history,
      colors: [Color(0xFF39A4E6), Color(0xFF5BB5ED)],
      type: MedicalCategoryType.medicalHistory,
    ),
  ];

  bool _isSearching = false;
  bool _hasRecords = false;

  List<_MedicalCategory> get _filteredCategories {
    if (_searchController.text.isEmpty) return _categories;
    return _categories
        .where(
          (category) => category.label.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddRecord() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddRecordScreen(
          onBack: () => Navigator.of(context).pop(),
          onSave: (data) {
            setState(() {
              _hasRecords = true;
              _patient = data;
            });
          },
        ),
      ),
    );
  }

  void _openAllergies() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AllergiesScreen(
          onBack: () => Navigator.of(context).pop(),
          patientData: _patient,
        ),
      ),
    );
  }

  void _openVaccinations() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            VaccinationsScreen(onBack: () => Navigator.of(context).pop()),
      ),
    );
  }

  void _openAnalysis() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnalysisScreen(
          onBack: () => Navigator.of(context).pop(),
          onViewDetails: (testName) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AnalysisDetailScreen(
                  onBack: () => Navigator.of(context).pop(),
                  testName: testName,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openMedicalHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            MedicalHistoryScreen(onBack: () => Navigator.of(context).pop()),
      ),
    );
  }

  void _handleCategoryTap(MedicalCategoryType type) {
    switch (type) {
      case MedicalCategoryType.allergies:
        _openAllergies();
        break;
      case MedicalCategoryType.analysis:
        _openAnalysis();
        break;
      case MedicalCategoryType.vaccinations:
        _openVaccinations();
        break;
      case MedicalCategoryType.medicalHistory:
        _openMedicalHistory();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: Stack(
        children: [
          const MedicalBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSearchField(),
                        const SizedBox(height: 24),
                        _buildPatientInfo(),
                        const SizedBox(height: 24),
                        _buildCategories(),
                        if (!_hasRecords) ...[
                          const SizedBox(height: 32),
                          _buildAddRecordButton(),
                        ],
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
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF39A4E6).withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(
                    LucideIcons.chevronLeft,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'Medical Record',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
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

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _isSearching = value.isNotEmpty);
        },
        decoration: InputDecoration(
          prefixIcon: const Icon(LucideIcons.search, color: Color(0xFF39A4E6)),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: const Icon(LucideIcons.x, size: 18, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _isSearching = false);
                  },
                )
              : null,
          hintText: 'Search...',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPatientInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE9F6FE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Jane Doe',
            style: TextStyle(
              color: Color(0xFF39A4E6),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFE9F6FE)),
          const SizedBox(height: 16),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 12,
              childAspectRatio: 3.5,
            ),
            children: [
              _infoItem('Gender', _patient.gender),
              _infoItem('Blood Type', _patient.bloodType),
              _infoItem('Age', '${_patient.age} Years'),
              _infoItem('Weight', '${_patient.weight} kg'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF39A4E6),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.05,
      children: _filteredCategories.map((category) {
        return GestureDetector(
          onTap: () => _handleCategoryTap(category.type),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: category.colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: category.colors.last.withOpacity(0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(category.icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  category.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddRecordButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          backgroundColor: const Color(0xFF39A4E6),
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        onPressed: _openAddRecord,
        child: const Text('Add Medical Record'),
      ),
    );
  }
}

class _MedicalCategory {
  final String label;
  final IconData icon;
  final List<Color> colors;
  final MedicalCategoryType type;

  const _MedicalCategory({
    required this.label,
    required this.icon,
    required this.colors,
    required this.type,
  });
}

enum MedicalCategoryType { allergies, analysis, vaccinations, medicalHistory }
