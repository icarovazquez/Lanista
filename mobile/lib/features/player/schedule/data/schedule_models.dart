class PlayerEvent {
  final String id;
  final String playerId;
  final String eventType; // 'game' | 'showcase'
  final String title;
  final DateTime eventDate;
  final String? location;
  final String? competition;
  final String? notes;
  final String? eventTime; // stored as "HH:MM" 24h string, nullable
  final DateTime createdAt;

  const PlayerEvent({
    required this.id,
    required this.playerId,
    required this.eventType,
    required this.title,
    required this.eventDate,
    this.location,
    this.competition,
    this.notes,
    this.eventTime,
    required this.createdAt,
  });

  factory PlayerEvent.fromMap(Map<String, dynamic> m) => PlayerEvent(
        id: m['id'] as String,
        playerId: m['player_id'] as String,
        eventType: m['event_type'] as String,
        title: m['title'] as String,
        eventDate: DateTime.parse(m['event_date'] as String),
        location: m['location'] as String?,
        competition: m['competition'] as String?,
        notes: m['notes'] as String?,
        eventTime: m['event_time'] as String?,
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  /// Returns a display string like "2:30 PM" from a "14:30:00" DB time string.
  String? get displayTime {
    if (eventTime == null) return null;
    try {
      final parts = eventTime!.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final displayMin = minute.toString().padLeft(2, '0');
      return '$displayHour:$displayMin $period';
    } catch (_) {
      return null;
    }
  }

  bool get isShowcase => eventType == 'showcase';
  bool get isGame => eventType == 'game';

  bool get isUpcoming =>
      eventDate.isAfter(DateTime.now().subtract(const Duration(days: 1)));

  String get typeLabel => isShowcase ? 'Showcase' : 'Game';
  String get typeEmoji => isShowcase ? '🏆' : '⚽';
}

/// Format a date as "Mon, Mar 15" or "Mon, Mar 15, 2026"
String formatEventDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final weekday = days[date.weekday - 1];
  final month = months[date.month - 1];
  final now = DateTime.now();
  final showYear = date.year != now.year;
  return showYear
      ? '$weekday, $month ${date.day}, ${date.year}'
      : '$weekday, $month ${date.day}';
}
