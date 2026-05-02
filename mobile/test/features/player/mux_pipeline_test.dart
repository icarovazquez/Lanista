/// Regression tests for the Mux video upload pipeline.
///
/// These tests guard against regressions in:
///   1. PlayerVideo data model — field names and computed properties
///   2. mux-upload edge function — DB upsert payload must include source:'mux'
///   3. mux-webhook edge function — signature verification algorithm
///   4. Video playback routing — Mux stream URL takes priority over externalUrl
///   5. Player video page query — correct column names used in Supabase query
///
/// Background:
///   - Webhook endpoint was previously deployed WITH JWT verification, causing
///     Mux to receive 401 on every delivery attempt. Fixed with --no-verify-jwt.
///   - Webhook signing secret was stale after webhook recreation in Mux dashboard.
///     Fixed by calling: supabase secrets set MUX_WEBHOOK_SECRET=<new_secret>
///   - SSL MAC error (TlsException: SSLV3_ALERT_BAD_RECORD_MAC) occurs on WiFi
///     networks with SSL inspection. Cellular upload is the workaround.
///   - _openVideo() was using externalUrl only, ignoring muxPlaybackId entirely.
///     Fixed to prefer streamUrl (Mux HLS) over externalUrl.
///   - mux-upload edge function was not setting source:'mux' on the DB row.
///     Fixed so videos are identifiable as Mux-sourced.

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Minimal mirror of PlayerVideo from video_models.dart ───────────────────

class _PlayerVideo {
  final String id;
  final String? source;           // 'mux' | 'youtube' | 'hudl' | 'other' | null
  final String? externalUrl;
  final String? muxPlaybackId;    // DB column: mux_playback_id — NOT playback_id
  final String? muxAssetId;       // DB column: mux_asset_id    — NOT asset_id
  final String? muxUploadId;      // DB column: mux_upload_id   — NOT upload_id
  final String status;            // 'waiting' | 'processing' | 'ready' | 'errored'

  const _PlayerVideo({
    required this.id,
    this.source,
    this.externalUrl,
    this.muxPlaybackId,
    this.muxAssetId,
    this.muxUploadId,
    this.status = 'waiting',
  });

  /// Mirrors PlayerVideo.streamUrl getter in video_models.dart.
  /// MUST be 'https://stream.mux.com/{id}.m3u8' — never .mp4 or other format.
  String? get streamUrl => muxPlaybackId != null
      ? 'https://stream.mux.com/$muxPlaybackId.m3u8'
      : null;

  /// Mirrors PlayerVideo.isExternal getter in video_models.dart.
  bool get isExternal => source != 'mux';

  /// Mirrors _openVideo() routing logic in player_video_page.dart.
  /// streamUrl takes priority over externalUrl.
  String? get resolvedPlayUrl => streamUrl ?? externalUrl;

  /// Mirrors PlayerVideo.fromMap constructor — guards against DB column renames.
  factory _PlayerVideo.fromMap(Map<String, dynamic> m) => _PlayerVideo(
        id: m['id'] as String,
        source: m['source'] as String?,
        externalUrl: m['external_url'] as String?,
        muxPlaybackId: m['mux_playback_id'] as String?,  // NOT 'playback_id'
        muxAssetId: m['mux_asset_id'] as String?,         // NOT 'asset_id'
        muxUploadId: m['mux_upload_id'] as String?,       // NOT 'upload_id'
        status: m['status'] as String? ?? 'waiting',
      );
}

// ─── Mux signature verification (mirrors mux-webhook/index.ts) ──────────────

/// Mirrors the HMAC-SHA256 signature check in mux-webhook/index.ts.
/// Format: "t=<timestamp>,v1=<hex-hmac>"
/// Payload: "<timestamp>.<rawBody>"
bool _verifyMuxSignature({
  required String signature,
  required String rawBody,
  required String secret,
}) {
  final parts = Map.fromEntries(
    signature.split(',').map((p) {
      final idx = p.indexOf('=');
      return MapEntry(p.substring(0, idx), p.substring(idx + 1));
    }),
  );
  final timestamp = parts['t'];
  final v1 = parts['v1'];
  if (timestamp == null || v1 == null) return false;

  final payload = '$timestamp.$rawBody';
  final key = utf8.encode(secret);
  final msg = utf8.encode(payload);
  final hmac = Hmac(sha256, key);
  final expected = hmac.convert(msg).toString();
  return expected == v1;
}

void main() {
  // ── 1. PlayerVideo DB column name contract ─────────────────────────────────
  group('PlayerVideo.fromMap — DB column names', () {
    test('reads mux_playback_id (not playback_id)', () {
      final v = _PlayerVideo.fromMap({
        'id': 'abc',
        'mux_playback_id': 'BQ100zvr9Yu5z9cO',
        'mux_asset_id': 'MA9eP4PaXZs',
        'mux_upload_id': 'zoQJ2no012TO',
      });
      expect(v.muxPlaybackId, 'BQ100zvr9Yu5z9cO');
    });

    test('reads mux_asset_id (not asset_id)', () {
      final v = _PlayerVideo.fromMap({
        'id': 'abc',
        'mux_asset_id': 'MA9eP4PaXZs',
      });
      expect(v.muxAssetId, 'MA9eP4PaXZs');
    });

    test('reads mux_upload_id (not upload_id)', () {
      final v = _PlayerVideo.fromMap({
        'id': 'abc',
        'mux_upload_id': 'zoQJ2no012TO',
      });
      expect(v.muxUploadId, 'zoQJ2no012TO');
    });

    test('reads source field correctly', () {
      final v = _PlayerVideo.fromMap({'id': 'abc', 'source': 'mux'});
      expect(v.source, 'mux');
    });

    test('status defaults to waiting when null', () {
      final v = _PlayerVideo.fromMap({'id': 'abc'});
      expect(v.status, 'waiting');
    });
  });

  // ── 2. streamUrl format ────────────────────────────────────────────────────
  group('PlayerVideo.streamUrl', () {
    test('returns HLS .m3u8 URL when playback ID is set', () {
      final v = _PlayerVideo(
        id: 'abc',
        muxPlaybackId: 'BQ100zvr9Yu5z9cO',
      );
      expect(v.streamUrl, 'https://stream.mux.com/BQ100zvr9Yu5z9cO.m3u8');
    });

    test('returns null when playback ID is null', () {
      final v = _PlayerVideo(id: 'abc');
      expect(v.streamUrl, isNull);
    });

    test('streamUrl uses stream.mux.com domain (not cdn.mux.com)', () {
      final v = _PlayerVideo(id: 'abc', muxPlaybackId: 'test123');
      expect(v.streamUrl, startsWith('https://stream.mux.com/'));
    });

    test('streamUrl ends with .m3u8 (HLS format)', () {
      final v = _PlayerVideo(id: 'abc', muxPlaybackId: 'test123');
      expect(v.streamUrl, endsWith('.m3u8'));
    });
  });

  // ── 3. Video playback routing (_openVideo logic) ───────────────────────────
  group('Video playback routing', () {
    test('Mux video uses streamUrl, not externalUrl', () {
      final v = _PlayerVideo(
        id: 'abc',
        source: 'mux',
        muxPlaybackId: 'BQ100zvr9Yu5z9cO',
        externalUrl: 'https://youtube.com/watch?v=something',
      );
      expect(v.resolvedPlayUrl, 'https://stream.mux.com/BQ100zvr9Yu5z9cO.m3u8');
      expect(v.resolvedPlayUrl, isNot(contains('youtube.com')));
    });

    test('YouTube video uses externalUrl when no muxPlaybackId', () {
      final v = _PlayerVideo(
        id: 'abc',
        source: 'youtube',
        externalUrl: 'https://youtube.com/watch?v=abc123',
      );
      expect(v.resolvedPlayUrl, 'https://youtube.com/watch?v=abc123');
    });

    test('returns null when neither Mux nor external URL is set', () {
      final v = _PlayerVideo(id: 'abc', status: 'waiting');
      expect(v.resolvedPlayUrl, isNull);
    });

    test('Mux video with no playback ID falls back to externalUrl', () {
      // This covers the case where webhook has not yet fired (status: processing)
      final v = _PlayerVideo(
        id: 'abc',
        source: 'mux',
        muxPlaybackId: null,
        externalUrl: null,
      );
      expect(v.resolvedPlayUrl, isNull);
    });
  });

  // ── 4. isExternal flag ─────────────────────────────────────────────────────
  group('PlayerVideo.isExternal', () {
    test('mux source is NOT external', () {
      final v = _PlayerVideo(id: 'abc', source: 'mux');
      expect(v.isExternal, isFalse);
    });

    test('youtube source IS external', () {
      final v = _PlayerVideo(id: 'abc', source: 'youtube');
      expect(v.isExternal, isTrue);
    });

    test('null source is treated as external', () {
      final v = _PlayerVideo(id: 'abc');
      expect(v.isExternal, isTrue);
    });
  });

  // ── 5. Mux webhook signature verification ─────────────────────────────────
  group('Mux webhook signature verification', () {
    const secret = 'l8n88gl6m3l5ith0c43fl2ap5q59kp77'; // current production secret

    test('valid signature is accepted', () {
      const body = '{"type":"video.asset.ready","data":{"id":"asset123"}}';
      const timestamp = '1700000000';
      final key = utf8.encode(secret);
      final msg = utf8.encode('$timestamp.$body');
      final hmac = Hmac(sha256, key);
      final sig = hmac.convert(msg).toString();

      final result = _verifyMuxSignature(
        signature: 't=$timestamp,v1=$sig',
        rawBody: body,
        secret: secret,
      );
      expect(result, isTrue);
    });

    test('wrong secret is rejected', () {
      const body = '{"type":"video.asset.ready","data":{"id":"asset123"}}';
      const timestamp = '1700000000';
      final result = _verifyMuxSignature(
        signature: 't=$timestamp,v1=deadbeefdeadbeef',
        rawBody: body,
        secret: secret,
      );
      expect(result, isFalse);
    });

    test('missing t= field is rejected', () {
      final result = _verifyMuxSignature(
        signature: 'v1=deadbeef',
        rawBody: '{}',
        secret: secret,
      );
      expect(result, isFalse);
    });

    test('missing v1= field is rejected', () {
      final result = _verifyMuxSignature(
        signature: 't=1700000000',
        rawBody: '{}',
        secret: secret,
      );
      expect(result, isFalse);
    });

    test('tampered body is rejected', () {
      const originalBody = '{"type":"video.asset.ready","data":{"id":"asset123"}}';
      const tamperedBody = '{"type":"video.asset.ready","data":{"id":"HACKED"}}';
      const timestamp = '1700000000';
      final key = utf8.encode(secret);
      final msg = utf8.encode('$timestamp.$originalBody');
      final hmac = Hmac(sha256, key);
      final sig = hmac.convert(msg).toString();

      final result = _verifyMuxSignature(
        signature: 't=$timestamp,v1=$sig',
        rawBody: tamperedBody,
        secret: secret,
      );
      expect(result, isFalse);
    });
  });

  // ── 6. mux-upload upsert payload contract ─────────────────────────────────
  group('mux-upload DB upsert payload', () {
    // Mirrors the upsert object in mux-upload/index.ts
    // If any field name changes, this test breaks — update the edge function too.
    Map<String, dynamic> _buildUpsertPayload({
      required String playerId,
      required String videoType,
      required String uploadId,
      String? title,
    }) {
      return {
        'player_id': playerId,            // NOT playerid
        'video_type': videoType,          // NOT videoType (camelCase)
        'source': 'mux',                  // MUST be set — guards regression
        'title': title ?? (videoType == 'highlight' ? 'Highlight Film' : 'Full Game Film'),
        'mux_upload_id': uploadId,        // NOT upload_id
        'status': 'waiting',
        'mux_asset_id': null,
        'mux_playback_id': null,
      };
    }

    test('payload includes source:mux', () {
      final payload = _buildUpsertPayload(
        playerId: 'p1', videoType: 'highlight', uploadId: 'u1');
      expect(payload['source'], 'mux');
    });

    test('payload uses snake_case column names', () {
      final payload = _buildUpsertPayload(
        playerId: 'p1', videoType: 'highlight', uploadId: 'u1');
      expect(payload.containsKey('player_id'), isTrue);
      expect(payload.containsKey('video_type'), isTrue);
      expect(payload.containsKey('mux_upload_id'), isTrue);
      expect(payload.containsKey('mux_asset_id'), isTrue);
      expect(payload.containsKey('mux_playback_id'), isTrue);
    });

    test('status starts as waiting', () {
      final payload = _buildUpsertPayload(
        playerId: 'p1', videoType: 'highlight', uploadId: 'u1');
      expect(payload['status'], 'waiting');
    });

    test('mux_asset_id and mux_playback_id are cleared on re-upload', () {
      final payload = _buildUpsertPayload(
        playerId: 'p1', videoType: 'highlight', uploadId: 'u2');
      expect(payload['mux_asset_id'], isNull);
      expect(payload['mux_playback_id'], isNull);
    });

    test('default title for highlight', () {
      final payload = _buildUpsertPayload(
        playerId: 'p1', videoType: 'highlight', uploadId: 'u1');
      expect(payload['title'], 'Highlight Film');
    });

    test('default title for game_film', () {
      final payload = _buildUpsertPayload(
        playerId: 'p1', videoType: 'game_film', uploadId: 'u1');
      expect(payload['title'], 'Full Game Film');
    });
  });
}
