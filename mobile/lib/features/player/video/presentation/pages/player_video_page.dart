import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/video_models.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/player_colors.dart';
import '../../../../../../core/theme/player_theme_scope.dart';
import 'player_video_add_page.dart';

class PlayerVideoPage extends StatefulWidget {
  const PlayerVideoPage({super.key});

  @override
  State<PlayerVideoPage> createState() => _PlayerVideoPageState();
}

class _PlayerVideoPageState extends State<PlayerVideoPage> {
  final _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _playerId;
  List<PlayerVideo> _videos = [];

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
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
          .eq('video_type', 'highlight')
          .order('is_primary', ascending: false)
          .order('uploaded_at', ascending: false);

      if (mounted) {
        setState(() {
          _videos = (rows as List).map((r) => PlayerVideo.fromMap(r)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load videos: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteVideo(PlayerVideo video) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Video?'),
        content: Text(
            'Remove "${video.displayTitle}" from your highlights?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _supabase.from('player_videos').delete().eq('id', video.id);
      await _loadVideos();
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

  Future<void> _openVideo(PlayerVideo video) async {
    // Prefer Mux stream URL, fall back to external URL
    final url = video.streamUrl ?? video.externalUrl;
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
    final isDark = PlayerThemeScope.isDark(context);
    return Scaffold(
      backgroundColor: isDark ? PlayerColors.background : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? PlayerColors.accent : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Highlights',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: isDark ? PlayerColors.accent : AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlayerVideoAddPage(playerId: _playerId ?? ''),
            ),
          );
          _loadVideos();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: isDark ? PlayerColors.accent : AppColors.primary))
          : _videos.isEmpty
              ? _EmptyState(
                  onAdd: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            PlayerVideoAddPage(playerId: _playerId ?? ''),
                      ),
                    );
                    _loadVideos();
                  },
                  isDark: isDark,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _videos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final video = _videos[index];
                    return _VideoCard(
                      video: video,
                      onTap: () => _openVideo(video),
                      onLongPress: () => _deleteVideo(video),
                      isDark: isDark,
                    );
                  },
                ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  final bool isDark;
  const _EmptyState({required this.onAdd, required this.isDark});

  @override
  Widget build(BuildContext context) {
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
                color: isDark ? PlayerColors.gradientStart.withValues(alpha: 0.15) : AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🎬', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No highlights yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your Hudl reel, YouTube highlights, or any video link so coaches can watch you play.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? PlayerColors.textSecondary : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Your First Video'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? PlayerColors.accent : AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Video Card ─────────────────────────────────────────────────────────────────

class _VideoCard extends StatelessWidget {
  final PlayerVideo video;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isDark;

  const _VideoCard({
    required this.video,
    required this.onTap,
    required this.onLongPress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? PlayerColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? PlayerColors.border : AppColors.border),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16)),
              child: _Thumbnail(thumbnailUrl: video.thumbnailUrl, isDark: isDark),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (video.isPrimary) ...[
                          const Text('⭐',
                              style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                        ],
                        _SourceBadge(label: video.sourceLabel, isDark: isDark),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      video.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.play_circle_outline,
                            size: 14, color: isDark ? PlayerColors.accent : AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Tap to watch',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? PlayerColors.accent : AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Hold to delete',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? PlayerColors.textTertiary : AppColors.textTertiary,
                          ),
                        ),
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
  final bool isDark;
  const _Thumbnail({this.thumbnailUrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: thumbnailUrl!,
        width: 100,
        height: 80,
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
      width: 100,
      height: 80,
      color: isDark ? PlayerColors.gradientStart.withValues(alpha: 0.15) : AppColors.primaryContainer,
      child: Center(
        child: Icon(Icons.play_circle_outline,
            color: isDark ? PlayerColors.accent : AppColors.primary, size: 32),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SourceBadge({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isDark ? PlayerColors.accent : AppColors.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? PlayerColors.accent : AppColors.primary,
        ),
      ),
    );
  }
}
