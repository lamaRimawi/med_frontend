import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';
import 'package:intl/intl.dart';

import '../services/timeline_api.dart';
import '../models/timeline_models.dart';
import '../models/extracted_report_data.dart';
import '../models/profile_model.dart';
import '../widgets/profile_selector.dart';
import '../services/profile_state_service.dart';

import '../services/api_client.dart'; // For AccessVerificationException
import '../widgets/access_verification_modal.dart';

class TimelineScreen extends StatefulWidget {
  final VoidCallback onBack;
  final bool isDarkMode;

  const TimelineScreen({
    super.key,
    required this.onBack,
    required this.isDarkMode,
  });

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  // Data State
  List<TimelineReport> _timelineReports = [];
  final Map<int, ExtractedReportData> _reportDetailsCache = {};
  List<String> _availableMetrics = [];
  String _selectedMetric = '';
  List<TrendDataPoint> _trendData = [];
  
  // Patient Filtering
  List<String> _patientNames = [];
  String? _selectedPatient;
  // UI State
  bool _isLoading = true;
  bool _isMetricLoading = false;
  String? _errorMessage;
  int? _touchedSpotIndex;
  int? _selectedProfileId;
  String? _selectedProfileName;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    // Listen to profile changes
    ProfileStateService().profileNotifier.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    ProfileStateService().profileNotifier.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    final profile = ProfileStateService().profileNotifier.value;
    if (mounted) {
      setState(() {
        _selectedProfileId = profile?.id;
        _selectedProfileName = profile?.fullName;
        _isLoading = true;
      });
      _loadTimelineData();
    }
  }

  Future<void> _initializeApp() async {
    await _initializeProfile();
    await _loadTimelineData();
  }

  Future<void> _initializeProfile() async {
    // Load the selected profile from global state
    final selectedProfile = await ProfileStateService().getSelectedProfile();
    if (mounted) {
      setState(() {
        _selectedProfileId = selectedProfile?.id;
        _selectedProfileName = selectedProfile?.fullName;
      });
    }
  }

  // Demo Data Flag
  final bool _useDemoData = false;

  Future<void> _loadTimelineData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _timelineReports = [];
      _reportDetailsCache.clear(); // Clear cache to prevent data mixing between profiles
      _availableMetrics = [];
      _patientNames = [];
      _trendData = [];
      _selectedMetric = '';
    });

    // Removed Demo Data Logic

    try {
      // 1. Fetch the timeline to get report IDs
      final timeline = await TimelineApi.getTimeline(profileId: _selectedProfileId);
      _timelineReports = timeline;

      // 2. Fetch details for each report to discover available metrics
      // Note: In a production app with pagination, we wouldn't fetch ALL details at once.
      // But for this use case (visualizing trends), we need to know what's available.
      await Future.wait(
        timeline.map((report) => _fetchReportDetails(report.reportId)),
      );



      // 3. Extract unique patient names
      final names = <String>{};
      for (var details in _reportDetailsCache.values) {
        if (details.patientInfo.name.isNotEmpty) {
          names.add(details.patientInfo.name.trim());
        }
      }
      // Sort names, putting 'Unknown' last
      _patientNames = names.toList()..sort((a, b) {
        if (a == 'Unknown') return 1;
        if (b == 'Unknown') return -1;
        return a.compareTo(b);
      });
      
      // Default to first patient if not selected, or if current selection is invalid
      if (_patientNames.isNotEmpty) {
        if (_selectedPatient == null || !_patientNames.contains(_selectedPatient)) {
          _selectedPatient = _patientNames.first;
        }
      }

      // Check for partial failures
      if (_timelineReports.isNotEmpty && _reportDetailsCache.isEmpty) {
        _errorMessage = "Unable to load report details. Please try again.";
      }


      // 4. Extract unique metric names (test names) for the selected patient
      _extractAvailableMetrics();

      setState(() {
        _isLoading = false;
      });

      // 4. Load trends for the first metric if available
      if (_availableMetrics.isNotEmpty) {
        _selectMetric(_availableMetrics.first);
      }
    } catch (e) {
      if (mounted) {
        if (e is AccessVerificationException) {
          _showVerificationModal();
        } else {
          setState(() {
            _errorMessage = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _fetchReportDetails(int reportId) async {
    try {
      final details = await TimelineApi.getReport(reportId, profileId: _selectedProfileId);
      _reportDetailsCache[reportId] = details;
    } catch (e) {
      if (e is AccessVerificationException) rethrow;
      debugPrint('Error fetching details for report $reportId: $e');
    }
  }

  Future<void> _showVerificationModal() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AccessVerificationModal(
        resourceType: 'profile',
        resourceId: _selectedProfileId ?? 0,
      ),
    );

    if (result == true) {
      if (mounted) {
        setState(() {
           _isLoading = true;
           _errorMessage = null;
        });
        _loadTimelineData();
      }
    } else {
       if (mounted && _timelineReports.isEmpty) {
          setState(() {
            _errorMessage = "Verification required to view health trends";
            _isLoading = false;
          });
       }
    }
  }

  void _extractAvailableMetrics() {
    final Set<String> metrics = {};
    for (var entry in _reportDetailsCache.entries) {
      final details = entry.value;
      
      // Filter by selected patient
      if (_selectedPatient != null && 
          details.patientInfo.name.trim() != _selectedPatient) {
        continue;
      }

      if (details.testResults != null) {
        for (var test in details.testResults!) {
          if (test.name.isNotEmpty) {
            metrics.add(test.name);
          }
        }
      }
    }
    _availableMetrics = metrics.toList()..sort();
    
    // Reset selected metric if it's no longer available
    if (_selectedMetric.isNotEmpty && !_availableMetrics.contains(_selectedMetric)) {
      _selectedMetric = '';
      _trendData = [];
    }
  }

  Future<void> _selectMetric(String metric) async {
    setState(() {
      _selectedMetric = metric;
      _isMetricLoading = true;
      _touchedSpotIndex = null;
    });

    // Removed Demo Data Logic

    try {
      // Use the specific API for trends if possible, or extract from cache
      // The API is preferred as it might handle normalization/units better.
      final trends = await TimelineApi.getTrends([metric], profileId: _selectedProfileId);
      
      setState(() {
        // The API returns a Map<String, List<TrendDataPoint>>
        // We just want the list for our selected metric.
        // The key might be the exact metric name.
        if (trends.trends.containsKey(metric)) {
          _trendData = trends.trends[metric]!;
        } else if (trends.trends.isNotEmpty) {
          // Fallback
          _trendData = trends.trends.values.first; 
        } else {
          _trendData = [];
        }
        
        // Filter by patient and strict metric name/value matching
        _trendData = _trendData.where((point) {
          final details = _reportDetailsCache[point.reportId];
          if (details == null) return false;
          
          // 1. Check patient name match
          if (_selectedPatient != null && 
              details.patientInfo.name.trim() != _selectedPatient) {
            return false;
          }
          
          // 2. Strict metric identification
          // We look into the actual report details to find an exact match for the selected metric
          // that also has the same value as this data point.
          final hasExactMatch = details.testResults?.any((test) => 
            test.name == metric && test.value == point.rawValue
          ) ?? false;
          
          return hasExactMatch;
        }).toList();
        
        // Sort by date just in case
        _trendData.sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));
        
        // Deduplicate points with same date and value to handle potential backend/upload duplicates
        final uniquePoints = <String, TrendDataPoint>{};
        final dedupedList = <TrendDataPoint>[];
        
        for (var point in _trendData) {
          // Create a unique key based on date and value
          final key = '${point.date}_${point.value}';
          
          if (!uniquePoints.containsKey(key)) {
            uniquePoints[key] = point;
            dedupedList.add(point);
          }
        }
        _trendData = dedupedList;
        
        _isMetricLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading trends for $metric: $e');
      setState(() {
        _trendData = [];
        _isMetricLoading = false;
      });
    }
  }



  // --- UI Builders ---

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    // Dark Mode Palette (Unified Black/Grey)
    const darkBgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
         Color(0xFF0A1929), // Material Dark Background
         Color(0xFF0A1929), // Solid consistency
      ],
    );

    // Light Mode Palette (Morning Sky)
    const lightBgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
         Color(0xFFF0F9FF), // Very light blue
         Color(0xFFE0F2FE), // Light sky blue
      ],
    );

    final bgGradient = isDark ? darkBgGradient : lightBgGradient;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final subTextColor = isDark ? Colors.white70 : Colors.grey[600];

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? const Color(0xFF0A1929) : null, // Fallback
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadTimelineData,
            color: const Color(0xFF39A4E6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isDark, textColor),
                if (_errorMessage != null)
                  Expanded(
                    child: ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.alertCircle, size: 48, color: Colors.red[400]),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: TextStyle(color: subTextColor, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadTimelineData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF39A4E6),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_isLoading)
                   Expanded(child: Center(child: CircularProgressIndicator(color: isDark ? Colors.white : const Color(0xFF39A4E6))))
                else 
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        children: [
                          _buildMetricSelector(isDark, textColor),
                          const SizedBox(height: 20),
                          if (_selectedMetric.isNotEmpty) ...[
                            _buildChartSection(isDark, textColor, subTextColor),
                            const SizedBox(height: 20),
                            _buildStatsCards(isDark, textColor, subTextColor),
                            const SizedBox(height: 20),
                            _buildHistoryList(isDark, textColor, subTextColor),
                          ] else if (_availableMetrics.isEmpty) ...[
                            // Empty state with chart and cards structure
                            _buildEmptyChartSection(isDark, textColor, subTextColor),
                            const SizedBox(height: 20),
                            _buildEmptyStatsCards(isDark, textColor, subTextColor),
                            const SizedBox(height: 20),
                            _buildEmptyHistoryList(isDark, textColor, subTextColor),
                          ] else
                             Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                "No health metrics found in your reports for $_selectedPatient.",
                                style: TextStyle(color: subTextColor),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textColor) {
    final title = (_selectedProfileName != null && _selectedProfileName!.isNotEmpty)
        ? "$_selectedProfileName's Trends"
        : 'Health Trends';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_selectedProfileName != null && _selectedProfileName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Health History & Analytics',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildMetricSelector(bool isDark, Color textColor) {
    if (_availableMetrics.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _availableMetrics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final metric = _availableMetrics[index];
          final isSelected = metric == _selectedMetric;
          
          final bgColor = isSelected 
              ? const Color(0xFF39A4E6) 
              : (isDark ? Colors.white.withOpacity(0.1) : Colors.white);
              
          final borderColor = isSelected 
              ? const Color(0xFF39A4E6) 
              : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!);

          final itemTextColor = isSelected 
              ? Colors.white 
              : (isDark ? Colors.white70 : Colors.grey[700]);

          return GestureDetector(
            onTap: () => _selectMetric(metric),
            child: AnimatedContainer(
              duration: 200.ms,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: isSelected || !isDark ? [
                   BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                   )
                ] : null,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150), // Limit width to prevent huge chips
                  child: Text(
                    metric,
                    style: TextStyle(
                      color: itemTextColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Key for the dropdown button to calculate its position
  final GlobalKey _metricButtonKey = GlobalKey();

  Widget _buildChartSection(bool isDark, Color textColor, Color? subTextColor) {
    final cardColor = isDark 
        ? const Color(0xFF1F2937).withOpacity(0.9) 
        : Colors.white.withOpacity(0.7);
    
    final borderColor = isDark 
        ? Colors.white.withOpacity(0.1)
        : Colors.white.withOpacity(0.5);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.blue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Spacer to avoid overlap with the top-left button
                        const SizedBox(width: 80),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                               Text(
                                _selectedMetric,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2, // Allow wrapping for long names
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                              ),
                              if (_trendData.isNotEmpty)
                                Text(
                                  '${_trendData.last.value} ${_trendData.last.unit ?? ''}',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.8),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      child: _trendData.isEmpty
                          ? _buildEmptyChart(isDark, textColor, subTextColor)
                          : _buildLineChart(isDark, textColor),
                    ),
                  ],
                ),
              ),
              // Responsive Icon / Selector Button (With GlobalKey)
              Positioned(
                top: 20,
                left: 20,
                child: GestureDetector(
                  onTap: () => _showMetricDropdown(context, isDark, textColor),
                  child: Container(
                    key: _metricButtonKey,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         Icon(
                          _getIconForMetric(_selectedMetric),
                          color: isDark ? Colors.white : Colors.black87,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          LucideIcons.chevronDown,
                          color: isDark ? Colors.white70 : Colors.black54,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isMetricLoading)
                Positioned(
                  top: 20,
                  left: 80,
                  child: SizedBox(
                   width: 16, 
                   height: 16, 
                   child: CircularProgressIndicator(strokeWidth: 2, color: subTextColor)
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  IconData _getIconForMetric(String metric) {
    final m = metric.toLowerCase();
    if (m.contains('hemoglobin') || m.contains('blood')) return LucideIcons.droplet;
    if (m.contains('heart') || m.contains('rate') || m.contains('pressure')) return LucideIcons.heart;
    if (m.contains('glucose') || m.contains('sugar')) return LucideIcons.candy;
    if (m.contains('temp')) return LucideIcons.thermometer;
    if (m.contains('wbc') || m.contains('immune')) return LucideIcons.shield;
    return LucideIcons.activity;
  }

  void _showMetricDropdown(BuildContext context, bool isDark, Color textColor) {
    final RenderBox renderBox = _metricButtonKey.currentContext!.findRenderObject() as RenderBox;
    final buttonPosition = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;

    // Constrain the menu height to avoid overflow
    final double maxMenuHeight = 300.0;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double bottomSpace = screenHeight - buttonPosition.dy - buttonSize.height - 20;
    
    // If not enough space below, show above? For now, let's assume scrolling handles it or it sits below.
    // The user specifically wanted it "not from bottom", suggesting a dropdown feel.

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Stack(
          children: [
            Positioned(
              top: buttonPosition.dy + buttonSize.height + 8,
              left: buttonPosition.dx,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 250, // Fixed width or dynamic? Fixed looks cleaner for menus
                  constraints: BoxConstraints(
                    maxHeight: maxMenuHeight,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F2937).withOpacity(0.95) : Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: Text(
                                'Select Metric',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ..._availableMetrics.map((metric) {
                              final isSelected = metric == _selectedMetric;
                              return InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                  _selectMetric(metric);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  color: isSelected ? (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)) : Colors.transparent,
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getIconForMetric(metric),
                                        size: 18,
                                        color: isSelected ? const Color(0xFF39A4E6) : textColor.withOpacity(0.8),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          metric,
                                          style: TextStyle(
                                            color: isSelected ? const Color(0xFF39A4E6) : textColor,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(LucideIcons.check, color: Color(0xFF39A4E6), size: 16),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            alignment: Alignment.topLeft, // Expand from the button
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildLineChart(bool isDark, Color textColor) {
    // Determine Min/Max for Y Axis to scale properly
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    
    for (var p in _trendData) {
      final val = p.numericValue ?? 0;
      if (val < minY) minY = val;
      if (val > maxY) maxY = val;
    }
    
    // Add some padding
    final double range = maxY - minY;
    final double padding = range == 0 ? 10 : range * 0.2;
    minY = (minY - padding).clamp(0, double.infinity); // Assuming health metrics are positive
    maxY = maxY + padding;
    
    final gridColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05);

    // Calculate a better display interval to avoid crowded labels
    final double displayRange = maxY - minY;
    // Aim for ~4-5 horizontal grid lines/labels
    final double labelInterval = displayRange == 0 ? 5 : (displayRange / 4).clamp(1.0, double.infinity);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: labelInterval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: gridColor,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1, // Show typical interval
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= _trendData.length) return const SizedBox.shrink();
                
                // Show date for the first, last, and maybe partials if many points
                // Simple logic: Show first and last always. Show others if enough space?
                // For now, let's show formatted date.
                
                // Optimize label density
                int skip = 0;
                if (_trendData.length > 5) skip = 2;
                if (_trendData.length > 10) skip = 3;
                
                if (skip > 0 && index % skip != 0 && index != _trendData.length - 1) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _formatDateAxis(_trendData[index].date),
                    style: TextStyle(
                      color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.4),
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: labelInterval,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    color: isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.4),
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.left,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (_trendData.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: _trendData.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.numericValue ?? 0);
            }).toList(),
            isCurved: true,
            color: const Color(0xFF39A4E6),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                // Highlight touched spot or last spot
                bool isTouched = _touchedSpotIndex == index;
                return FlDotCirclePainter(
                  radius: isTouched ? 6 : 4,
                  color: isTouched ? (isDark ? Colors.white : const Color(0xFF2E335A)) : const Color(0xFF39A4E6),
                  strokeWidth: 2,
                  strokeColor: isDark ? Colors.white : Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF39A4E6).withOpacity(0.3),
                  const Color(0xFF39A4E6).withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
             getTooltipColor: (touchedSpot) => isDark ? const Color(0xFF1F2937) : Colors.white,
             getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final point = _trendData[touchedSpot.x.toInt()];
                return LineTooltipItem(
                  '${point.value} ${point.unit ?? ''}\n',
                  TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1F2937), 
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: _formatDateFull(point.date),
                      style: TextStyle(
                        color: isDark ? Colors.white.withOpacity(0.7) : Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            if (response != null && response.lineBarSpots != null) {
              setState(() {
                _touchedSpotIndex = response.lineBarSpots!.first.spotIndex;
              });
            } else {
               setState(() {
                _touchedSpotIndex = null;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatsCards(bool isDark, Color textColor, Color? subTextColor) {
    if (_trendData.isEmpty) return const SizedBox.shrink();

    // Calculate Stats
    double sum = 0;
    double min = double.infinity;
    double max = double.negativeInfinity;
    int count = 0;

    for (var item in _trendData) {
      final val = item.numericValue;
      if (val != null) {
        sum += val;
        if (val < min) min = val;
        if (val > max) max = val;
        count++;
      }
    }

    if (count == 0) return const SizedBox.shrink();

    final avg = sum / count;
    final unit = _trendData.first.unit ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildSingleStatCard('Average', '${avg.toStringAsFixed(1)} $unit', LucideIcons.barChart3, isDark, textColor, subTextColor)),
          const SizedBox(width: 12),
          Expanded(child: _buildSingleStatCard('Min', '${min.toStringAsFixed(1)} $unit', LucideIcons.arrowDown, isDark, textColor, subTextColor)),
          const SizedBox(width: 12),
          Expanded(child: _buildSingleStatCard('Max', '${max.toStringAsFixed(1)} $unit', LucideIcons.arrowUp, isDark, textColor, subTextColor)),
        ],
      ),
    );
  }

  Widget _buildSingleStatCard(String label, String value, IconData icon, bool isDark, Color textColor, Color? subTextColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.white),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Icon(icon, color: isDark ? Colors.white70 : const Color(0xFF39A4E6), size: 16),
           const SizedBox(height: 8),
           Text(
             value,
             style: TextStyle(
               color: textColor,
               fontWeight: FontWeight.bold,
               fontSize: 14,
             ),
             maxLines: 1,
             overflow: TextOverflow.ellipsis,
           ),
           Text(
             label,
             style: TextStyle(
               color: subTextColor,
               fontSize: 10,
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(bool isDark, Color textColor, Color? subTextColor) {
    final cardColor = isDark 
        ? const Color(0xFF1F2937) 
        : Colors.white.withOpacity(0.7);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.white),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.blue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'History',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _trendData.length,
            separatorBuilder: (_, __) => Divider(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]),
            itemBuilder: (context, index) {
              // Show reverse order (newest first)
              final data = _trendData[_trendData.length - 1 - index];
              final isNormal = data.isNormal;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDateFull(data.date),
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isNormal 
                            ? (isDark ? Colors.green.withOpacity(0.2) : Colors.green[50])
                            : (isDark ? Colors.red.withOpacity(0.2) : Colors.red[50]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${data.rawValue} ${data.unit ?? ''}',
                        style: TextStyle(
                          color: isNormal 
                            ? (isDark ? Colors.greenAccent : Colors.green[700])
                            : (isDark ? Colors.redAccent : Colors.red[700]),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Empty State Widgets ---

  Widget _buildEmptyChartSection(bool isDark, Color textColor, Color? subTextColor) {
    final cardColor = isDark 
        ? const Color(0xFF1F2937) 
        : Colors.white.withOpacity(0.7);
    
    final borderColor = isDark 
        ? Colors.white.withOpacity(0.1)
        : Colors.white.withOpacity(0.5);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.blue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.activity,
                            color: isDark ? Colors.white70 : Colors.black54,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Select Metric',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'No Data',
                          style: TextStyle(
                            color: textColor.withOpacity(0.5),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '--',
                          style: TextStyle(
                            color: textColor.withOpacity(0.3),
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: _buildEmptyChart(isDark, textColor, subTextColor),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildEmptyChart(bool isDark, Color textColor, Color? subTextColor) {
    final gridColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03);
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: gridColor,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '',
                    style: TextStyle(
                      color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.2),
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '',
                  style: TextStyle(
                    color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.2),
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 100,
        lineBarsData: [],
      ),
    );
  }

  Widget _buildEmptyStatsCards(bool isDark, Color textColor, Color? subTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildEmptyStatCard('Average', '--', LucideIcons.barChart3, isDark, textColor, subTextColor)),
          const SizedBox(width: 12),
          Expanded(child: _buildEmptyStatCard('Min', '--', LucideIcons.arrowDown, isDark, textColor, subTextColor)),
          const SizedBox(width: 12),
          Expanded(child: _buildEmptyStatCard('Max', '--', LucideIcons.arrowUp, isDark, textColor, subTextColor)),
        ],
      ),
    );
  }

  Widget _buildEmptyStatCard(String label, String value, IconData icon, bool isDark, Color textColor, Color? subTextColor) {
    return Opacity(
      opacity: 0.5,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.white),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.blue.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isDark ? Colors.white70 : const Color(0xFF39A4E6), size: 16),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: textColor.withOpacity(0.5),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                color: subTextColor?.withOpacity(0.5) ?? Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryList(bool isDark, Color textColor, Color? subTextColor) {
    final cardColor = isDark 
        ? const Color(0xFF1F2937) 
        : Colors.white.withOpacity(0.7);

    return Opacity(
      opacity: 0.5,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.white),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.2) : Colors.blue.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'History',
              style: TextStyle(
                color: textColor.withOpacity(0.5),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(
                    LucideIcons.fileX,
                    size: 48,
                    color: subTextColor?.withOpacity(0.3) ?? Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No data available',
                    style: TextStyle(
                      color: subTextColor?.withOpacity(0.5) ?? Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upload reports to see trends',
                    style: TextStyle(
                      color: subTextColor?.withOpacity(0.4) ?? Colors.grey[400],
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

  // --- Helpers ---

  String _formatDateShort(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('MMM d, y').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  String _formatDateAxis(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('M/d').format(date);
    } catch (_) {
      return '';
    }
  }

  String _formatDateFull(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('E, MMM d').format(date);
    } catch (_) {
      return isoDate;
    }
  }

}
