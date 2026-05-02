import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/player_colors.dart';
import '../../../../../core/theme/player_theme_scope.dart';

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
  return '${(diff.inDays / 365).floor()}y ago';
}

/// A notification item fetched from the `notifications` table.
class _Notification {
  final String id;
  final String type;
  final String title;
  final String? body;
  final bool isRead;
  final DateTime sentAt;

  const _Notification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    required this.isRead,
    required this.sentAt,
  });

  factory _Notification.fromMap(Map<String, dynamic> m) => _Notification(
        id: m['id'] as String,
        type: m['type'] as String? ?? 'general',
        title: m['title'] as String? ?? '',
        body: m['body'] as String?,
        isRead: m['is_read'] as bool? ?? false,
        sentAt: DateTime.tryParse(m['sent_at'] as String? ?? '') ?? DateTime.now(),
      );
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _supabase = Supabase.instance.client;
  bool _loading = true;
  List<_Notification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final rows = await _supabase
          .from('notifications')
          .select('id, type, title, body, is_read, sent_at')
          .eq('user_id', userId)
          .order('sent_at', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _notifications = (rows as List)
              .map((r) => _Notification.fromMap(r as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      }

      // Mark all unread as read
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'match':
      case 'new_match':
        return Icons.stars_rounded;
      case 'message':
        return Icons.chat_bubble_outline_rounded;
      case 'pipeline':
      case 'pipeline_move':
        return Icons.trending_up_rounded;
      case 'video':
      case 'video_ready':
        return Icons.play_circle_outline_rounded;
      case 'recruit':
      case 'recruiting':
        return Icons.school_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type, bool isDark) {
    switch (type) {
      case 'match':
      case 'new_match':
        return isDark ? PlayerColors.accent : AppColors.primary;
      case 'message':
        return const Color(0xFF818CF8); // indigo — visible on both themes
      case 'pipeline':
      case 'pipeline_move':
        return const Color(0xFF34D399); // green
      case 'video':
      case 'video_ready':
        return const Color(0xFFFBBF24); // amber
      case 'recruit':
      case 'recruiting':
        return const Color(0xFFF472B6); // pink
      default:
        return isDark ? PlayerColors.textSecondary : AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    final bg = isDark ? PlayerColors.background : AppColors.background;
    final appBarBg = isDark ? PlayerColors.surface : AppColors.primary;
    final accent = isDark ? PlayerColors.accent : AppColors.primary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : _notifications.isEmpty
              ? _buildEmpty(isDark, accent)
              : RefreshIndicator(
                  color: accent,
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 72,
                      color: isDark ? PlayerColors.border : AppColors.border,
                    ),
                    itemBuilder: (_, i) => _NotificationTile(
                      notification: _notifications[i],
                      iconData: _iconForType(_notifications[i].type),
                      iconColor: _colorForType(_notifications[i].type, isDark),
                      isDark: isDark,
                      accent: accent,
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmpty(bool isDark, Color accent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(Icons.notifications_none_rounded,
                    size: 40, color: accent),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ll be notified about new matches, messages, and recruiting activity.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final _Notification notification;
  final IconData iconData;
  final Color iconColor;
  final bool isDark;
  final Color accent;

  const _NotificationTile({
    required this.notification,
    required this.iconData,
    required this.iconColor,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    final tileBg = unread
        ? (isDark
            ? PlayerColors.surface.withValues(alpha: 0.6)
            : AppColors.primary.withValues(alpha: 0.04))
        : Colors.transparent;

    return Container(
      color: tileBg,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                  color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
                ),
              ),
            ),
            if (unread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notification.body != null && notification.body!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                notification.body!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _timeAgo(notification.sentAt),
              style: TextStyle(
                fontSize: 11,
                color: isDark ? PlayerColors.textTertiary : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
