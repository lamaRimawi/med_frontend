import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'quick_actions_grid.dart';

class QuickActionItem {
  final IconData icon;
  final String label;
  final Color color;

  const QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}

class QuickActionsWidget extends StatefulWidget {
  final Function(String) onActionTap;

  const QuickActionsWidget({
    super.key,
    required this.onActionTap,
  });

  @override
  State<QuickActionsWidget> createState() => _QuickActionsWidgetState();
}

class _QuickActionsWidgetState extends State<QuickActionsWidget> {
  String? _selectedAction;

  final List<QuickActionItem> _actions = [
    const QuickActionItem(
      icon: LucideIcons.heart,
      label: 'Favorite',
      color: Color(0xFFFF6B9D),
    ),
    const QuickActionItem(
      icon: LucideIcons.upload,
      label: 'Upload',
      color: Color(0xFF39A4E6),
    ),
    const QuickActionItem(
      icon: LucideIcons.clock,
      label: 'Timeline',
      color: Color(0xFFFFA726),
    ),
    const QuickActionItem(
      icon: LucideIcons.barChart3,
      label: 'Analytics',
      color: Color(0xFF66BB6A),
    ),
    const QuickActionItem(
      icon: LucideIcons.share2,
      label: 'Share',
      color: Color(0xFFAB47BC),
    ),
  ];

  void _showAllActions(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => QuickActionsGrid(
        onActionTap: (action) {
          Navigator.pop(context);
          widget.onActionTap(action);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(
                  color: Color(0xFF39A4E6),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () => _showAllActions(context),
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: Color(0xFF39A4E6),
                    fontSize: 14,
                  ),
                ),
              )
                  .animate(target: _selectedAction == 'See all' ? 1 : 0)
                  .scale(begin: const Offset(1, 1), end: const Offset(0.95, 0.95), duration: 100.ms),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _actions.asMap().entries.map((entry) {
              final index = entry.key;
              final action = entry.value;
              final isSelected = _selectedAction == action.label;

              return GestureDetector(
                onTapDown: (_) => setState(() => _selectedAction = action.label),
                onTapUp: (_) {
                  setState(() => _selectedAction = null);
                  widget.onActionTap(action.label);
                },
                onTapCancel: () => setState(() => _selectedAction = null),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: action.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: action.color.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            action.icon,
                            color: action.color,
                            size: 28,
                          ),
                          if (isSelected)
                            Container(
                              decoration: BoxDecoration(
                                color: action.color,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            )
                                .animate()
                                .scale(begin: const Offset(0, 0), end: const Offset(2, 2), duration: 600.ms)
                                .fadeOut(duration: 600.ms),
                        ],
                      ),
                    )
                        .animate(target: isSelected ? 1 : 0)
                        .scale(end: const Offset(0.9, 0.9), duration: 100.ms),
                    const SizedBox(height: 8),
                    Text(
                      action.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: (index * 100).ms)
                  .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut);
            }).toList(),
          ),
        ],
      ),
    );
  }
}
