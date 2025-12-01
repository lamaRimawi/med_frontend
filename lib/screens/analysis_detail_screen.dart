import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../widgets/medical_background.dart';

class AnalysisDetailScreen extends StatelessWidget {
  final VoidCallback onBack;
  final String testName;

  const AnalysisDetailScreen({
    super.key,
    required this.onBack,
    required this.testName,
  });

  static const Map<String, dynamic> _testData = {
    'Blood Test': {
      'title': 'Blood Test',
      'description':
          'Complete blood analysis including glucose levels, electrolyte balance, and liver function tests. This comprehensive test helps monitor overall health and detect potential medical conditions early.',
      'subtitle': 'Test Results Overview',
      'sections': [
        {
          'title': 'GLUCOSE',
          'items': [
            {'name': 'Fasting Levels', 'value': '12 mg/dL'},
            {'name': 'Oral Glucose Tolerance Test (OGTT)', 'value': '6 mg/dL'},
            {'name': 'Hemoglobin A1c (HbA1c)', 'value': '16 mg/dL'},
          ],
        },
        {
          'title': 'ELECTROLYTES',
          'items': [
            {'name': 'Sodium', 'value': '10%'},
            {'name': 'Potassium', 'value': '23%'},
            {'name': 'Chloride', 'value': '12%'},
          ],
        },
        {
          'title': 'LIVER ENZYMES',
          'items': [
            {'name': 'ALT', 'value': '6%'},
            {'name': 'AST', 'value': '19%'},
            {'name': 'ALP', 'value': '12%'},
            {'name': 'Bilirubin', 'value': '14g%'},
          ],
        },
      ],
    },
  };

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data =
        (_testData[testName] ?? _testData['Blood Test'])
            as Map<String, dynamic>;
    final List<dynamic> sections = data['sections'] as List<dynamic>;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const MedicalBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(data['title'] as String),
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
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          data['description'] as String,
                          style: const TextStyle(
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          data['subtitle'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...sections.asMap().entries.map((entry) {
                          final section = entry.value as Map<String, dynamic>;
                          final items = section['items'] as List<dynamic>;
                          return Animate(
                            delay: Duration(milliseconds: entry.key * 100),
                            effects: const [
                              FadeEffect(duration: Duration(milliseconds: 300)),
                              MoveEffect(
                                begin: Offset(0, 20),
                                end: Offset.zero,
                                duration: Duration(milliseconds: 400),
                              ),
                            ],
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFFE9F6FE),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 14,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    section['title'] as String,
                                    style: const TextStyle(
                                      color: Color(0xFF39A4E6),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ...items.map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item['name'] as String,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            height: 1,
                                            width: 60,
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            color: Colors.grey.withOpacity(0.4),
                                          ),
                                          Text(
                                            item['value'] as String,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
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

  Widget _buildHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF39A4E6),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
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
}
