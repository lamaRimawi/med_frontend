import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/patient_data.dart';
import '../widgets/medical_background.dart';

class Allergy {
  final String name;
  final String symptoms;
  final String addedDate;

  const Allergy({
    required this.name,
    required this.symptoms,
    required this.addedDate,
  });
}

class AllergiesScreen extends StatefulWidget {
  final VoidCallback onBack;
  final PatientData patientData;

  const AllergiesScreen({
    super.key,
    required this.onBack,
    required this.patientData,
  });

  @override
  State<AllergiesScreen> createState() => _AllergiesScreenState();
}

class _AllergiesScreenState extends State<AllergiesScreen> {
  final List<Allergy> _allergies = [
    const Allergy(
      name: "Insulin",
      symptoms:
          "Skin Symptoms: redness, itching and swelling at injection site.",
      addedDate: "Added Manually 10 February 20XX",
    ),
    const Allergy(
      name: "Codeine",
      symptoms: "Respiratory Symptoms: Wheezing, difficulty breathing.",
      addedDate: "Added Manually 06 June 20XX",
    ),
    const Allergy(
      name: "Pollen",
      symptoms: "Respiratory Symptoms: Sneezing, runny nose, nasal congestion.",
      addedDate: "Added Manually 20 October 20XX",
    ),
    const Allergy(
      name: "latex",
      symptoms: "Skin Symptoms: Itching, redness, rash.",
      addedDate: "Added Manually 20 October 20XX",
    ),
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();

  bool _showAddForm = false;

  @override
  void dispose() {
    _nameController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }

  void _handleAddAllergy() {
    final name = _nameController.text.trim();
    final symptoms = _symptomsController.text.trim();
    if (name.isEmpty || symptoms.isEmpty) return;

    final now = DateTime.now();
    final months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    final dateLabel =
        "Added Manually ${now.day} ${months[now.month - 1]} ${now.year}";

    setState(() {
      _allergies.add(
        Allergy(name: name, symptoms: symptoms, addedDate: dateLabel),
      );
      _nameController.clear();
      _symptomsController.clear();
      _showAddForm = false;
    });
  }

  void _handleDeleteAllergy(int index) {
    setState(() => _allergies.removeAt(index));
  }

  void _toggleForm(bool value) {
    setState(() {
      _showAddForm = value;
      if (!value) {
        _nameController.clear();
        _symptomsController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const MedicalBackground(),
          SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 120),
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
                            _buildPatientInfo(),
                            const SizedBox(height: 24),
                            const Text(
                              'Allergies',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'and adverse reactions',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ..._allergies.asMap().entries.map((entry) {
                              final index = entry.key;
                              final allergy = entry.value;
                              return Animate(
                                delay: Duration(milliseconds: 80 * index),
                                effects: const [
                                  FadeEffect(
                                    duration: Duration(milliseconds: 300),
                                  ),
                                  MoveEffect(
                                    begin: Offset(0, 20),
                                    end: Offset.zero,
                                    duration: Duration(milliseconds: 400),
                                  ),
                                ],
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(26),
                                    border: Border.all(
                                      color: const Color(0xFFE9F6FE),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 18,
                                        height: 18,
                                        margin: const EdgeInsets.only(top: 6),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF39A4E6),
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFF39A4E6),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              allergy.name,
                                              style: const TextStyle(
                                                color: Color(0xFF39A4E6),
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              allergy.symptoms,
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                height: 1.4,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              allergy.addedDate,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          LucideIcons.x,
                                          color: Color(0xFFE57373),
                                          size: 22,
                                        ),
                                        onPressed: () =>
                                            _handleDeleteAllergy(index),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                            Center(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF39A4E6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 48,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: () => _toggleForm(true),
                                child: const Text('Add More'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildAddAllergyModal(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
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

  Widget _buildPatientInfo() {
    return Column(
      children: [
        const Text(
          'Jane Doe',
          style: TextStyle(
            color: Color(0xFF39A4E6),
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(color: const Color(0xFFE9F6FE), height: 1),
        const SizedBox(height: 18),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 24,
            mainAxisSpacing: 12,
            childAspectRatio: 3.6,
          ),
          children: [
            _buildInfoItem('Gender', widget.patientData.gender),
            _buildInfoItem('Blood Type', widget.patientData.bloodType),
            _buildInfoItem('Age', '${widget.patientData.age} Years'),
            _buildInfoItem('Weight', '${widget.patientData.weight} kg'),
          ],
        ),
        const SizedBox(height: 18),
        Container(color: const Color(0xFFE9F6FE), height: 1),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
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

  Widget _buildAddAllergyModal() {
    return IgnorePointer(
      ignoring: !_showAddForm,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _showAddForm ? 1 : 0,
        child: Visibility(
          visible: _showAddForm,
          child: GestureDetector(
            onTap: () => _toggleForm(false),
            child: Container(
              color: Colors.black54,
              child: Center(
                child: GestureDetector(
                  onTap: () {},
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: _showAddForm ? 1 : 0.9,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Add New Allergy',
                                style: TextStyle(
                                  color: Color(0xFF39A4E6),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.x),
                                onPressed: () => _toggleForm(false),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildModalField(
                            label: 'Allergy Name',
                            controller: _nameController,
                            hint: 'e.g., Penicillin',
                          ),
                          const SizedBox(height: 16),
                          _buildModalField(
                            label: 'Symptoms',
                            controller: _symptomsController,
                            hint: 'Describe symptoms...',
                            maxLines: 4,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _toggleForm(false),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      (_nameController.text.trim().isEmpty ||
                                          _symptomsController.text
                                              .trim()
                                              .isEmpty)
                                      ? null
                                      : _handleAddAllergy,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF39A4E6),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text('Add'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFF39A4E6)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
