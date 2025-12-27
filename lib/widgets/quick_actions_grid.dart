import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'quick_actions_widget.dart'; // For QuickActionItem definition

class QuickActionsGrid extends StatelessWidget {
  final Function(String) onActionTap;

  const QuickActionsGrid({
    super.key,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final List<QuickActionItem> allActions = [
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
      const QuickActionItem(
        icon: LucideIcons.scanLine,
        label: 'Scan',
        color: Color(0xFFFF4081),
      ),
      const QuickActionItem(
        icon: LucideIcons.settings,
        label: 'Settings',
        color: Color(0xFF607D8B),
      ),
      const QuickActionItem(
        icon: LucideIcons.bell,
        label: 'Alerts',
        color: Color(0xFFFF9800),
      ),
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF0F2137) : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.x,
                      size: 20,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 24,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: allActions.length,
              itemBuilder: (context, index) {
                final action = allActions[index];
                return GestureDetector(
                  onTap: () => onActionTap(action.label),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: action.color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          action.icon,
                          color: action.color,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        action.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
