import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';

import 'package:mediScan/models/extracted_report_data.dart';
import 'package:mediScan/widgets/report_content_widget.dart';

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

  @override
  Widget build(BuildContext context) {
    final d = widget.extractedData;
    return Scaffold(
      backgroundColor: widget.isDarkMode
          ? const Color(0xFF0A1929)
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
                // Header (kept as is)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                        child: Text(
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
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ReportContentWidget(
                    isDarkMode: widget.isDarkMode,
                    patientName: d.patientInfo.name,
                    patientAge: d.patientInfo.age.toString(),
                    patientGender: d.patientInfo.gender,
                    patientId: d.patientInfo.id,
                    patientPhone: d.patientInfo.phone,
                    reportType: d.reportType,
                    reportDate: d.reportDate,
                    doctorName: d.doctorInfo?.name,
                    doctorSpecialty: d.doctorInfo?.specialty,
                    hospitalName: d.doctorInfo?.hospital,
                    results: [
                      // Map Vitals
                      if (d.vitals != null)
                        ...d.vitals!.map((v) => TestResult(
                          name: v.name,
                          value: v.value,
                          unit: v.unit,
                          normalRange: 'N/A',
                          status: 'normal', // Default for now
                          category: 'Vital Signs',
                        )),
                      
                      // Map Test Results
                      if (d.testResults != null)
                        ...d.testResults!,
                        
                      // Map Medications
                      if (d.medications != null)
                        ...d.medications!.map((m) => TestResult(
                          name: m.name,
                          value: '${m.dosage} - ${m.frequency}',
                          unit: '',
                          normalRange: m.duration,
                          status: 'normal',
                          category: 'Medications',
                        )),
                        
                      // Map Diagnosis
                      if (d.diagnosis != null && d.diagnosis!.isNotEmpty)
                        TestResult(
                          name: 'Diagnosis',
                          value: d.diagnosis!,
                          unit: '',
                          normalRange: '',
                          status: 'normal',
                          category: 'Diagnosis & Summary',
                        ),
                        
                      // Map Observations
                      if (d.observations != null && d.observations!.isNotEmpty)
                        TestResult(
                          name: 'Observations',
                          value: d.observations!,
                          unit: '',
                          normalRange: '',
                          status: 'normal',
                          category: 'Diagnosis & Summary',
                        ),
                        
                      // Map Warnings
                      if (d.warnings != null && d.warnings!.isNotEmpty)
                        ...d.warnings!.map((w) => TestResult(
                          name: 'Warning',
                          value: w,
                          unit: '',
                          normalRange: '',
                          status: 'critical',
                          category: 'Warnings',
                        )),
                        
                      // Map Next Visit
                      if (d.nextVisit != null && d.nextVisit!.isNotEmpty)
                        TestResult(
                          name: 'Next Visit',
                          value: d.nextVisit!,
                          unit: '',
                          normalRange: '',
                          status: 'normal',
                          category: 'Follow Up',
                        ),
                    ],
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

  // Helper method for header buttons
  Widget _roundIconButton(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: widget.isDarkMode ? const Color(0xFF0F2137) : Colors.grey.shade100,
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
                      ? const Color(0xFF1E293B)
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
