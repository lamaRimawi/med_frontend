import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final List<String> _filters = ['All', 'Lab Results', 'Prescriptions', 'Scans'];
  int _selectedFilterIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload feature coming soon')),
          );
        },
        backgroundColor: const Color(0xFF39A4E6),
        icon: const Icon(LucideIcons.uploadCloud, color: Colors.white),
        label: const Text('Upload', style: TextStyle(color: Colors.white)),
      ).animate().scale(delay: 500.ms, curve: Curves.elasticOut),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1F2937)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'My Reports',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.filter, color: Color(0xFF1F2937)),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.search, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Search reports...',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).moveY(begin: -20, end: 0),

            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(_filters.length, (index) {
                  final isSelected = _selectedFilterIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilterIndex = index),
                      child: AnimatedContainer(
                        duration: 200.ms,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF39A4E6) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF39A4E6) : Colors.grey[300]!,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF39A4E6).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : [],
                        ),
                        child: Text(
                          _filters[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ).animate().fadeIn(delay: 200.ms).moveX(begin: 20, end: 0),

            // Reports List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildReportCard(
                    'General Blood Test',
                    '23 Nov 2025',
                    'Dr. Sarah Smith',
                    'Lab Result',
                    LucideIcons.flaskConical,
                    Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  _buildReportCard(
                    'MRI Scan Brain',
                    '20 Nov 2025',
                    'City Imaging Center',
                    'Radiology',
                    LucideIcons.scan,
                    Colors.blueAccent,
                  ),
                  const SizedBox(height: 16),
                  _buildReportCard(
                    'Dental X-Ray',
                    '15 Nov 2025',
                    'Dr. Emily White',
                    'X-Ray',
                    LucideIcons.fileImage,
                    Colors.orangeAccent,
                  ),
                  const SizedBox(height: 16),
                  _buildReportCard(
                    'Vitamin D Test',
                    '10 Nov 2025',
                    'HealthLab',
                    'Lab Result',
                    LucideIcons.flaskConical,
                    Colors.purpleAccent,
                  ),
                  const SizedBox(height: 16),
                  _buildReportCard(
                    'Eye Checkup',
                    '05 Nov 2025',
                    'Dr. Mark Brown',
                    'Prescription',
                    LucideIcons.fileText,
                    Colors.green,
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(
    String title,
    String date,
    String source,
    String type,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$source • $date',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'View',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF39A4E6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
