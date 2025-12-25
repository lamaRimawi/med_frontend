import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/extracted_report_data.dart';

class ReportContentWidget extends StatelessWidget {
  final String patientName;
  final String patientAge;
  final String patientGender;
  final String? patientId;
  final String? patientPhone;
  
  final String reportType;
  final String reportDate;
  
  final String? doctorName;
  final String? doctorSpecialty;
  final String? hospitalName;
  
  final List<TestResult> results;
  final bool isDarkMode;

  const ReportContentWidget({
    super.key,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    this.patientId,
    this.patientPhone,
    required this.reportType,
    required this.reportDate,
    this.doctorName,
    this.doctorSpecialty,
    this.hospitalName,
    required this.results,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Group results by category
    final Map<String, List<TestResult>> groupedResults = {};
    for (var result in results) {
      final category = (result.category != null && result.category!.isNotEmpty) 
          ? result.category! 
          : 'General Results';
      if (!groupedResults.containsKey(category)) {
        groupedResults[category] = [];
      }
      groupedResults[category]!.add(result);
    }
    
    // Sort categories: General Results first, then alphabetical
    final sortedCategories = groupedResults.keys.toList()..sort((a, b) {
      if (a == 'General Results') return -1;
      if (b == 'General Results') return 1;
      return a.compareTo(b);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Patient Info Section
          _sectionCard(
            context,
            id: 'patient',
            leadingIcon: LucideIcons.user,
            title: 'Patient Information',
            content: Column(
              children: [
                _infoRow(context, 'Full Name', patientName),
                _infoRow(
                  context,
                  'Age / Gender',
                  '$patientAge years • $patientGender',
                ),
                if (patientId != null && patientId!.isNotEmpty)
                  _infoRow(context, 'Patient ID', patientId!),
                if (patientPhone != null && patientPhone!.isNotEmpty)
                  _infoRow(context, 'Phone', patientPhone!),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Doctor / Report Info Section
          if (doctorName != null || hospitalName != null)
             _sectionCard(
              context,
              id: 'doctor', 
              leadingIcon: LucideIcons.stethoscope,
              title: 'Source Information',
              content: Column(
                children: [
                  if (doctorName != null && doctorName!.isNotEmpty)
                     _infoRow(context, 'Doctor', doctorName!),
                  if (doctorSpecialty != null && doctorSpecialty!.isNotEmpty)
                     _infoRow(context, 'Specialty', doctorSpecialty!),
                  if (hospitalName != null && hospitalName!.isNotEmpty)
                     _infoRow(context, 'Hospital/Clinic', hospitalName!),
                  _infoRow(context, 'Report Date', reportDate),
                ],
              ),
             ),

          const SizedBox(height: 24),
          
          // Categorized Results
          if (results.isEmpty)
            _buildEmptyState(context)
          else
            ...sortedCategories.map((category) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _sectionCard(
                  context,
                  id: 'cat_$category',
                  leadingIcon: LucideIcons.fileText,
                  title: category,
                  content: Column(
                    children: groupedResults[category]!.map((t) {
                      return _buildTestResultItem(context, t);
                    }).toList(),
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              LucideIcons.fileSearch,
              size: 48,
              color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No detailed results available',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultItem(BuildContext context, TestResult t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white10 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.name,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusBg(t.status),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        t.status,
                        style: TextStyle(
                          color: _statusColor(t.status),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      t.value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      t.unit,
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey : Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (t.normalRange.isNotEmpty && t.normalRange != 'N/A') ...[
                  const SizedBox(height: 4),
                  Text(
                    'Normal: ${t.normalRange} ${t.unit}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey : Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String id,
    required IconData leadingIcon,
    required String title,
    required Widget content,
    String? subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      // margin: const EdgeInsets.only(bottom: 16), // Handled by parent
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF39A4E6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  leadingIcon,
                  color: const Color(0xFF39A4E6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          content,
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'high':
      case 'low':
      case 'abnormal':
        return const Color(0xFFF59E0B);
      case 'critical':
        return const Color(0xFFEF4444);
      case 'normal':
        return const Color(0xFF10B981);
      default:
        return isDarkMode ? Colors.grey : Colors.grey.shade700;
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'high':
      case 'low':
      case 'abnormal':
        return const Color(0x1AF59E0B);
      case 'critical':
        return const Color(0x1AEF4444);
      case 'normal':
        return const Color(0x1A10B981);
      default:
        return isDarkMode ? const Color(0x80373737) : Colors.grey.shade100;
    }
  }
}
