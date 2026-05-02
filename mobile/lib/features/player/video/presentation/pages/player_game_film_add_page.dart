import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/video_models.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/player_colors.dart';
import '../../../../../../core/theme/player_theme_scope.dart';
import '../../../../../../core/di/injection.dart';

class PlayerGameFilmAddPage extends StatefulWidget {
  final String playerId;
  const PlayerGameFilmAddPage({super.key, required this.playerId});

  @override
  State<PlayerGameFilmAddPage> createState() => _PlayerGameFilmAddPageState();
}

class _PlayerGameFilmAddPageState extends State<PlayerGameFilmAddPage> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();

  bool _saving = false;
  String _detectedSource = 'other';
  String? _previewThumbnail;

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.playerId.isEmpty) return;

    setState(() => _saving = true);
    try {
      final url = _urlController.text.trim();
      final title = _titleController.text.trim();
      final source = _detectedSource;
      final thumbnail = _previewThumbnail;

      await _supabase.from('player_videos').insert({
        'player_id': widget.playerId,
        'title': title.isNotEmpty ? title : 'Full Game',
        'source': source,
        'external_url': url,
        'thumbnail_url': thumbnail,
        'video_type': 'game_film',
        'is_primary': false,
      });

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save game film: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = getIt<PlayerThemeService>();
    return PlayerThemeScope(
      service: themeService,
      child: _GameFilmAddContent(
        formKey: _formKey,
        urlController: _urlController,
        titleController: _titleController,
        saving: _saving,
        detectedSource: _detectedSource,
        previewThumbnail: _previewThumbnail,
        onUrlChanged: _onUrlChanged,
        onSave: _save,
      ),
    );
  }
}

class _GameFilmAddContent extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController urlController;
  final TextEditingController titleController;
  final bool saving;
  final String detectedSource;
  final String? previewThumbnail;
  final ValueChanged<String> onUrlChanged;
  final VoidCallback onSave;

  const _GameFilmAddContent({
    required this.formKey,
    required this.urlController,
    required this.titleController,
    required this.saving,
    required this.detectedSource,
    required this.previewThumbnail,
    required this.onUrlChanged,
    required this.onSave,
  });

  String _sourceName(String source) {
    switch (source) {
      case 'youtube': return 'YouTube';
      case 'hudl':    return 'Hudl';
      case 'taka':    return 'Taka';
      default:        return source;
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefix,
    required bool isDark,
  }) {
    final accent = isDark ? PlayerColors.accent : AppColors.primary;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 14,
          color: isDark ? PlayerColors.textTertiary : AppColors.textTertiary),
      prefixIcon: prefix,
      filled: true,
      fillColor: isDark ? PlayerColors.surfaceVariant : Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? PlayerColors.border : AppColors.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? PlayerColors.border : AppColors.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? PlayerColors.error : AppColors.error)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? PlayerColors.error : AppColors.error, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = PlayerThemeScope.isDark(context);
    final bg = isDark ? PlayerColors.background : AppColors.background;
    final appBarBg = isDark ? PlayerColors.surface : AppColors.primary;
    final accent = isDark ? PlayerColors.accent : AppColors.primary;
    final textPrimary = isDark ? PlayerColors.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? PlayerColors.textSecondary : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Add Game Film',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Instruction card ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? PlayerColors.accentSubtle : AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Download your full game from Taka, Trace, or your club platform, upload it to YouTube, then paste the link below.',
                      style: TextStyle(
                        fontSize: 13, height: 1.5,
                        color: isDark ? PlayerColors.textPrimary : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── URL field ─────────────────────────────────────────────────────
            _FieldLabel(text: 'Video URL', isDark: isDark),
            const SizedBox(height: 8),
            TextFormField(
              controller: urlController,
              onChanged: onUrlChanged,
              keyboardType: TextInputType.url,
              autocorrect: false,
              style: TextStyle(color: textPrimary),
              decoration: _inputDecoration(
                hint: 'https://www.youtube.com/watch?v=...',
                prefix: Icon(Icons.link, size: 18, color: textSecondary),
                isDark: isDark,
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

            // ── Source badge ──────────────────────────────────────────────────
            if (detectedSource != 'other' && urlController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 14,
                      color: isDark ? PlayerColors.success : AppColors.success),
                  const SizedBox(width: 6),
                  Text(
                    'Detected: ${_sourceName(detectedSource)}',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500,
                      color: isDark ? PlayerColors.success : AppColors.success,
                    ),
                  ),
                ],
              ),
            ],

            // ── YouTube thumbnail preview ─────────────────────────────────────
            if (previewThumbnail != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  previewThumbnail!,
                  height: 160, width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Title field ───────────────────────────────────────────────────
            _FieldLabel(text: 'Title (optional)', isDark: isDark),
            const SizedBox(height: 8),
            TextFormField(
              controller: titleController,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: textPrimary),
              decoration: _inputDecoration(
                hint: 'e.g. vs FC Dallas – March 2025',
                isDark: isDark,
              ),
            ),

            const SizedBox(height: 32),

            // ── Save button ───────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: isDark ? PlayerColors.textOnAccent : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                child: saving
                    ? SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? PlayerColors.textOnAccent : Colors.white),
                      )
                    : const Text('Save Game Film'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _FieldLabel({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: isDark ? PlayerColors.textPrimary : AppColors.textPrimary,
      ),
    );
  }
}
