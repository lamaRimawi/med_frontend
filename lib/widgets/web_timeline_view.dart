import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/timeline_api.dart';
import '../models/timeline_models.dart';
import '../models/extracted_report_data.dart';
import 'dart:ui';

class WebTimelineView extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback? onBack;

  const WebTimelineView({
    super.key,
    required this.isDarkMode,
    this.onBack,
  });

  @override
  State<WebTimelineView> createState() => _WebTimelineViewState();
}

class _WebTimelineViewState extends State<WebTimelineView> {
  List<TimelineReport> _timelineReports = [];
  final Map<int, ExtractedReportData> _reportDetailsCache = {};
  List<String> _availableMetrics = [];
  String _selectedMetric = '';
  List<TrendDataPoint> _trendData = [];
  
  bool _isLoading = true;
  bool _isMetricLoading = false;
  String? _errorMessage;
  int? _touchedSpotIndex;

  @override
  void initState() {
    super.initState();
    _loadTimelineData();
  }

  Future<void> _loadTimelineData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final timeline = await TimelineApi.getTimeline();
      _timelineReports = timeline;

      await Future.wait(
        timeline.map((report) => _fetchReportDetails(report.reportId)),
      );

      _extractAvailableMetrics();

      setState(() {
        _isLoading = false;
      });

      if (_availableMetrics.isNotEmpty) {
        _selectMetric(_availableMetrics.first);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchReportDetails(int reportId) async {
    try {
      final details = await TimelineApi.getReport(reportId);
      _reportDetailsCache[reportId] = details;
    } catch (e) {
      debugPrint('Error fetching details for report $reportId: $e');
    }
  }

  void _extractAvailableMetrics() {
    final Set<String> metrics = {};
    for (var details in _reportDetailsCache.values) {
      if (details.testResults != null) {
        for (var test in details.testResults!) {
          if (test.name.isNotEmpty) {
            metrics.add(test.name);
          }
        }
      }
    }
    _availableMetrics = metrics.toList()..sort();
  }

  Future<void> _selectMetric(String metric) async {
    setState(() {
      _selectedMetric = metric;
      _isMetricLoading = true;
      _touchedSpotIndex = null;
    });

    try {
      final trends = await TimelineApi.getTrends([metric]);
      
      setState(() {
        if (trends.trends.containsKey(metric)) {
          _trendData = trends.trends[metric]!;
        } else if (trends.trends.isNotEmpty) {
          _trendData = trends.trends.values.first; 
        } else {
          _trendData = [];
        }
        
        _trendData.sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));
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

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: Colors.transparent,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.alertCircle, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading timeline',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                style: GoogleFonts.outfit(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_availableMetrics.isNotEmpty) ...[
                                _buildMetricSelector(),
                                const SizedBox(height: 32),
                                if (_selectedMetric.isNotEmpty) ...[
                                  _buildChartSection(),
                                  const SizedBox(height: 32),
                                  _buildStatsCards(),
                                  const SizedBox(height: 32),
                                  _buildHistoryList(),
                                ],
                              ] else
                                Center(
                                  child: Column(
                                    children: [
                                      Icon(LucideIcons.activity, size: 64, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No health metrics found',
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          color: widget.isDarkMode ? Colors.white : Colors.black87,
                                        ),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF0F2137) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Health Trends',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          if (_timelineReports.isNotEmpty)
            Text(
              '${_timelineReports.length} ${_timelineReports.length == 1 ? 'report' : 'reports'}',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricSelector() {
    if (_availableMetrics.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _availableMetrics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final metric = _availableMetrics[index];
          final isSelected = metric == _selectedMetric;
          
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectMetric(metric),
              borderRadius: BorderRadius.circular(25),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF39A4E6)
                      : widget.isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF39A4E6)
                        : widget.isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey[300]!,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF39A4E6).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getIconForMetric(metric),
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : (widget.isDarkMode ? Colors.white70 : Colors.grey[700]),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      metric,
                      style: GoogleFonts.outfit(
                        color: isSelected
                            ? Colors.white
                            : (widget.isDarkMode ? Colors.white70 : Colors.grey[700]),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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

  Widget _buildChartSection() {
    final cardColor = widget.isDarkMode
        ? const Color(0xFF0F2137)
        : Colors.white;
    
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedMetric,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (_trendData.isNotEmpty)
                    Text(
                      '${_trendData.last.value} ${_trendData.last.unit ?? ''}',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                ],
              ),
              if (_isMetricLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 300,
            child: _trendData.isEmpty
                ? Center(
                    child: Text(
                      'No data points',
                      style: GoogleFonts.outfit(
                        color: Colors.grey[500],
                      ),
                    ),
                  )
                : _buildLineChart(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildLineChart() {
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    
    for (var p in _trendData) {
      final val = p.numericValue ?? 0;
      if (val < minY) minY = val;
      if (val > maxY) maxY = val;
    }
    
    final double range = maxY - minY;
    final double padding = range == 0 ? 10 : range * 0.2;
    minY = (minY - padding).clamp(0, double.infinity);
    maxY = maxY + padding;
    
    final gridColor = widget.isDarkMode
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.05);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: range == 0 ? 1 : range / 4,
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
              reservedSize: 40,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= _trendData.length) return const SizedBox.shrink();
                
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
                    style: GoogleFonts.outfit(
                      color: widget.isDarkMode
                          ? Colors.white.withOpacity(0.5)
                          : Colors.black.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: range == 0 ? 1 : range / 4,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: GoogleFonts.outfit(
                    color: widget.isDarkMode
                        ? Colors.white.withOpacity(0.5)
                        : Colors.black.withOpacity(0.4),
                    fontSize: 11,
                  ),
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
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                bool isTouched = _touchedSpotIndex == index;
                return FlDotCirclePainter(
                  radius: isTouched ? 7 : 5,
                  color: isTouched
                      ? Colors.white
                      : const Color(0xFF39A4E6),
                  strokeWidth: 3,
                  strokeColor: Colors.white,
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
            getTooltipColor: (touchedSpot) =>
                widget.isDarkMode ? const Color(0xFF0F2137) : Colors.white,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final point = _trendData[touchedSpot.x.toInt()];
                return LineTooltipItem(
                  '${point.value} ${point.unit ?? ''}\n',
                  GoogleFonts.outfit(
                    color: widget.isDarkMode ? Colors.white : const Color(0xFF1F2937),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: _formatDateFull(point.date),
                      style: GoogleFonts.outfit(
                        color: widget.isDarkMode
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey,
                        fontSize: 11,
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

  Widget _buildStatsCards() {
    if (_trendData.isEmpty) return const SizedBox.shrink();

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

    return Row(
      children: [
        Expanded(
          child: _buildSingleStatCard(
            'Average',
            '${avg.toStringAsFixed(1)} $unit',
            LucideIcons.barChart3,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSingleStatCard(
            'Minimum',
            '${min.toStringAsFixed(1)} $unit',
            LucideIcons.arrowDown,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSingleStatCard(
            'Maximum',
            '${max.toStringAsFixed(1)} $unit',
            LucideIcons.arrowUp,
          ),
        ),
      ],
    );
  }

  Widget _buildSingleStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF0F2137) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
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
          Icon(
            icon,
            color: const Color(0xFF39A4E6),
            size: 24,
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildHistoryList() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF0F2137) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'History',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          ..._trendData.reversed.map((data) {
            final isNormal = data.isNormal;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDateFull(data.date),
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: widget.isDarkMode ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isNormal
                          ? const Color(0xFF10B981).withOpacity(0.15)
                          : const Color(0xFFEF4444).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${data.rawValue} ${data.unit ?? ''}',
                      style: GoogleFonts.outfit(
                        color: isNormal
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
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
      return DateFormat('E, MMM d, y').format(date);
    } catch (_) {
      return isoDate;
    }
  }
}

