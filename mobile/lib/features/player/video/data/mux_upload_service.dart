import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'upload_helper_stub.dart'
    if (dart.library.html) 'upload_helper_web.dart';

class MuxUploadResult {
  final String uploadId;
  final String videoId;
  final String uploadUrl;

  const MuxUploadResult({
    required this.uploadId,
    required this.videoId,
    required this.uploadUrl,
  });
}

class MuxUploadService {
  final _supabase = Supabase.instance.client;

  /// Step 1 — Call edge function to get a Mux upload URL
  Future<MuxUploadResult> createUploadUrl({
    required String playerId,
    required String videoType, // 'highlight' | 'game_film'
    String? title,
  }) async {
    final res = await _supabase.functions.invoke(
      'mux-upload',
      body: {
        'player_id': playerId,
        'video_type': videoType,
        if (title != null) 'title': title,
      },
    );

    if (res.status != 200) {
      throw Exception('Failed to create upload URL: ${res.data}');
    }

    final data = res.data as Map<String, dynamic>;
    return MuxUploadResult(
      uploadId: data['upload_id'] as String,
      videoId: data['video_id'] as String,
      uploadUrl: data['upload_url'] as String,
    );
  }

  /// Step 2a — Upload from a File (mobile/desktop)
  Future<void> uploadFile({
    required String uploadUrl,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    final fileSize = await file.length();
    final client = http.Client();
    try {
      final request = http.StreamedRequest('PUT', Uri.parse(uploadUrl));
      request.headers['Content-Type'] = 'video/mp4';
      request.contentLength = fileSize;

      int uploaded = 0;
      file.openRead().listen(
        (chunk) {
          request.sink.add(chunk);
          uploaded += chunk.length;
          onProgress?.call(uploaded / fileSize);
        },
        onDone: () => request.sink.close(),
        onError: (e) => request.sink.addError(e),
        cancelOnError: true,
      );

      final response = await client.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Mux upload failed: HTTP ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  /// Step 2b — Upload bytes (web)
  /// Uses dart:html XHR on web to avoid http.put's double-copy OOM on large files.
  Future<void> uploadBytes({
    required String uploadUrl,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    if (kIsWeb) {
      await uploadBytesXhr(
        uploadUrl: uploadUrl,
        bytes: bytes,
        onProgress: onProgress,
      );
    } else {
      throw UnsupportedError('Use uploadFile on non-web platforms');
    }
  }

  /// Poll player_videos until status = 'ready' or 'errored'
  Stream<String> pollStatus({
    required String videoId,
    int maxAttempts = 40,
  }) async* {
    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(const Duration(seconds: 3));

      final row = await _supabase
          .from('player_videos')
          .select('status')
          .eq('id', videoId)
          .maybeSingle();

      final status = row?['status'] as String? ?? 'waiting';
      yield status;

      if (status == 'ready' || status == 'errored') break;
    }
  }
}
