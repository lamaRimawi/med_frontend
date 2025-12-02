import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../widgets/medical_background.dart';

class AnalysisItem {
  final String name;
  final String description;
  final String addedDate;
  final DateTime date;

  const AnalysisItem({
    required this.name,
    required this.description,
    required this.addedDate,
    required this.date,
  });
}

class AnalysisScreen extends StatefulWidget {
  final VoidCallback onBack;
  final void Function(String testName)? onViewDetails;

  const AnalysisScreen({super.key, required this.onBack, this.onViewDetails});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  String _selectedFilter = 'Newest';
  String _selectedTest = 'Blood Test';
  bool _showDatePicker = false;

  int? _selectedDay;
  int? _selectedMonth;
  int? _selectedYear;

  final List<AnalysisItem> _analysisItems = [
    AnalysisItem(
      name: "Blood Test",
      description: "Glucose: Elevated levels may indicate diabetes.",
      addedDate: "Added Manually 10 February 2024",
      date: DateTime(2024, 2, 10),
    ),
    AnalysisItem(
      name: "Urine Tests",
      description:
          "Color, and Odor: Abnormalities may indicate urinary tract infections or kidney disease.",
      addedDate: "Added Manually 06 June 2024",
      date: DateTime(2024, 6, 6),
    ),
    AnalysisItem(
      name: "Lipid Profile",
      description:
          "Triglycerides: Elevated levels may indicate increased cardiovascular risk.",
      addedDate: "Added Manually 20 October 2024",
      date: DateTime(2024, 10, 20),
    ),
    AnalysisItem(
      name: "Thyroid Tests",
      description:
          "T3 and T4: Abnormal levels may indicate thyroid dysfunction.",
      addedDate: "Added Manually 15 March 2024",
      date: DateTime(2024, 3, 15),
    ),
  ];

  List<int> get _days => List.generate(31, (index) => index + 1);
  List<int> get _months => List.generate(12, (index) => index + 1);
  List<int> get _years => List.generate(6, (index) => 2020 + index);

  List<AnalysisItem> get _filteredItems {
    return _analysisItems.where((item) {
      final dayMatch = _selectedDay == null || item.date.day == _selectedDay;
      final monthMatch =
          _selectedMonth == null || item.date.month == _selectedMonth;
      final yearMatch =
          _selectedYear == null || item.date.year == _selectedYear;
      return dayMatch && monthMatch && yearMatch;
    }).toList()..sort(
      (a, b) => _selectedFilter == 'Newest'
          ? b.date.compareTo(a.date)
          : a.date.compareTo(b.date),
    );
  }

  void _handleDownload(AnalysisItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading ${item.name} report...')),
    );
  }

  void _handleTestTap(AnalysisItem item) {
    setState(() => _selectedTest = item.name);
    widget.onViewDetails?.call(item.name);
  }

  void _handleFilterChange(String label) {
    setState(() => _selectedFilter = label);
  }

  void _toggleDatePicker() =>
      setState(() => _showDatePicker = !_showDatePicker);

  void _clearDateFilter() {
    setState(() {
      _selectedDay = null;
      _selectedMonth = null;
      _selectedYear = null;
      _showDatePicker = false;
    });
  }

  void _selectDay(int day) => setState(() => _selectedDay = day);
  void _selectMonth(int month) => setState(() => _selectedMonth = month);
  void _selectYear(int year) => setState(() => _selectedYear = year);

  String _getDateDisplay() {
    if (_selectedDay == null &&
        _selectedMonth == null &&
        _selectedYear == null) {
      return 'D  M  Y';
    }

    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final monthLabel = _selectedMonth != null
        ? monthNames[_selectedMonth! - 1]
        : 'M';
    final dayLabel = _selectedDay?.toString() ?? 'D';
    final yearLabel = _selectedYear?.toString() ?? 'Y';
    return '$dayLabel $monthLabel $yearLabel';
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const MedicalBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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
                        const Text(
                          'Analysis',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildFilterRow(),
                        if (_showDatePicker) ...[
                          const SizedBox(height: 16),
                          _buildDatePickerCard(),
                        ],
                        if ((_selectedDay != null ||
                            _selectedMonth != null ||
                            _selectedYear != null))
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              'Showing ${items.length} result${items.length == 1 ? '' : 's'} for ${_getDateDisplay()}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        const SizedBox(height: 24),
                        if (items.isEmpty)
                          _buildEmptyState()
                        else
                          Column(
                            children: items.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
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
                                child: _buildAnalysisCard(item),
                              );
                            }).toList(),
                          ),
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
      width: double.infinity,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
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

  Widget _buildFilterRow() {
    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Search By:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 12),
            _buildChip('Newest'),
            const SizedBox(width: 8),
            _buildChip('Oldest'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Date:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _toggleDatePicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getDateDisplay(),
                        style: TextStyle(
                          color:
                              (_selectedDay == null &&
                                  _selectedMonth == null &&
                                  _selectedYear == null)
                              ? Colors.grey
                              : const Color(0xFF39A4E6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        _showDatePicker
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_selectedDay != null ||
                _selectedMonth != null ||
                _selectedYear != null)
              TextButton(
                onPressed: _clearDateFilter,
                child: const Text('Clear'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(String label) {
    final selected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => _handleFilterChange(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF39A4E6) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.grey.shade300,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF39A4E6).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerCard() {
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9F6FE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Date',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: _clearDateFilter,
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateColumn(
                  'Day',
                  _days,
                  (value) => _selectDay(value as int),
                  _selectedDay,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateColumn(
                  'Month',
                  _months,
                  (value) => _selectMonth(value as int),
                  _selectedMonth,
                  valueBuilder: (value) => monthNames[value - 1],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateColumn(
                  'Year',
                  _years,
                  (value) => _selectYear(value as int),
                  _selectedYear,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _showDatePicker = false),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39A4E6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateColumn(
    String label,
    List<int> values,
    ValueChanged<dynamic> onTap,
    int? selectedValue, {
    String Function(int value)? valueBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Scrollbar(
            child: ListView.builder(
              itemCount: values.length,
              itemBuilder: (context, index) {
                final value = values[index];
                final isSelected = value == selectedValue;
                return ListTile(
                  dense: true,
                  title: Text(
                    valueBuilder?.call(value) ?? value.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  tileColor: isSelected
                      ? const Color(0xFF39A4E6)
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () => onTap(value),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisCard(AnalysisItem item) {
    final isSelected = _selectedTest == item.name;
    return GestureDetector(
      onTap: () => _handleTestTap(item),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected ? const Color(0xFF39A4E6) : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _handleTestTap(item),
              child: _buildRadio(isSelected),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: Color(0xFF39A4E6),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(item.description, style: const TextStyle(height: 1.4)),
                  const SizedBox(height: 8),
                  Text(
                    item.addedDate,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => _handleDownload(item),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF39A4E6), Color(0xFF2B8FD9)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const Icon(
                  LucideIcons.download,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadio(bool selected) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? const Color(0xFF39A4E6) : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: selected ? 12 : 0,
          height: selected ? 12 : 0,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF39A4E6),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE9F6FE)),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.calendar, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          const Text(
            'No analysis found for the selected date',
            style: TextStyle(color: Colors.grey),
          ),
          TextButton(
            onPressed: _clearDateFilter,
            child: const Text('Clear filter'),
          ),
        ],
      ),
    );
  }
}
