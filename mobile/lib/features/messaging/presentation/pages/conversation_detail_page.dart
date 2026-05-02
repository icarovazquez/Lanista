import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/player_colors.dart';

class ConversationDetailPage extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserRole; // 'player' | 'coach'
  /// Pass true when opened from a player-side page to apply Design D dark theme.
  final bool isDark;

  const ConversationDetailPage({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserRole,
    this.isDark = false,
  });

  @override
  State<ConversationDetailPage> createState() => _ConversationDetailPageState();
}

class _ConversationDetailPageState extends State<ConversationDetailPage> {
  final _supabase = Supabase.instance.client;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Message> _messages = [];
  RealtimeChannel? _channel;
  bool _isLoading = true;
  bool _isSending = false;
  String? _currentUserId;
  bool _isContactWindowOpen = true;
  bool _requiresParentApproval = false;

  bool get _d => widget.isDark;

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabase.auth.currentUser?.id;
    _loadMessages();
    _subscribeToMessages();
    _checkContactWindow();
    _checkParentApproval();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final data = await _supabase
          .from('messages')
          .select()
          .eq('conversation_id', widget.conversationId)
          .order('sent_at', ascending: true);

      if (mounted) {
        setState(() {
          _messages.clear();
          for (final row in data as List) {
            _messages.add(_Message.fromMap(row));
          }
          _isLoading = false;
        });
        _scrollToBottom();
      }

      // Mark incoming messages as read — skip if we don't have current user yet
      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        await _supabase
            .from('messages')
            .update({'is_read': true})
            .eq('conversation_id', widget.conversationId)
            .neq('sender_id', _currentUserId!)
            .catchError((_) {}); // non-critical, ignore errors
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToMessages() {
    _channel = _supabase
        .channel('messages:${widget.conversationId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: widget.conversationId,
          ),
          callback: (payload) {
            final msg = _Message.fromMap(payload.newRecord);
            // Skip if already added locally (our own sent message)
            if (mounted && !_messages.any((m) => m.id == msg.id)) {
              setState(() => _messages.add(msg));
              _scrollToBottom();
            }
          },
        )
        .subscribe();
  }

  Future<void> _checkContactWindow() async {
    try {
      final data = await _supabase
          .from('conversations')
          .select('contact_window_valid')
          .eq('id', widget.conversationId)
          .maybeSingle();
      if (mounted && data != null) {
        setState(() {
          _isContactWindowOpen = data['contact_window_valid'] as bool? ?? true;
        });
      }
    } catch (_) {}
  }

  Future<void> _checkParentApproval() async {
    if (widget.otherUserRole != 'player') return;
    try {
      final data = await _supabase
          .from('players')
          .select('birth_year')
          .eq('user_id', widget.otherUserId)
          .maybeSingle();
      if (mounted && data != null) {
        final birthYear = data['birth_year'] as int?;
        if (birthYear != null) {
          final age = DateTime.now().year - birthYear;
          setState(() => _requiresParentApproval = age < 18);
        }
      }
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;
    if (!_isContactWindowOpen) {
      _showContactWindowClosed();
      return;
    }
    // Reload user ID in case session wasn't ready at initState time
    _currentUserId ??= _supabase.auth.currentUser?.id;
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired — please log in again')),
        );
      }
      return;
    }

    setState(() => _isSending = true);
    _textController.clear();

    try {
      final result = await _supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': _currentUserId,
        'body': text,
        'content': text,
        'requires_parent_approval': _requiresParentApproval,
      }).select().single();

      // Add locally immediately so it shows without relying on realtime
      if (mounted) {
        final msg = _Message.fromMap(result);
        setState(() => _messages.add(msg));
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        _textController.text = text;
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showContactWindowClosed() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _d ? PlayerColors.surfaceElevated : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Text('🚫', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text('Contact Window Closed',
                style: TextStyle(
                    color: _d ? PlayerColors.textPrimary : AppColors.textPrimary)),
          ],
        ),
        content: Text(
          'NCAA regulations prohibit contact during this period. '
          'Coaches may contact recruits starting September 1 of their junior year.',
          style: TextStyle(
              fontSize: 14,
              color: _d ? PlayerColors.textSecondary : AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Understood',
                style: TextStyle(
                    color: _d ? PlayerColors.accent : AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _d ? PlayerColors.background : AppColors.background,
      resizeToAvoidBottomInset: false,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (!_isContactWindowOpen) _ContactWindowBanner(),
          if (_requiresParentApproval) _ParentApprovalBanner(),
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _d ? PlayerColors.surfaceElevated : AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back,
            color: _d ? PlayerColors.textPrimary : AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: widget.otherUserRole == 'coach'
                ? (_d
                    ? PlayerColors.gradientStart.withValues(alpha: 0.2)
                    : AppColors.coachColor.withValues(alpha: 0.15))
                : (_d
                    ? PlayerColors.accent.withValues(alpha: 0.15)
                    : AppColors.primaryContainer),
            child: Text(
              widget.otherUserName.isNotEmpty
                  ? widget.otherUserName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: widget.otherUserRole == 'coach'
                    ? (_d ? PlayerColors.gradientStart : AppColors.coachColor)
                    : (_d ? PlayerColors.accent : AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.otherUserName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _d ? PlayerColors.textPrimary : AppColors.textPrimary,
                ),
              ),
              Text(
                widget.otherUserRole == 'coach' ? 'College Coach' : 'Player',
                style: TextStyle(
                  fontSize: 11,
                  color: _d ? PlayerColors.textSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.info_outline,
              color: _d ? PlayerColors.textSecondary : AppColors.textSecondary),
          onPressed: _showConversationInfo,
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
            color: _d ? PlayerColors.accent : AppColors.primary),
      );
    }
    if (_messages.isEmpty) return _buildEmptyChat();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMe = msg.senderId == _currentUserId;
        final showDate = index == 0 ||
            !_isSameDay(_messages[index - 1].createdAt, msg.createdAt);
        return Column(
          children: [
            if (showDate) _DateDivider(date: msg.createdAt, isDark: _d),
            _MessageBubble(
              message: msg,
              isMe: isMe,
              isDark: _d,
              otherUserName: widget.otherUserName,
              accentColor: widget.otherUserRole == 'coach'
                  ? (_d ? PlayerColors.gradientStart : AppColors.coachColor)
                  : (_d ? PlayerColors.accent : AppColors.primary),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _d
                    ? PlayerColors.accent.withValues(alpha: 0.12)
                    : AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('👋', style: TextStyle(fontSize: 36))),
            ),
            const SizedBox(height: 20),
            Text(
              'Start the conversation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _d ? PlayerColors.textPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Introduce yourself to ${widget.otherUserName}. Keep it professional and highlight what makes you a great fit.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: _d ? PlayerColors.textSecondary : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _d ? PlayerColors.surfaceVariant : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '💡 Tip: Coaches receive hundreds of messages. Mention your position, graduation year, and one specific reason you\'re interested in their program.',
                style: TextStyle(
                  fontSize: 12,
                  color: _d ? PlayerColors.textSecondary : AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final borderClr = _d ? PlayerColors.border : AppColors.border;
    final sendBtnClr = _isContactWindowOpen
        ? (_d ? PlayerColors.accent : AppColors.primary)
        : borderClr;

    return Container(
      decoration: BoxDecoration(
        color: _d ? PlayerColors.surfaceElevated : AppColors.surface,
        border: Border(top: BorderSide(color: borderClr)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: _d ? PlayerColors.surface : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
                border: _d ? Border.all(color: borderClr, width: 0.5) : null,
              ),
              child: TextField(
                controller: _textController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  fontSize: 14,
                  color: _d ? PlayerColors.textPrimary : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: _isContactWindowOpen
                      ? 'Type a message…'
                      : 'Contact window closed',
                  hintStyle: TextStyle(
                    color: _d ? PlayerColors.textSecondary : AppColors.textTertiary,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                enabled: _isContactWindowOpen,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isSending
                ? SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _d ? PlayerColors.accent : AppColors.primary,
                        ),
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: sendBtnClr,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        color: _d ? PlayerColors.textOnAccent : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showConversationInfo() {
    final sheetBg = _d ? PlayerColors.surfaceElevated : Colors.white;
    final handleClr = _d ? PlayerColors.border : AppColors.border;
    final titleClr = _d ? PlayerColors.textPrimary : AppColors.textPrimary;
    final labelClr = _d ? PlayerColors.textSecondary : AppColors.textSecondary;
    final tipBg = _d
        ? PlayerColors.gradientStart.withValues(alpha: 0.1)
        : AppColors.primaryContainer;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: handleClr, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('NCAA Recruiting Rules',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: titleClr)),
            const SizedBox(height: 12),
            _InfoRow(
              icon: '📅',
              label: 'Contact Window',
              value: _isContactWindowOpen ? 'Open ✅' : 'Closed 🚫',
              valueColor: _isContactWindowOpen ? AppColors.success : AppColors.error,
              labelColor: labelClr,
              titleColor: titleClr,
            ),
            _InfoRow(
              icon: '👨‍👩‍👧',
              label: 'Parent Approval',
              value: _requiresParentApproval ? 'Required' : 'Not required',
              labelColor: labelClr,
              titleColor: titleClr,
            ),
            _InfoRow(
              icon: '📋',
              label: 'Contact Type',
              value: 'Recruiting Contact',
              labelColor: labelClr,
              titleColor: titleClr,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration:
                  BoxDecoration(color: tipBg, borderRadius: BorderRadius.circular(12)),
              child: Text(
                'NCAA D1 rules: Coaches may not initiate contact with a player before September 1 of their junior year of high school. Players may contact coaches at any time.',
                style: TextStyle(fontSize: 12, color: labelClr, height: 1.4),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Sub-Widgets ──────────────────────────────────────────────────────────────

class _ContactWindowBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.error.withValues(alpha: 0.1),
      child: const Row(
        children: [
          Icon(Icons.block, color: AppColors.error, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'NCAA contact window is currently closed. Messaging is read-only.',
              style: TextStyle(
                  fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentApprovalBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.warning.withValues(alpha: 0.12),
      child: const Row(
        children: [
          Icon(Icons.family_restroom, color: AppColors.warning, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Messages to this minor require parent/guardian approval before delivery.',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _Message message;
  final bool isMe;
  final bool isDark;
  final Color accentColor;
  final String otherUserName;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isDark,
    required this.accentColor,
    required this.otherUserName,
  });

  @override
  Widget build(BuildContext context) {
    final myBubbleBg = isDark ? PlayerColors.accent : AppColors.primary;
    final theirBubbleBg = isDark ? PlayerColors.surface : AppColors.surface;
    final myTextClr = isDark ? PlayerColors.textOnAccent : Colors.white;
    final theirTextClr = isDark ? PlayerColors.textPrimary : AppColors.textPrimary;
    final borderClr = isDark ? PlayerColors.border : AppColors.border;
    final timeClr = isDark ? PlayerColors.textSecondary : AppColors.textTertiary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: accentColor.withValues(alpha: 0.15),
              child: Text(
                  otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: accentColor)),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? myBubbleBg : theirBubbleBg,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    border: isMe ? null : Border.all(color: borderClr),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    message.body,
                    style: TextStyle(
                        fontSize: 14,
                        color: isMe ? myTextClr : theirTextClr,
                        height: 1.4),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.requiresParentApproval && message.approvedAt == null)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Text('⏳', style: TextStyle(fontSize: 10)),
                      ),
                    Text(_formatTime(message.createdAt),
                        style: TextStyle(fontSize: 10, color: timeClr)),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.approvedAt != null || !message.requiresParentApproval
                            ? Icons.done_all
                            : Icons.access_time,
                        size: 12,
                        color: timeClr,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $period';
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime date;
  final bool isDark;
  const _DateDivider({required this.date, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final clr = isDark ? PlayerColors.textSecondary : AppColors.textTertiary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: clr.withValues(alpha: 0.4))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(_formatDate(date),
                style: TextStyle(
                    fontSize: 11, color: clr, fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Divider(color: clr.withValues(alpha: 0.4))),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(msgDay).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

class _InfoRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Color labelColor;
  final Color titleColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    required this.labelColor,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 13, color: labelColor))),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? titleColor)),
        ],
      ),
    );
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────

class _Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final bool requiresParentApproval;
  final DateTime? approvedAt;
  final DateTime createdAt;

  const _Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.requiresParentApproval,
    this.approvedAt,
    required this.createdAt,
  });

  factory _Message.fromMap(Map<String, dynamic> map) {
    return _Message(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      senderId: map['sender_id'] as String,
      body: map['body'] as String? ?? map['content'] as String? ?? '',
      requiresParentApproval: map['requires_parent_approval'] as bool? ?? false,
      approvedAt: map['approved_at'] != null
          ? DateTime.parse(map['approved_at'] as String)
          : null,
      createdAt: DateTime.parse(
          map['created_at'] as String? ?? map['sent_at'] as String),
    );
  }
}
