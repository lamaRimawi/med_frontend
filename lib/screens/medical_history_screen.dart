import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../widgets/medical_background.dart';

class MedicalHistoryScreen extends StatefulWidget {
  final VoidCallback onBack;

  const MedicalHistoryScreen({super.key, required this.onBack});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  bool _isDoctorsExpanded = false;
  bool _isEditingControl = false;
  bool _isEditingTreatment = false;

  final TextEditingController _controlController = TextEditingController(
    text:
        'Paroxysmal Tachycardia\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
  );

  final TextEditingController _treatmentController = TextEditingController(
    text:
        'Lorem ipsum dolor 5mg (Morning)\nSit amet consectetur 10mg (Evening)\nAdipiscing elit 2.5mg (Night)',
  );

  final List<_Doctor> _doctors = [
    const _Doctor(
      name: 'Dr. Emma Hall, M.D.',
      specialty: 'General Doctor',
      isFavorite: true,
    ),
    const _Doctor(name: 'Dr. James Taylor, M.D.', specialty: 'General Doctor'),
  ];

  @override
  void dispose() {
    _controlController.dispose();
    _treatmentController.dispose();
    super.dispose();
  }

  void _toggleFavorite(int index) {
    setState(() {
      _doctors[index] = _doctors[index].copyWith(
        isFavorite: !_doctors[index].isFavorite,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A1929) : Colors.white,
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
                        _buildTitle(isDark),
                        const SizedBox(height: 24),
                        _buildEditableCard(
                          title: 'In Control',
                          controller: _controlController,
                          isEditing: _isEditingControl,
                          onEditToggle: () => setState(
                            () => _isEditingControl = !_isEditingControl,
                          ),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 24),
                        _buildEditableCard(
                          title: 'Treatment Plan',
                          controller: _treatmentController,
                          isEditing: _isEditingTreatment,
                          onEditToggle: () => setState(
                            () => _isEditingTreatment = !_isEditingTreatment,
                          ),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 32),
                        _buildDoctorsSection(isDark),
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
      padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F2137) : null,
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
                icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
              ),
              const Expanded(
                child: Text(
                  'Medical Record',
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

  Widget _buildTitle(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medical History',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Divider(
          color: isDark ? const Color(0xFF0F2137) : const Color(0xFFE9F6FE),
          thickness: 1,
        ),
      ],
    );
  }

  Widget _buildEditableCard({
    required String title,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEditToggle,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            TextButton.icon(
              onPressed: onEditToggle,
              icon: Icon(
                isEditing ? LucideIcons.check : LucideIcons.edit,
                size: 16,
                color: const Color(0xFF39A4E6),
              ),
              label: Text(
                isEditing ? 'Save' : 'Edit',
                style: const TextStyle(color: Color(0xFF39A4E6)),
              ),
            ),
          ],
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F2137) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF0F2137) : const Color(0xFFE9F6FE),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            enabled: isEditing,
            maxLines: null,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: const InputDecoration.collapsed(hintText: ''),
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isDoctorsExpanded = !_isDoctorsExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF39A4E6).withOpacity(0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Consulting Physicians',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Icon(LucideIcons.chevronDown, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isDoctorsExpanded
              ? Column(
                  children: _doctors.asMap().entries.map((entry) {
                    final index = entry.key;
                    final doctor = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F2137) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF0F2137)
                              : const Color(0xFFE9F6FE),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                doctor.initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doctor.name,
                                  style: const TextStyle(
                                    color: Color(0xFF39A4E6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  doctor.specialty,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _toggleFavorite(index),
                            icon: Icon(
                              doctor.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: doctor.isFavorite
                                  ? const Color(0xFF39A4E6)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _Doctor {
  final String name;
  final String specialty;
  final bool isFavorite;

  const _Doctor({
    required this.name,
    required this.specialty,
    this.isFavorite = false,
  });

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return name.substring(0, 1);
  }

  _Doctor copyWith({bool? isFavorite}) {
    return _Doctor(
      name: name,
      specialty: specialty,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
