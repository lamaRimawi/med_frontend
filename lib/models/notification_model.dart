import 'package:intl/intl.dart';

class InAppNotification {
  final int id;
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  InAppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  factory InAppNotification.fromJson(Map<String, dynamic> json) {
    return InAppNotification(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'general',
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      data: json['data'] is Map<String, dynamic> ? json['data'] : null,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    // Handle clock skew if server time is slightly ahead of local time
    if (difference.inSeconds < 0) return 'Now';
    
    if (difference.inSeconds < 5) return 'Now';
    if (difference.inSeconds < 60) return '${difference.inSeconds}s ago';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';

    final nowDay = DateTime(now.year, now.month, now.day);
    final createdDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final dayDiff = nowDay.difference(createdDay).inDays;

    if (dayDiff == 1) return 'Yesterday';
    if (dayDiff < 7) return '$dayDiff days ago';
    
    return DateFormat('MMM d, y').format(createdAt);
  }
}
