// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:typed_data';

/// Web-only: upload bytes via dart:html XHR.
/// Avoids http.put's double-copy OOM for large video files.
Future<void> uploadBytesXhr({
  required String uploadUrl,
  required Uint8List bytes,
  void Function(double)? onProgress,
}) {
  final completer = Completer<void>();
  final xhr = html.HttpRequest();
  xhr.open('PUT', uploadUrl);
  xhr.setRequestHeader('Content-Type', 'video/mp4');

  xhr.upload.onProgress.listen((html.ProgressEvent e) {
    if (e.lengthComputable) {
      onProgress?.call(e.loaded! / e.total!);
    }
  });

  xhr.onLoad.listen((_) {
    if (xhr.status! >= 200 && xhr.status! < 300) {
      completer.complete();
    } else {
      completer.completeError(
          Exception('Mux upload failed: HTTP ${xhr.status}'));
    }
  });

  xhr.onError.listen((_) {
    completer.completeError(Exception('Mux upload network error'));
  });

  xhr.send(bytes);
  return completer.future;
}
