import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/player_colors.dart';
import '../../../../../core/theme/player_theme_scope.dart';
import 'conversation_detail_page.dart';

/// Conversations list — shows all active threads for the current user.
/// Works for both players (dark mode via PlayerThemeScope) and coaches (light).
class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _subscribeToRealtime();
  }

  void _subscribeToRealtime() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    _channel = Supabase.instance.client
        .channel('conversations:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (_) => _loadConversations(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final userData = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();
      final role = userData['role'] as String?;

      List<Map<String, dynamic>> data;

      if (role == 'player') {
        final playerRow = await Supabase.instance.client
            .from('players')
            .select('id')
            .eq('user_id', userId)
            .maybeSingle();
        final playerId = playerRow?['id'] as String?;
        if (playerId == null) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
        data = await Supabase.instance.client
            .from('conversations')
            .select('''
              id, contact_window_valid, created_at,
              coaches!inner(id, school_name, division,
                users!inner(first_name, last_name)),
              messages(body, created_at, sender_id, read_at)
            ''')
            .eq('player_id', playerId)
            .order('created_at', ascending: false);
      } else {
        data = await Supabase.instance.client
            .from('conversations')
            .select('''
              id, contact_window_valid, created_at,
              players!inner(user_id,
                users!inner(first_name, last_name)),
              messages(body, created_at, sender_id, read_at)
            ''')
            .order('created_at', ascending: false);
      }

      if (mounted) {
        setState(() {
          _conversations = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    final accentColor = isDark ? PlayerColors.accent : AppColors.primary;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }

    if (_conversations.isEmpty) {
      return _EmptyConversations(isDark: isDark);
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: accentColor,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _conversations.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 72,
          color: isDark ? PlayerColors.border : null,
        ),
        itemBuilder: (context, index) {
          final convo = _conversations[index];
          final coach = convo['coaches'] as Map<String, dynamic>?;
          final player = convo['players'] as Map<String, dynamic>?;
          String otherUserId = '';
          String otherUserName = '';
          String otherUserRole = '';

          if (coach != null) {
            final coachUser = coach['users'] as Map<String, dynamic>? ?? {};
            otherUserId = coach['id'] as String? ?? '';
            otherUserName =
                'Coach ${coachUser['first_name'] ?? ''} ${coachUser['last_name'] ?? ''}'
                    .trim();
            otherUserRole = 'coach';
          } else if (player != null) {
            final playerUser = player['users'] as Map<String, dynamic>? ?? {};
            otherUserId = player['user_id'] as String? ?? '';
            otherUserName =
                '${playerUser['first_name'] ?? ''} ${playerUser['last_name'] ?? ''}'
                    .trim();
            otherUserRole = 'player';
          }

          return _ConversationTile(
            conversation: convo,
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ConversationDetailPage(
                  conversationId: convo['id'] as String,
                  otherUserId: otherUserId,
                  otherUserName: otherUserName,
                  otherUserRole: otherUserRole,
                  isDark: isDark,
                ),
              ),
            ).then((_) => _loadConversations()),
          );
        },
      ),
    );
  }
}

class _EmptyConversations extends StatelessWidget {
  final bool isDark;
  const _EmptyConversations({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark ? PlayerColors.accent : AppColors.primary;
    final textPri = isDark ? PlayerColors.textPrimary : AppColors.textPrimary;
    final textSec = isDark ? PlayerColors.textSecondary : AppColors.textSecondary;
    final cardBg = isDark ? PlayerColors.surface : AppColors.surface;
    final avatarBg = isDark
        ? PlayerColors.accent.withValues(alpha: 0.12)
        : AppColors.primaryContainer;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: avatarBg, shape: BoxShape.circle),
              child: const Center(child: Text('💬', style: TextStyle(fontSize: 36))),
            ),
            const SizedBox(height: 20),
            Text('No Messages Yet',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: textPri)),
            const SizedBox(height: 8),
            Text(
              'When a college coach reaches out — or when you message a coach — conversations will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textSec, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: isDark ? Border.all(color: PlayerColors.border) : null,
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'NCAA rules limit when coaches can contact players. Lanista enforces contact windows automatically.',
                      style: TextStyle(fontSize: 11, color: textSec, height: 1.4),
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

class _ConversationTile extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final VoidCallback onTap;
  final bool isDark;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final coach = conversation['coaches'] as Map<String, dynamic>?;
    final player = conversation['players'] as Map<String, dynamic>?;

    String name;
    String subtitle;

    if (coach != null) {
      final u = coach['users'] as Map<String, dynamic>? ?? {};
      name = 'Coach ${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim();
      subtitle = coach['school_name'] as String? ?? 'Unknown Program';
    } else if (player != null) {
      final u = player['users'] as Map<String, dynamic>? ?? {};
      name = '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim();
      subtitle = 'Player';
    } else {
      name = 'Unknown';
      subtitle = '';
    }

    final messages =
        (conversation['messages'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    messages.sort((a, b) {
      final aTime =
          DateTime.tryParse(a['created_at'] as String? ?? '') ?? DateTime(2000);
      final bTime =
          DateTime.tryParse(b['created_at'] as String? ?? '') ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });
    final latestMsg = messages.isNotEmpty ? messages.first : null;
    final latestContent =
        latestMsg?['body'] as String? ?? 'Start the conversation...';
    final isRead = latestMsg?['read_at'] != null;
    final isContactValid = conversation['contact_window_valid'] as bool? ?? true;

    final accentColor = isDark ? PlayerColors.accent : AppColors.primary;
    final textPri = isDark ? PlayerColors.textPrimary : AppColors.textPrimary;
    final textSec = isDark ? PlayerColors.textSecondary : AppColors.textSecondary;
    final avatarBg = isDark
        ? PlayerColors.accent.withValues(alpha: 0.12)
        : AppColors.primary.withValues(alpha: 0.1);
    final windowBadgeBg = isDark
        ? PlayerColors.gradientEnd.withValues(alpha: 0.15)
        : AppColors.secondary.withValues(alpha: 0.15);
    final windowBadgeText = isDark ? PlayerColors.gradientEnd : AppColors.secondary;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: avatarBg,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
              color: accentColor, fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                  fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                  fontSize: 14,
                  color: textPri),
            ),
          ),
          if (!isContactValid)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: windowBadgeBg, borderRadius: BorderRadius.circular(4)),
              child: Text('Contact Window',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: windowBadgeText)),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: TextStyle(fontSize: 11, color: textSec)),
          const SizedBox(height: 2),
          Text(
            latestContent,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isRead ? textSec : textPri,
              fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
            ),
          ),
        ],
      ),
      trailing: isRead
          ? null
          : Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: accentColor),
            ),
    );
  }
}
