import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum ReportBadgeVariant { defaultVariant, compact, iconOnly }

class ReportTypeBadge extends StatelessWidget {
  const ReportTypeBadge({
    super.key,
    required this.type,
    this.variant = ReportBadgeVariant.defaultVariant,
    this.size = BadgeSize.md,
    this.margin,
  });

  final String type;
  final ReportBadgeVariant variant;
  final BadgeSize size;
  final EdgeInsetsGeometry? margin;

  static const Map<String, _BadgeConfig> _config = {
    'Lab Results': _BadgeConfig(
      icon: LucideIcons.droplet,
      color: Color(0xFFFF6B9D),
      bg: Color(0x26FF6B9D),
    ),
    'Prescriptions': _BadgeConfig(
      icon: LucideIcons.pill,
      color: Color(0xFF6C63FF),
      bg: Color(0x266C63FF),
    ),
    'Imaging': _BadgeConfig(
      icon: LucideIcons.scan,
      color: Color(0xFF06B6D4),
      bg: Color(0x2606B6D4),
    ),
    'Vitals': _BadgeConfig(
      icon: LucideIcons.activity,
      color: Color(0xFFEF4444),
      bg: Color(0x26EF4444),
    ),
    'Pathology': _BadgeConfig(
      icon: LucideIcons.microscope,
      color: Color(0xFFFBBF24),
      bg: Color(0x26FBBF24),
    ),
    'Cardiology': _BadgeConfig(
      icon: LucideIcons.heartPulse,
      color: Color(0xFFEF4444),
      bg: Color(0x26EF4444),
    ),
    'Neurology': _BadgeConfig(
      icon: LucideIcons.brain,
      color: Color(0xFF14B8A6),
      bg: Color(0x2614B8A6),
    ),
    'Orthopedics': _BadgeConfig(
      icon: LucideIcons.bone,
      color: Color(0xFFF59E0B),
      bg: Color(0x26F59E0B),
    ),
    'General': _BadgeConfig(
      icon: LucideIcons.stethoscope,
      color: Color(0xFF10B981),
      bg: Color(0x2610B981),
    ),
    'Temperature': _BadgeConfig(
      icon: LucideIcons.thermometer,
      color: Color(0xFFF97316),
      bg: Color(0x26F97316),
    ),
    'Respiratory': _BadgeConfig(
      icon: LucideIcons.wind,
      color: Color(0xFF06B6D4),
      bg: Color(0x2606B6D4),
    ),
  };

  _BadgeConfig get _resolvedConfig => _config[type] ?? _config['General']!;

  @override
  Widget build(BuildContext context) {
    final cfg = _resolvedConfig;
    final dims = size == BadgeSize.sm
        ? _BadgeDims(icon: 14, padH: 10, padV: 6, textSize: 11)
        : _BadgeDims(icon: 16, padH: 12, padV: 8, textSize: 13);

    switch (variant) {
      case ReportBadgeVariant.iconOnly:
        return Container(
          margin: margin,
          width: size == BadgeSize.sm ? 28 : 32,
          height: size == BadgeSize.sm ? 28 : 32,
          decoration: BoxDecoration(
            color: cfg.bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(cfg.icon, size: dims.icon.toDouble(), color: cfg.color),
        );
      case ReportBadgeVariant.compact:
        return Container(
          margin: margin,
          padding: EdgeInsets.symmetric(
            horizontal: dims.padH.toDouble(),
            vertical: dims.padV.toDouble(),
          ),
          decoration: BoxDecoration(
            color: cfg.bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(cfg.icon, size: dims.icon.toDouble(), color: cfg.color),
              const SizedBox(width: 6),
              Text(
                type,
                style: TextStyle(
                  fontSize: dims.textSize.toDouble(),
                  fontWeight: FontWeight.w600,
                  color: cfg.color,
                ),
              ),
            ],
          ),
        );
      case ReportBadgeVariant.defaultVariant:
        return Container(
          margin: margin,
          padding: EdgeInsets.symmetric(
            horizontal: dims.padH.toDouble() + 2,
            vertical: dims.padV.toDouble() + 2,
          ),
          decoration: BoxDecoration(
            color: cfg.bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(cfg.icon, size: dims.icon.toDouble(), color: cfg.color),
              const SizedBox(width: 8),
              Text(
                type,
                style: TextStyle(
                  fontSize: (dims.textSize + 1).toDouble(),
                  fontWeight: FontWeight.w600,
                  color: cfg.color,
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _BadgeConfig {
  const _BadgeConfig({
    required this.icon,
    required this.color,
    required this.bg,
  });
  final IconData icon;
  final Color color;
  final Color bg;
}

enum BadgeSize { sm, md }

class _BadgeDims {
  const _BadgeDims({
    required this.icon,
    required this.padH,
    required this.padV,
    required this.textSize,
  });
  final int icon;
  final int padH;
  final int padV;
  final int textSize;
}
