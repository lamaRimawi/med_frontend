import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../widgets/medical_background.dart';

class VaccinationRecord {
  final String name;
  final String day;
  final String month;
  final String year;
  final bool isPlanned;

  const VaccinationRecord({
    required this.name,
    required this.day,
    required this.month,
    required this.year,
    this.isPlanned = false,
  });
}

class VaccinationsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const VaccinationsScreen({super.key, required this.onBack});

  @override
  State<VaccinationsScreen> createState() => _VaccinationsScreenState();
}

class _VaccinationsScreenState extends State<VaccinationsScreen> {
  final List<VaccinationRecord> _history = [
    const VaccinationRecord(name: "Covid", day: "18", month: "08", year: "20"),
    const VaccinationRecord(
      name: "Tetanus",
      day: "09",
      month: "02",
      year: "19",
    ),
    const VaccinationRecord(name: "Typus", day: "22", month: "06", year: "18"),
    const VaccinationRecord(
      name: "Hepatitis",
      day: "15",
      month: "09",
      year: "17",
    ),
  ];

  final List<VaccinationRecord> _next = [
    const VaccinationRecord(
      name: "Human Papillomavirus (HPV)",
      day: "18",
      month: "02",
      year: "24",
      isPlanned: false,
    ),
    const VaccinationRecord(
      name: "Second Dose",
      day: "18",
      month: "03",
      year: "24",
      isPlanned: true,
    ),
    const VaccinationRecord(
      name: "Third Dose",
      day: "D",
      month: "M",
      year: "Y",
      isPlanned: true,
    ),
  ];

  bool _editMode = false;
  bool _showAddForm = false;
  String _targetSection = 'history';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  Map<String, String> _errors = {
    'name': '',
    'day': '',
    'month': '',
    'year': '',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _toggleAddForm(String section) {
    setState(() {
      _targetSection = section;
      _showAddForm = true;
    });
  }

  void _closeForm() {
    setState(() {
      _showAddForm = false;
      _errors = {'name': '', 'day': '', 'month': '', 'year': ''};
      _nameController.clear();
      _dayController.clear();
      _monthController.clear();
      _yearController.clear();
    });
  }

  bool _validate() {
    final errors = {'name': '', 'day': '', 'month': '', 'year': ''};
    bool isValid = true;

    final name = _nameController.text.trim();
    final day = int.tryParse(_dayController.text);
    final month = int.tryParse(_monthController.text);
    final year = int.tryParse(_yearController.text);
    final currentYear = DateTime.now().year % 100;

    if (name.isEmpty) {
      errors['name'] = 'Vaccine name is required';
      isValid = false;
    } else if (name.length < 2) {
      errors['name'] = 'Vaccine name must be at least 2 characters';
      isValid = false;
    }

    if (_dayController.text.isEmpty) {
      errors['day'] = 'Day is required';
      isValid = false;
    } else if (day == null || day < 1 || day > 31) {
      errors['day'] = 'Day must be between 1-31';
      isValid = false;
    }

    if (_monthController.text.isEmpty) {
      errors['month'] = 'Month is required';
      isValid = false;
    } else if (month == null || month < 1 || month > 12) {
      errors['month'] = 'Month must be between 1-12';
      isValid = false;
    }

    if (_yearController.text.isEmpty) {
      errors['year'] = 'Year is required';
      isValid = false;
    } else if (year == null || year < 0 || year > currentYear + 10) {
      errors['year'] = 'Year must be between 00-${currentYear + 10}';
      isValid = false;
    }

    setState(() => _errors = errors);
    return isValid;
  }

  void _handleAdd() {
    if (!_validate()) return;

    final record = VaccinationRecord(
      name: _nameController.text.trim(),
      day: _dayController.text.padLeft(2, '0'),
      month: _monthController.text.padLeft(2, '0'),
      year: _yearController.text.padLeft(2, '0'),
    );

    setState(() {
      if (_targetSection == 'history') {
        _history.add(record);
      } else {
        _next.add(record);
      }
    });
    _closeForm();
  }

  void _deleteHistory(int index) {
    setState(() => _history.removeAt(index));
  }

  void _deleteNext(int index) {
    setState(() => _next.removeAt(index));
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
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 100),
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
                            _buildTitleRow(isDark),
                            const SizedBox(height: 32),
                            _buildSectionHeader('Immunisation history', isDark),
                            const SizedBox(height: 12),
                            ..._history.asMap().entries.map(
                              (entry) => Animate(
                                delay: Duration(milliseconds: entry.key * 80),
                                effects: const [
                                  FadeEffect(
                                    duration: Duration(milliseconds: 250),
                                  ),
                                  MoveEffect(
                                    begin: Offset(-20, 0),
                                    end: Offset.zero,
                                    duration: Duration(milliseconds: 250),
                                  ),
                                ],
                                child: _buildHistoryRow(entry.value, entry.key, isDark),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildAddButton(
                              'Add Vaccination',
                              () => _toggleAddForm('history'),
                            ),
                            const SizedBox(height: 32),
                            _buildSectionHeader('Next Immunisations due', isDark),
                            const SizedBox(height: 12),
                            ..._next.asMap().entries.map(
                              (entry) => Animate(
                                delay: Duration(milliseconds: 120 * entry.key),
                                effects: const [
                                  FadeEffect(
                                    duration: Duration(milliseconds: 250),
                                  ),
                                  MoveEffect(
                                    begin: Offset(-20, 0),
                                    end: Offset.zero,
                                    duration: Duration(milliseconds: 250),
                                  ),
                                ],
                                child: _buildNextRow(entry.value, entry.key, isDark),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildAddButton(
                              'Add Next Immunisation',
                              () => _toggleAddForm('next'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildModal(isDark),
              ],
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

  Widget _buildTitleRow(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Vaccinations',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        IconButton(
          onPressed: () => setState(() => _editMode = !_editMode),
          icon: Icon(
            _editMode ? LucideIcons.check : LucideIcons.edit,
            color: const Color(0xFF39A4E6),
          ),
          splashRadius: 20,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const Row(
          children: [
            SizedBox(
              width: 24,
              child: Center(
                child: Text('D', style: TextStyle(color: Colors.grey)),
              ),
            ),
            SizedBox(
              width: 24,
              child: Center(
                child: Text('M', style: TextStyle(color: Colors.grey)),
              ),
            ),
            SizedBox(
              width: 24,
              child: Center(
                child: Text('Y', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryRow(VaccinationRecord record, int index, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            record.name,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        _buildDateTriplet(record, isDark),
        if (_editMode)
          IconButton(
            icon: const Icon(LucideIcons.x, color: Colors.redAccent, size: 20),
            onPressed: () => _deleteHistory(index),
          ),
      ],
    );
  }

  Widget _buildNextRow(VaccinationRecord record, int index, bool isDark) {
    final isPlanned = record.isPlanned;
    final content = isPlanned
        ? _buildPlannedDate(record)
        : _buildDateTriplet(record, isDark);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            record.name,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isPlanned
                  ? const Color(0xFF39A4E6)
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
        content,
        if (_editMode)
          IconButton(
            icon: const Icon(LucideIcons.x, color: Colors.redAccent, size: 20),
            onPressed: () => _deleteNext(index),
          ),
      ],
    );
  }

  Widget _buildDateTriplet(VaccinationRecord record, bool isDark) {
    final style = TextStyle(color: isDark ? Colors.white : Colors.black87);
    return Row(
      children: [
        SizedBox(
            width: 28, child: Center(child: Text(record.day, style: style))),
        SizedBox(
            width: 28, child: Center(child: Text(record.month, style: style))),
        SizedBox(
            width: 28, child: Center(child: Text(record.year, style: style))),
      ],
    );
  }

  Widget _buildPlannedDate(VaccinationRecord record) {
    Widget _circle(String value) {
      return Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF39A4E6)),
        ),
        child: Center(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF39A4E6),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        _circle(record.day),
        _circle(record.month),
        _circle(record.year),
      ],
    );
  }

  Widget _buildAddButton(String label, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(LucideIcons.plus, color: Color(0xFF39A4E6), size: 18),
      label: Text(label, style: const TextStyle(color: Color(0xFF39A4E6))),
    );
  }

  Widget _buildModal(bool isDark) {
    return IgnorePointer(
      ignoring: !_showAddForm,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _showAddForm ? 1 : 0,
        child: Visibility(
          visible: _showAddForm,
          child: GestureDetector(
            onTap: _closeForm,
            child: Container(
              color: Colors.black45,
              child: Center(
                child: GestureDetector(
                  onTap: () {},
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: _showAddForm ? 1 : 0.9,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F2137) : Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
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
                              Text(
                                _targetSection == 'history'
                                    ? 'Add Vaccination'
                                    : 'Add Next Immunisation',
                                style: const TextStyle(
                                  color: Color(0xFF39A4E6),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                onPressed: _closeForm,
                                icon: const Icon(LucideIcons.x),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _nameController,
                            label: 'Vaccine Name',
                            hint: 'e.g., COVID-19',
                            errorKey: 'name',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _dayController,
                                  label: 'Day',
                                  hint: 'DD',
                                  maxLength: 2,
                                  errorKey: 'day',
                                  keyboardType: TextInputType.number,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: _monthController,
                                  label: 'Month',
                                  hint: 'MM',
                                  maxLength: 2,
                                  errorKey: 'month',
                                  keyboardType: TextInputType.number,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: _yearController,
                                  label: 'Year',
                                  hint: 'YY',
                                  maxLength: 2,
                                  errorKey: 'year',
                                  keyboardType: TextInputType.number,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _closeForm,
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
                                  onPressed: _handleAdd,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String errorKey,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
    required bool isDark,
  }) {
    final errorMessage = _errors[errorKey] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLength: maxLength,
          keyboardType: keyboardType,
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0A1929)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: isDark ? Colors.white30 : Colors.black38),
            counterText: '',
            filled: true,
            fillColor: isDark ? const Color(0xFF0A1929) : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: errorMessage.isNotEmpty
                    ? Colors.redAccent
                    : Colors.transparent,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: errorMessage.isNotEmpty
                    ? Colors.redAccent
                    : const Color(0xFF39A4E6),
              ),
            ),
          ),
          onChanged: (_) {
            if (errorMessage.isNotEmpty) {
              setState(() => _errors[errorKey] = '');
            }
          },
        ),
        if (errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
