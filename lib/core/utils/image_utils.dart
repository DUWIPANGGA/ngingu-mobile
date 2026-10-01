import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';

/// Client-side image optimization (NFR-01.7: target < 500 KB/file,
/// API.md §2.7 upload limits).
Future<File> compressImage(
  File file, {
  int maxBytes = AppConfig.compressTargetBytes,
  int maxDimension = 1600,
}) async {
  try {
    final bytes = await file.readAsBytes();
    var decoded = img.decodeImage(bytes);
    if (decoded == null) return file;

    // Downscale oversized photos.
    if (decoded.width > maxDimension || decoded.height > maxDimension) {
      final scale = math.min(maxDimension / decoded.width, maxDimension / decoded.height);
      decoded = img.copyResize(
        decoded,
        width: (decoded.width * scale).round(),
        height: (decoded.height * scale).round(),
      );
    }

    // Progressive JPEG re-encode until under the size budget.
    int quality = 90;
    Uint8List out = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
    while (out.lengthInBytes > maxBytes && quality > 55) {
      quality -= 15;
      out = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
    }
    if (out.lengthInBytes >= bytes.length) return file; // original already smaller

    final tmp = await getTemporaryDirectory();
    final outPath =
        '${tmp.path}/ngingu_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final outFile = File(outPath);
    await outFile.writeAsBytes(out, flush: true);
    return outFile;
  } catch (_) {
    return file; // fail-open: send the original
  }
}

/// Compress a list (scans: up to 5, posts: up to 5 — API.md §2.7).
Future<List<File>> compressImages(List<File> files) async {
  final out = <File>[];
  for (final f in files) {
    out.add(await compressImage(f));
  }
  return out;
}
