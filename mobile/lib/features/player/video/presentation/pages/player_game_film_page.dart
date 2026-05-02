import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/video_models.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/player_colors.dart';
import '../../../../../../core/theme/player_theme_scope.dart';
import '../../../../../../core/di/injection.dart';
import 'player_game_film_add_page.dart';

class PlayerGameFilmPage extends StatefulWidget {
  const PlayerGameFilmPage({super.key});

  @override
  State<PlayerGameFilmPage> createState() => _PlayerGameFilmPageState();
}

class _PlayerGameFilmPageState extends State<PlayerGameFilmPage> {
  final _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _playerId;
  List<PlayerVideo> _films = [];

  @override
  void initState() {
    super.initState();
    _loadFilms();
  }

  Future<void> _loadFilms() async {
    setState(() => _loading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final playerRow = await _supabase
          .from('players')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (playerRow == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      _playerId = playerRow['id'] as String;

      final rows = await _supabase
          .from('player_videos')
          .select('*')
          .eq('player_id', _playerId!)
          .eq('video_type', 'game_film')
          .order('uploaded_at', ascending: false);

      if (mounted) {
        setState(() {
          _films = (rows as List).map((r) => PlayerVideo.fromMap(r)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load game film: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteFilm(PlayerVideo film) async {
    final isDark = PlayerThemeScope.isDark(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? PlayerColors.surfaceElevated : Colors.white,
        title: Text('Delete Game Film?',
            style: TextStyle(color: isDark ? PlayerColors.textPrimary : null)),
        content: Text('Remove "${film.displayTitle}"?',
            style: TextStyle(color: isDark ? PlayerColors.textSecondary : null)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: isDark ? PlayerColors.textSecondary : null)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: isDark ? PlayerColors.error : AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _supabase.from('player_videos').delete().eq('id', film.id);
      await _loadFilms();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not delete: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _openFilm(PlayerVideo film) async {
    final url = film.externalUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open video link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = getIt<PlayerThemeService>();
    return PlayerThemeScope(
      service: themeService,
      child: _GameFilmContent(
        loading: _loading,
        films: _films,
        playerId: _playerId,
        onOpen: _openFilm,
        onDelete: _deleteFilm,
        onRefresh: _loadFilms,
      ),
    );
  }
}

class _GameFilmContent extends StatelessWidget {
  final bool loading;
  final List<PlayerVideo> films;
  final String? playerId;
  final Future<void> Function(PlayerVideo) onOpen;
  final Future<void> Function(PlayerVideo) onDelete;
  final Future<void> Function() onRefresh;

  const _GameFilmContent({
    required this.loading,
    required this.films,
    required this.playerId,
    required this.onOpen,
    required this.onDelete,
    required this.onRefresh,
  });

  void _addFilm(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerGameFilmAddPage(playerId: playerId ?? ''),
      ),
    );
    onRefresh();
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
        title: const Text('Game Film',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accent,
        foregroundColor: isDark ? PlayerColors.textOnAccent : Colors.white,
        onPressed: () => _addFilm(context),
        child: const Icon(Icons.add),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(
              color: isDark ? PlayerColors.accent : AppColors.primary))
          : films.isEmpty
              ? _EmptyState(onAdd: () => _addFilm(context))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: films.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final film = films[index];
                    return _FilmCard(
                      film: film,
                      onTap: () => onOpen(film),
                      onLongPress: () => onDelete(film),
                    );
                  },
                ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    final accent = isDark ? PlayerColors.accent : AppColors.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: isDark ? PlayerColors.accentSubtle : AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🎥', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No game film yet',
              style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Download your game from Taka, Trace, or your club platform and upload it to YouTube, then add the link here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14, height: 1.5,
                color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Game Film'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: isDark ? PlayerColors.textOnAccent : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Film Card ──────────────────────────────────────────────────────────────────

class _FilmCard extends StatelessWidget {
  final PlayerVideo film;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _FilmCard({
    required this.film,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    final cardBg = isDark ? PlayerColors.surface : Colors.white;
    final cardBorder = isDark ? PlayerColors.border : AppColors.border;
    final accent = isDark ? PlayerColors.accent : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: _Thumbnail(thumbnailUrl: film.thumbnailUrl),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SourceBadge(label: film.sourceLabel),
                    const SizedBox(height: 6),
                    Text(
                      film.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.play_circle_outline, size: 14, color: accent),
                        const SizedBox(width: 4),
                        Text('Tap to watch',
                            style: TextStyle(fontSize: 12, color: accent,
                                fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Text('Hold to delete',
                            style: TextStyle(fontSize: 11,
                                color: isDark ? PlayerColors.textTertiary
                                    : AppColors.textTertiary)),
                      ],
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
}

class _Thumbnail extends StatelessWidget {
  final String? thumbnailUrl;
  const _Thumbnail({this.thumbnailUrl});

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: thumbnailUrl!,
        width: 100, height: 80,
        fit: BoxFit.cover,
        placeholder: (_, __) => _PlaceholderBox(isDark: isDark),
        errorWidget: (_, __, ___) => _PlaceholderBox(isDark: isDark),
      );
    }
    return _PlaceholderBox(isDark: isDark);
  }
}

class _PlaceholderBox extends StatelessWidget {
  final bool isDark;
  const _PlaceholderBox({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100, height: 80,
      color: isDark ? PlayerColors.surfaceVariant : AppColors.primaryContainer,
      child: Center(
        child: Icon(Icons.videocam_outlined,
            color: isDark ? PlayerColors.accent : AppColors.primary, size: 32),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final String label;
  const _SourceBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    final accent = isDark ? PlayerColors.accent : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? PlayerColors.accentSubtle : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent),
      ),
    );
  }
}
