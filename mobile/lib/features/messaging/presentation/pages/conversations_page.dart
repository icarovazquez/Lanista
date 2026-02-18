import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_colors.dart';
import 'conversation_detail_page.dart';

/// Conversations list — shows all active threads for the current user.
/// Works for both players (conversations with coaches) and coaches (with players).
class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _subscribeToRealtime();
  }

  RealtimeChannel? _channel;

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

      // Load user role first
      final userData = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();
      final role = userData['role'] as String?;

      List<Map<String, dynamic>> data;

      if (role == 'player') {
        data = await Supabase.instance.client
            .from('conversations')
            .select('''
              id,
              contact_window_valid,
              created_at,
              coaches!inner(
                id,
                school_name,
                division,
                users!inner(first_name, last_name)
              ),
              messages(
                content,
                created_at,
                sender_id,
                is_read
              )
            ''')
            .eq('player_id', userId)
            .order('created_at', ascending: false);
      } else {
        // Coach or parent view
        data = await Supabase.instance.client
            .from('conversations')
            .select('''
              id,
              contact_window_valid,
              created_at,
              players!inner(
                user_id,
                users!inner(first_name, last_name)
              ),
              messages(
                content,
                created_at,
                sender_id,
                is_read
              )
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_conversations.isEmpty) {
      return const _EmptyConversations();
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _conversations.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final convo = _conversations[index];
          // Extract the other party's info for the detail page
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ConversationDetailPage(
                  conversationId: convo['id'] as String,
                  otherUserId: otherUserId,
                  otherUserName: otherUserName,
                  otherUserRole: otherUserRole,
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
  const _EmptyConversations();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('💬', style: TextStyle(fontSize: 36))),
            ),
            const SizedBox(height: 20),
            const Text('No Messages Yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'When a college coach reaches out — or when you message a coach — conversations will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'NCAA rules limit when coaches can contact players. Lanista enforces contact windows automatically.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
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

  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Extract coach or player info
    final coach = conversation['coaches'] as Map<String, dynamic>?;
    final player = conversation['players'] as Map<String, dynamic>?;

    String name;
    String subtitle;

    if (coach != null) {
      final coachUser = coach['users'] as Map<String, dynamic>? ?? {};
      name = 'Coach ${coachUser['first_name'] ?? ''} ${coachUser['last_name'] ?? ''}'.trim();
      subtitle = coach['school_name'] as String? ?? 'Unknown Program';
    } else if (player != null) {
      final playerUser = player['users'] as Map<String, dynamic>? ?? {};
      name = '${playerUser['first_name'] ?? ''} ${playerUser['last_name'] ?? ''}'.trim();
      subtitle = 'Player';
    } else {
      name = 'Unknown';
      subtitle = '';
    }

    // Get latest message
    final messages = (conversation['messages'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    messages.sort((a, b) {
      final aTime = DateTime.tryParse(a['created_at'] as String? ?? '') ?? DateTime(2000);
      final bTime = DateTime.tryParse(b['created_at'] as String? ?? '') ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });
    final latestMsg = messages.isNotEmpty ? messages.first : null;
    final latestContent = latestMsg?['content'] as String? ?? 'Start the conversation...';
    final isRead = latestMsg?['is_read'] as bool? ?? true;
    final isContactValid = conversation['contact_window_valid'] as bool? ?? true;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
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
              ),
            ),
          ),
          if (!isContactValid)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Contact Window',
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.secondary),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            latestContent,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isRead ? AppColors.textSecondary : AppColors.textPrimary,
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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
            ),
    );
  }
}
