import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/video_models.dart';
import '../../data/mux_upload_service.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/player_colors.dart';
import '../../../../../../core/theme/player_theme_scope.dart';

class PlayerVideoAddPage extends StatefulWidget {
  final String playerId;
  final String videoType; // 'highlight' | 'game_film'
  const PlayerVideoAddPage({
    super.key,
    required this.playerId,
    this.videoType = 'highlight',
  });

  @override
  State<PlayerVideoAddPage> createState() => _PlayerVideoAddPageState();
}

class _PlayerVideoAddPageState extends State<PlayerVideoAddPage> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _muxService = MuxUploadService();

  // 'url' or 'device'
  String _mode = 'device';

  bool _isPrimary = false;
  bool _saving = false;

  // URL mode
  String _detectedSource = 'other';
  String? _previewThumbnail;

  // Device upload mode
  File? _pickedFile;
  Uint8List? _pickedBytes; // web only
  String? _pickedFileName;
  double _uploadProgress = 0;
  String _uploadStatus = ''; // '', 'uploading', 'processing', 'ready', 'errored'

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _onUrlChanged(String url) {
    final source = detectVideoSource(url);
    final thumbnail = extractYoutubeThumbnail(url);
    setState(() {
      _detectedSource = source;
      _previewThumbnail = thumbnail;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;

    if (kIsWeb) {
      if (file.bytes == null) return;
      setState(() {
        _pickedBytes = file.bytes;
        _pickedFile = null;
        _pickedFileName = file.name;
        _uploadStatus = '';
        _uploadProgress = 0;
      });
    } else {
      if (file.path == null) return;
      setState(() {
        _pickedFile = File(file.path!);
        _pickedBytes = null;
        _pickedFileName = file.name;
        _uploadStatus = '';
        _uploadProgress = 0;
      });
    }
  }

  Future<void> _uploadToMux() async {
    final hasFile = kIsWeb ? _pickedBytes != null : _pickedFile != null;
    if (!hasFile || widget.playerId.isEmpty) return;

    setState(() {
      _saving = true;
      _uploadStatus = 'uploading';
      _uploadProgress = 0;
    });

    try {
      // Refresh session to ensure valid JWT; if expired, redirect to login
      try {
        await _supabase.auth.refreshSession();
      } catch (_) {
        await _supabase.auth.signOut();
        if (mounted) context.go('/auth/login');
        return;
      }

      final title = _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : (widget.videoType == 'game_film' ? 'Full Game Film' : 'Highlight Film');

      // 1. Get upload URL from edge function
      final result = await _muxService.createUploadUrl(
        playerId: widget.playerId,
        videoType: widget.videoType,
        title: title,
      );

      // 2. Upload file to Mux
      if (kIsWeb) {
        await _muxService.uploadBytes(
          uploadUrl: result.uploadUrl,
          bytes: _pickedBytes!,
          onProgress: (p) => setState(() => _uploadProgress = p),
        );
      } else {
        await _muxService.uploadFile(
          uploadUrl: result.uploadUrl,
          file: _pickedFile!,
          onProgress: (p) => setState(() => _uploadProgress = p),
        );
      }

      setState(() {
        _uploadStatus = 'processing';
        _uploadProgress = 1.0;
      });

      // 3. Poll for ready status
      await for (final status in _muxService.pollStatus(videoId: result.videoId)) {
        if (!mounted) return;
        setState(() => _uploadStatus = status);
        if (status == 'ready' || status == 'errored') break;
      }

      if (mounted && _uploadStatus == 'ready') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Video is live! Coaches can now watch it.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop(true);
      } else if (mounted && _uploadStatus == 'errored') {
        setState(() {
          _saving = false;
          _uploadStatus = 'errored';
        });
      }
    } catch (e) {
      debugPrint('🔴 Mux upload error: $e');
      if (mounted) {
        setState(() {
          _saving = false;
          _uploadStatus = 'errored';
        });
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Upload Failed'),
            content: SingleChildScrollView(child: Text(e.toString())),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _saveUrl() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.playerId.isEmpty) return;

    setState(() => _saving = true);
    try {
      final url = _urlController.text.trim();
      final title = _titleController.text.trim();

      if (_isPrimary) {
        await _supabase
            .from('player_videos')
            .update({'is_primary': false})
            .eq('player_id', widget.playerId)
            .eq('is_primary', true);
      }

      await _supabase.from('player_videos').insert({
        'player_id': widget.playerId,
        'video_type': widget.videoType,
        'title': title.isNotEmpty
            ? title
            : (widget.videoType == 'game_film' ? 'Full Game Film' : 'Highlight Reel'),
        'source': _detectedSource,
        'external_url': url,
        'thumbnail_url': _previewThumbnail,
        'is_primary': _isPrimary,
      });

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save video: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    final accent = isDark ? PlayerColors.accent : AppColors.primary;
    final bg = isDark ? PlayerColors.background : AppColors.background;
    final surface = isDark ? PlayerColors.surface : Colors.white;
    final textPrimary = isDark ? PlayerColors.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? PlayerColors.textSecondary : AppColors.textSecondary;

    final isHighlight = widget.videoType == 'highlight';
    final pageTitle = isHighlight ? 'Add Highlight Film' : 'Add Full Game Film';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(pageTitle, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Mode selector ────────────────────────────────────────────────
          _ModeSelector(
            mode: _mode,
            onChanged: (m) => setState(() => _mode = m),
            accent: accent,
            surface: surface,
          ),
          const SizedBox(height: 24),

          if (_mode == 'device')
            _buildDeviceUpload(accent, textPrimary, textSecondary)
          else
            _buildUrlForm(accent, textPrimary),
        ],
      ),
    );
  }

  Widget _buildDeviceUpload(Color accent, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Text('🎥', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Upload directly from your device. Video is encoded by Mux and streamed in HD to coaches.',
                  style: TextStyle(fontSize: 13, color: accent, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _FieldLabel(text: 'Title (optional)', textPrimary: textPrimary),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          textCapitalization: TextCapitalization.sentences,
          decoration: _inputDecoration(
            hint: widget.videoType == 'game_film'
                ? 'e.g. State Cup Final – April 2025'
                : 'e.g. Spring 2025 Highlights',
            accent: accent,
          ),
        ),
        const SizedBox(height: 20),

        Builder(builder: (context) {
          final hasFile = kIsWeb ? _pickedBytes != null : _pickedFile != null;
          return GestureDetector(
            onTap: _saving ? null : _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: hasFile ? accent.withValues(alpha: 0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasFile ? accent : AppColors.border,
                  width: hasFile ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    hasFile ? Icons.videocam : Icons.upload_file,
                    size: 40,
                    color: hasFile ? accent : AppColors.textTertiary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    hasFile ? (_pickedFileName ?? 'Video selected') : 'Tap to select a video',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: hasFile ? accent : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (hasFile) ...[
                    const SizedBox(height: 4),
                    const Text('Tap to choose a different file',
                        style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  ],
                ],
              ),
            ),
          );
        }),

        if (_uploadStatus.isNotEmpty) ...[
          const SizedBox(height: 20),
          _UploadStatusWidget(status: _uploadStatus, progress: _uploadProgress, accent: accent),
        ],

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_saving || (kIsWeb ? _pickedBytes == null : _pickedFile == null)) ? null : _uploadToMux,
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.cloud_upload, size: 20),
            label: Text(_saving ? _uploadButtonLabel() : 'Upload Video'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: accent.withValues(alpha: 0.4),
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  String _uploadButtonLabel() {
    switch (_uploadStatus) {
      case 'uploading':
        return 'Uploading ${(_uploadProgress * 100).toInt()}%…';
      case 'processing':
        return 'Processing…';
      default:
        return 'Uploading…';
    }
  }

  Widget _buildUrlForm(Color accent, Color textPrimary) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Paste a link from YouTube, Hudl, or any platform where your video is hosted.',
                    style: TextStyle(fontSize: 13, color: accent, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _FieldLabel(text: 'Video URL', textPrimary: textPrimary),
          const SizedBox(height: 8),
          TextFormField(
            controller: _urlController,
            onChanged: _onUrlChanged,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: _inputDecoration(
              hint: 'https://www.youtube.com/watch?v=...',
              accent: accent,
              prefix: const Icon(Icons.link, size: 18, color: AppColors.textSecondary),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter a video URL';
              final lower = v.trim().toLowerCase();
              if (!lower.startsWith('http://') && !lower.startsWith('https://')) {
                return 'URL must start with http:// or https://';
              }
              return null;
            },
          ),

          if (_detectedSource != 'other' && _urlController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                const SizedBox(width: 6),
                Text('Detected: ${_sourceName(_detectedSource)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w500)),
              ],
            ),
          ],

          if (_previewThumbnail != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(_previewThumbnail!, height: 160, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          ],

          const SizedBox(height: 20),

          _FieldLabel(text: 'Title (optional)', textPrimary: textPrimary),
          const SizedBox(height: 8),
          TextFormField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: _inputDecoration(hint: 'e.g. Spring 2025 Highlights', accent: accent),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isPrimary,
              onChanged: (v) => setState(() => _isPrimary = v),
              activeTrackColor: accent,
              title: const Text('Set as primary highlight',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('This video will be shown first to coaches',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveUrl,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Video'),
            ),
          ),
        ],
      ),
    );
  }

  String _sourceName(String source) {
    switch (source) {
      case 'youtube': return 'YouTube';
      case 'hudl': return 'Hudl';
      case 'taka': return 'Taka';
      default: return source;
    }
  }

  InputDecoration _inputDecoration({required String hint, required Color accent, Widget? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.textTertiary),
      prefixIcon: prefix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accent, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

// ── Mode Selector ─────────────────────────────────────────────────────────────

class _ModeSelector extends StatelessWidget {
  final String mode;
  final ValueChanged<String> onChanged;
  final Color accent;
  final Color surface;

  const _ModeSelector({
    required this.mode,
    required this.onChanged,
    required this.accent,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _Tab(label: '📱 From Device', value: 'device', current: mode, accent: accent, onTap: () => onChanged('device')),
          _Tab(label: '🔗 Paste URL', value: 'url', current: mode, accent: accent, onTap: () => onChanged('url')),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final Color accent;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.value, required this.current, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Upload Status Widget ──────────────────────────────────────────────────────

class _UploadStatusWidget extends StatelessWidget {
  final String status;
  final double progress;
  final Color accent;

  const _UploadStatusWidget({required this.status, required this.progress, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (status == 'uploading') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Uploading…', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accent)),
              const Spacer(),
              Text('${(progress * 100).toInt()}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accent)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress, color: accent, backgroundColor: accent.withValues(alpha: 0.2)),
        ],
      );
    }
    if (status == 'processing') {
      return Row(
        children: [
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: accent)),
          const SizedBox(width: 12),
          Text('Processing video… this may take a minute',
              style: TextStyle(fontSize: 13, color: accent, fontWeight: FontWeight.w500)),
        ],
      );
    }
    if (status == 'errored') {
      return const Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: AppColors.error),
          SizedBox(width: 8),
          Text('Upload failed. Please try again.',
              style: TextStyle(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.w500)),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

// ── Field Label ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  final Color textPrimary;
  const _FieldLabel({required this.text, required this.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary));
  }
}
