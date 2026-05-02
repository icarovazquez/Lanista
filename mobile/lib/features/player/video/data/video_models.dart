class PlayerVideo {
  final String id;
  final String playerId;
  final String? title;
  final String? source;
  final String? externalUrl;
  final String? muxAssetId;
  final String? muxPlaybackId;
  final String? thumbnailUrl;
  final int? durationSecs;
  final String analysisStatus;
  final Map<String, dynamic>? analysisResult;
  final bool isPrimary;
  final DateTime uploadedAt;
  final String videoType; // 'highlight' | 'game_film'

  const PlayerVideo({
    required this.id,
    required this.playerId,
    this.title,
    this.source,
    this.externalUrl,
    this.muxAssetId,
    this.muxPlaybackId,
    this.thumbnailUrl,
    this.durationSecs,
    required this.analysisStatus,
    this.analysisResult,
    required this.isPrimary,
    required this.uploadedAt,
    this.videoType = 'highlight',
  });

  factory PlayerVideo.fromMap(Map<String, dynamic> m) => PlayerVideo(
        id: m['id'] as String,
        playerId: m['player_id'] as String,
        title: m['title'] as String?,
        source: m['source'] as String?,
        externalUrl: m['external_url'] as String?,
        muxAssetId: m['mux_asset_id'] as String?,
        muxPlaybackId: m['mux_playback_id'] as String?,
        thumbnailUrl: m['thumbnail_url'] as String?,
        durationSecs: m['duration_secs'] as int?,
        analysisStatus: m['analysis_status'] as String? ?? 'pending',
        analysisResult: m['analysis_result'] != null
            ? Map<String, dynamic>.from(m['analysis_result'] as Map)
            : null,
        isPrimary: m['is_primary'] as bool? ?? false,
        uploadedAt: DateTime.tryParse(m['uploaded_at'] as String? ?? '') ??
            DateTime.now(),
        videoType: m['video_type'] as String? ?? 'highlight',
      );

  String get sourceLabel {
    switch (source) {
      case 'hudl':
        return 'Hudl';
      case 'taka':
        return 'Taka';
      case 'youtube':
        return 'YouTube';
      case 'mux':
        return 'Mux';
      default:
        return 'Video';
    }
  }

  bool get isExternal => source != 'mux';

  String? get streamUrl => muxPlaybackId != null
      ? 'https://stream.mux.com/$muxPlaybackId.m3u8'
      : null;

  String get displayTitle {
    if (title?.isNotEmpty == true) return title!;
    return videoType == 'game_film' ? 'Full Game' : 'Highlight Reel';
  }
}

/// Detects the video source from a URL string.
String detectVideoSource(String url) {
  final lower = url.toLowerCase();
  if (lower.contains('youtube.com') || lower.contains('youtu.be')) {
    return 'youtube';
  } else if (lower.contains('hudl.com')) {
    return 'hudl';
  } else if (lower.contains('taka.com')) {
    return 'taka';
  }
  return 'other';
}

/// Extracts a YouTube thumbnail URL from a YouTube video URL.
/// Returns null if the URL is not a valid YouTube URL.
String? extractYoutubeThumbnail(String url) {
  final videoId = extractYoutubeVideoId(url);
  if (videoId == null) return null;
  return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
}

/// Extracts the YouTube video ID from various YouTube URL formats.
String? extractYoutubeVideoId(String url) {
  try {
    final uri = Uri.parse(url);
    // youtu.be/VIDEO_ID
    if (uri.host == 'youtu.be') {
      final id = uri.pathSegments.firstOrNull;
      return (id != null && id.isNotEmpty) ? id : null;
    }
    // youtube.com/watch?v=VIDEO_ID
    if (uri.host.contains('youtube.com')) {
      final v = uri.queryParameters['v'];
      if (v != null && v.isNotEmpty) return v;
      // youtube.com/embed/VIDEO_ID
      final segments = uri.pathSegments;
      final embedIdx = segments.indexOf('embed');
      if (embedIdx >= 0 && embedIdx + 1 < segments.length) {
        return segments[embedIdx + 1];
      }
    }
  } catch (_) {}
  return null;
}
