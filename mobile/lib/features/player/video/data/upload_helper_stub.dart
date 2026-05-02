import 'dart:typed_data';

/// Stub for non-web platforms — uploadBytes is handled via http.StreamedRequest
Future<void> uploadBytesXhr({
  required String uploadUrl,
  required Uint8List bytes,
  void Function(double)? onProgress,
}) {
  throw UnsupportedError('XHR upload only supported on web');
}
