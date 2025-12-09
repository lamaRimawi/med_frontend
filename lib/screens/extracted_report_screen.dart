import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';

import 'package:mediScan/models/extracted_report_data.dart';

class ExtractedReportScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onClose;
  final VoidCallback onBack;
  final ExtractedReportData extractedData;

  const ExtractedReportScreen({
    super.key,
    required this.isDarkMode,
    required this.onClose,
    required this.onBack,
    required this.extractedData,
  });

  @override
  State<ExtractedReportScreen> createState() => _ExtractedReportScreenState();
}

class _ExtractedReportScreenState extends State<ExtractedReportScreen> {
  final Set<String> _expanded = {'patient', 'tests', 'vitals'};
  bool _shareOpen = false;
  bool _copied = false;
  late final String _shareLink;

  @override
  void initState() {
    super.initState();
    _shareLink =
        'https://healthtrack.app/reports/${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
  }

  void _toggle(String id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _shareLink));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  Future<void> _launchUri(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open app for sharing')),
      );
    }
  }

  Future<void> _shareEmail() async {
    final subject = Uri.encodeComponent('HealthTrack Medical Report');
    final body = Uri.encodeComponent(
      'View medical report for ${widget.extractedData.patientInfo.name}: $_shareLink',
    );
    await _launchUri(Uri.parse('mailto:?subject=$subject&body=$body'));
    setState(() => _shareOpen = false);
  }

  Future<void> _shareWhatsApp() async {
    final text = Uri.encodeComponent(
      'View medical report for ${widget.extractedData.patientInfo.name}: $_shareLink',
    );
    await _launchUri(Uri.parse('https://wa.me/?text=$text'));
    setState(() => _shareOpen = false);
  }

  Future<void> _shareSMS() async {
    final text = Uri.encodeComponent(
      'View medical report for ${widget.extractedData.patientInfo.name}: $_shareLink',
    );
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final uri = isIOS
        ? Uri.parse('sms:&body=$text')
        : Uri.parse('sms:?body=$text');
    await _launchUri(uri);
    setState(() => _shareOpen = false);
  }

  Future<void> _exportTxt() async {
    final data = widget.extractedData;
    final sb = StringBuffer();
    sb.writeln('HEALTHTRACK MEDICAL REPORT');
    sb.writeln('=' * 50);
    sb.writeln();
    sb.writeln('Report Type: ${data.reportType}');
    sb.writeln('Date: ${data.reportDate}');
    sb.writeln();
    sb.writeln('PATIENT INFORMATION');
    sb.writeln('-' * 50);
    sb.writeln('Name: ${data.patientInfo.name}');
    sb.writeln('Age: ${data.patientInfo.age} years');
    sb.writeln('Gender: ${data.patientInfo.gender}');
    if (data.patientInfo.id != null) sb.writeln('ID: ${data.patientInfo.id}');
    if (data.patientInfo.phone != null)
      sb.writeln('Phone: ${data.patientInfo.phone}');
    sb.writeln();
    if (data.doctorInfo != null) {
      sb.writeln('DOCTOR INFORMATION');
      sb.writeln('-' * 50);
      sb.writeln('Name: ${data.doctorInfo!.name}');
      sb.writeln('Specialty: ${data.doctorInfo!.specialty}');
      if (data.doctorInfo!.hospital != null)
        sb.writeln('Hospital: ${data.doctorInfo!.hospital}');
      sb.writeln();
    }
    if ((data.vitals ?? []).isNotEmpty) {
      sb.writeln('VITAL SIGNS');
      sb.writeln('-' * 50);
      for (final v in data.vitals!) {
        sb.writeln('${v.name}: ${v.value} ${v.unit}');
      }
      sb.writeln();
    }
    if ((data.testResults ?? []).isNotEmpty) {
      sb.writeln('TEST RESULTS');
      sb.writeln('-' * 50);
      for (final t in data.testResults!) {
        sb.writeln(
          '${t.name}: ${t.value} ${t.unit} (${t.status.toUpperCase()})',
        );
        sb.writeln('  Normal Range: ${t.normalRange} ${t.unit}');
      }
      sb.writeln();
    }
    if ((data.medications ?? []).isNotEmpty) {
      sb.writeln('MEDICATIONS');
      sb.writeln('-' * 50);
      for (final m in data.medications!) {
        sb.writeln(m.name);
        sb.writeln('  Dosage: ${m.dosage}');
        sb.writeln('  Frequency: ${m.frequency}');
        sb.writeln('  Duration: ${m.duration}');
      }
      sb.writeln();
    }
    if (data.diagnosis != null) {
      sb.writeln('DIAGNOSIS');
      sb.writeln('-' * 50);
      sb.writeln(data.diagnosis);
      sb.writeln();
    }
    if (data.observations != null) {
      sb.writeln('OBSERVATIONS');
      sb.writeln('-' * 50);
      sb.writeln(data.observations);
      sb.writeln();
    }
    if ((data.recommendations ?? []).isNotEmpty) {
      sb.writeln('RECOMMENDATIONS');
      sb.writeln('-' * 50);
      for (var i = 0; i < data.recommendations!.length; i++) {
        sb.writeln('${i + 1}. ${data.recommendations![i]}');
      }
      sb.writeln();
    }
    if ((data.warnings ?? []).isNotEmpty) {
      sb.writeln('WARNINGS');
      sb.writeln('-' * 50);
      for (final w in data.warnings!) {
        sb.writeln('⚠ $w');
      }
      sb.writeln();
    }
    if (data.nextVisit != null) {
      sb.writeln('NEXT VISIT');
      sb.writeln('-' * 50);
      sb.writeln(data.nextVisit);
      sb.writeln();
    }
    sb.writeln('-' * 50);
    sb.writeln(
      'Generated by HealthTrack on ${DateTime.now().toLocal().toString().split(' ').first}',
    );

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/medical-report-${widget.extractedData.patientInfo.name.replaceAll(' ', '-')}-${DateTime.now().toIso8601String().split('T').first}.txt',
    );
    await file.writeAsString(sb.toString());
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Medical report for ${widget.extractedData.patientInfo.name}');
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'high':
      case 'low':
        return const Color(0xFFF59E0B); // Orange for borderline
      case 'critical':
        return const Color(0xFFEF4444); // Red for critical
      case 'abnormal':
        return const Color(0xFFF59E0B); // Orange for abnormal
      case 'normal':
        return const Color(0xFF10B981); // Green for normal
      default:
        return widget.isDarkMode ? Colors.grey : Colors.grey.shade700;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'high':
      case 'low':
        return const Color(0x1AF59E0B); // 10% alpha orange
      case 'critical':
        return const Color(0x1AEF4444); // 10% alpha red
      case 'abnormal':
        return const Color(0x1AF59E0B); // 10% alpha orange
      case 'normal':
        return const Color(0x1A10B981); // 10% alpha green
      default:
        return widget.isDarkMode
            ? const Color(0x80373737)
            : Colors.grey.shade100;
    }
  }

  IconData _vitalIcon(String name) {
    switch (name) {
      case 'heart':
        return LucideIcons.heart;
      case 'thermometer':
        return LucideIcons.thermometer;
      case 'activity':
        return LucideIcons.activity;
      case 'droplet':
        return LucideIcons.droplet;
      default:
        return LucideIcons.activity;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.extractedData;
    return Scaffold(
      backgroundColor: widget.isDarkMode
          ? const Color(0xFF0B1220)
          : const Color(0xFFF7F9FC),
      body: Stack(
        children: [
          // floating gradient blobs
          Positioned(
            right: -160,
            top: -160,
            child:
                Container(
                      width: 420,
                      height: 420,
                      decoration: BoxDecoration(
                        color: const Color(0x1439A4E6),
                        borderRadius: BorderRadius.circular(420),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveX(begin: 0, end: -20, duration: 25.seconds),
          ),
          Positioned(
            left: -200,
            bottom: -200,
            child:
                Container(
                      width: 520,
                      height: 520,
                      decoration: BoxDecoration(
                        color: const Color(0x1F39A4E6),
                        borderRadius: BorderRadius.circular(520),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: 0, end: -30, duration: 28.seconds),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                          _roundIconButton(
                            LucideIcons.arrowLeft,
                            onTap: () {
                              debugPrint('DEBUG: Back button tapped');
                              widget.onBack();
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Medical Report',
                                  style: TextStyle(
                                    color: widget.isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${d.reportType} • ${d.reportDate}',
                                  style: TextStyle(
                                    color: widget.isDarkMode
                                        ? Colors.grey
                                        : Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                          ), // closes Column
                          ), // closes inner Expanded
                        ],
                      ),
                    ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          _roundIconButton(
                            LucideIcons.share2,
                            onTap: () => setState(() => _shareOpen = true),
                          ),
                          const SizedBox(width: 8),
                          _roundIconButton(
                            LucideIcons.download,
                            onTap: _exportTxt,
                          ),
                          const SizedBox(width: 8),
                          _roundIconButton(
                            LucideIcons.code, // Debug icon
                            onTap: () {
                              if (d.debugRawJson != null) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Raw Backend Response'),
                                    content: SingleChildScrollView(
                                      child: SelectableText(d.debugRawJson!),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          _roundIconButton(
                            LucideIcons.x,
                            onTap: () {
                              debugPrint('DEBUG: Close button tapped');
                              widget.onClose();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Patient info
                        _sectionCard(
                          id: 'patient',
                          leadingIcon: LucideIcons.user,
                          title: 'Patient Information',
                          subtitle: d.patientInfo.name,
                          content: Column(
                            children: [
                              _infoRow('Full Name', d.patientInfo.name),
                              _infoRow(
                                'Age / Gender',
                                '${d.patientInfo.age} years • ${d.patientInfo.gender}',
                              ),
                              if (d.patientInfo.id != null)
                                _infoRow('Patient ID', d.patientInfo.id!),
                              if (d.patientInfo.phone != null)
                                _infoRow('Phone', d.patientInfo.phone!),
                            ],
                          ),
                        ),

                        if (d.doctorInfo != null)
                          _plainCard(
                            icon: LucideIcons.stethoscope,
                            title: 'Doctor Information',
                            child: Column(
                              children: [
                                _infoRow('Doctor Name', d.doctorInfo!.name),
                                _infoRow('Specialty', d.doctorInfo!.specialty),
                                if (d.doctorInfo!.hospital != null)
                                  _infoRow('Hospital', d.doctorInfo!.hospital!),
                              ],
                            ),
                          ),

                        if ((d.vitals ?? []).isNotEmpty)
                          _sectionCard(
                            id: 'vitals',
                            leadingIcon: LucideIcons.activity,
                            title: 'Vital Signs',
                            subtitle: 'Current measurements',
                            content: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: d.vitals!.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: 2.6,
                                  ),
                              itemBuilder: (context, i) {
                                final v = d.vitals![i];
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: widget.isDarkMode
                                        ? Colors.white10
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(0x1A39A4E6),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          _vitalIcon(v.icon),
                                          color: const Color(0xFF39A4E6),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              v.value,
                                              style: TextStyle(
                                                color: widget.isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              '${v.name} • ${v.unit}',
                                              style: TextStyle(
                                                color: widget.isDarkMode
                                                    ? Colors.grey
                                                    : Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                        if ((d.testResults ?? []).isNotEmpty)
                          _sectionCard(
                            id: 'tests',
                            leadingIcon: LucideIcons.fileText,
                            title: 'Test Results',
                            subtitle: '${d.testResults!.length} tests analyzed',
                            content: Column(
                              children: d.testResults!.map((t) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: widget.isDarkMode
                                        ? Colors.white10
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    t.name,
                                                    style: TextStyle(
                                                      color: widget.isDarkMode
                                                          ? Colors.white
                                                          : Colors.black,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: _statusBg(t.status),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    t.status,
                                                    style: TextStyle(
                                                      color: _statusColor(
                                                        t.status,
                                                      ),
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  t.value,
                                                  style: TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: widget.isDarkMode
                                                        ? Colors.white
                                                        : Colors.black,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  t.unit,
                                                  style: TextStyle(
                                                    color: widget.isDarkMode
                                                        ? Colors.grey
                                                        : Colors.grey.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Normal: ${t.normalRange} ${t.unit}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: widget.isDarkMode
                                                    ? Colors.grey
                                                    : Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                        if ((d.medications ?? []).isNotEmpty)
                          _sectionCard(
                            id: 'meds',
                            leadingIcon: LucideIcons.pill,
                            title: 'Medications',
                            subtitle: '${d.medications!.length} prescribed',
                            content: Column(
                              children: d.medications!.map((m) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: widget.isDarkMode
                                        ? Colors.white10
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.name,
                                        style: TextStyle(
                                          color: widget.isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _infoRow('Dosage', m.dosage),
                                          ),
                                          Expanded(
                                            child: _infoRow(
                                              'Frequency',
                                              m.frequency,
                                            ),
                                          ),
                                          Expanded(
                                            child: _infoRow(
                                              'Duration',
                                              m.duration,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                        if (d.diagnosis != null)
                          _plainCard(
                            icon: LucideIcons.fileText,
                            title: 'Diagnosis',
                            child: Text(
                              d.diagnosis!,
                              style: TextStyle(
                                color: widget.isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),
                          ),

                        if (d.observations != null)
                          _plainCard(
                            icon: LucideIcons.stethoscope,
                            title: 'Observations',
                            child: Text(
                              d.observations!,
                              style: TextStyle(
                                color: widget.isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),
                          ),

                        if ((d.recommendations ?? []).isNotEmpty)
                          _plainCard(
                            icon: LucideIcons.target,
                            title: 'Recommendations',
                            child: Column(
                              children: d.recommendations!
                                  .map(
                                    (r) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            margin: const EdgeInsets.only(
                                              top: 6,
                                              right: 10,
                                            ),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF39A4E6),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              r,
                                              style: TextStyle(
                                                color: widget.isDarkMode
                                                    ? Colors.grey[300]
                                                    : Colors.grey.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),

                        if ((d.warnings ?? []).isNotEmpty)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: widget.isDarkMode
                                  ? const Color(0x33FF0000)
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: widget.isDarkMode
                                    ? const Color(0x26FF0000)
                                    : Colors.red.shade200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.alertTriangle,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Important Warnings',
                                      style: TextStyle(
                                        color: widget.isDarkMode
                                            ? Colors.red[200]
                                            : Colors.red.shade900,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ...d.warnings!.map(
                                  (w) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          LucideIcons.alertCircle,
                                          size: 16,
                                          color: Colors.redAccent,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            w,
                                            style: TextStyle(
                                              color: widget.isDarkMode
                                                  ? Colors.red[200]
                                                  : Colors.red.shade900,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (d.nextVisit != null)
                          _plainCard(
                            icon: LucideIcons.calendar,
                            title: 'Next Visit',
                            child: Text(
                              d.nextVisit!,
                              style: TextStyle(
                                color: widget.isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_shareOpen) _buildShareModal(),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String id,
    required IconData leadingIcon,
    required String title,
    String? subtitle,
    required Widget content,
  }) {
    final expanded = _expanded.contains(id);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDarkMode
              ? const Color(0x1FFFFFFF)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _toggle(id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0x1A39A4E6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.activity,
                      color: Color(0xFF39A4E6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: widget.isDarkMode
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: widget.isDarkMode
                                  ? Colors.grey
                                  : Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      LucideIcons.chevronDown,
                      color: widget.isDarkMode
                          ? Colors.grey
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: content,
            ),
        ],
      ),
    );
  }

  Widget _plainCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDarkMode
              ? const Color(0x1FFFFFFF)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0x1A39A4E6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF39A4E6)),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.grey : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundIconButton(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: widget.isDarkMode
          ? const Color(0xFF0F172A)
          : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDarkMode
                  ? const Color(0x1FFFFFFF)
                  : Colors.grey.shade300,
            ),
          ),
          child: Icon(
            icon,
            color: widget.isDarkMode ? Colors.grey[300] : Colors.grey.shade700,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildShareModal() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _shareOpen = false),
        child: Container(
          color: Colors.black54,
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                width: 420,
                decoration: BoxDecoration(
                  color: widget.isDarkMode
                      ? const Color(0xFF111827)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.isDarkMode
                        ? const Color(0x1FFFFFFF)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 40),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0x1A39A4E6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            LucideIcons.share2,
                            color: Color(0xFF39A4E6),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _shareOpen = false),
                          icon: const Icon(LucideIcons.x),
                          color: widget.isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey.shade600,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Share Medical Report',
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Share ${widget.extractedData.patientInfo.name}'s report securely",
                      style: TextStyle(
                        color: widget.isDarkMode
                            ? Colors.grey
                            : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // link row
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isDarkMode
                            ? Colors.black.withOpacity(0.2)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.isDarkMode
                              ? const Color(0x1FFFFFFF)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.link,
                            color: Color(0xFF39A4E6),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _shareLink,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: widget.isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _copyLink,
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF39A4E6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: Icon(
                              _copied ? LucideIcons.check : LucideIcons.copy,
                              size: 16,
                            ),
                            label: Text(_copied ? 'Copied!' : 'Copy'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Or share via',
                        style: TextStyle(
                          color: widget.isDarkMode
                              ? Colors.grey[300]
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _shareRow(
                      icon: LucideIcons.mail,
                      title: 'Email',
                      subtitle: 'Share via email client',
                      onTap: _shareEmail,
                    ),
                    const SizedBox(height: 8),
                    _shareRow(
                      icon: LucideIcons.messageCircle,
                      title: 'WhatsApp',
                      subtitle: 'Share on WhatsApp',
                      onTap: _shareWhatsApp,
                    ),
                    const SizedBox(height: 8),
                    _shareRow(
                      icon: LucideIcons.messageSquare,
                      title: 'SMS',
                      subtitle: 'Share via text message',
                      onTap: _shareSMS,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _shareRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: widget.isDarkMode ? Colors.white10 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.isDarkMode
                ? const Color(0x1FFFFFFF)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? Colors.white12
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: widget.isDarkMode
                    ? Colors.grey[300]
                    : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: widget.isDarkMode
                          ? Colors.grey
                          : Colors.grey.shade600,
                      fontSize: 12,
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
}
