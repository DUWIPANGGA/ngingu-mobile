import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';

/// Reads the `scanId` navigation argument (`int` or UUID string — API.md §4.1).
String scanIdFromArguments() {
  final args = Get.arguments;
  if (args is Map) {
    final id = args['scanId'];
    if (id != null) return '$id';
  }
  return '';
}

/// Indonesian status label (API.md §4.3: pending → processing → done | failed).
String scanStatusLabel(String? status) {
  switch (status) {
    case 'pending':
      return 'Menunggu';
    case 'processing':
      return 'Diproses';
    case 'done':
      return 'Selesai';
    case 'failed':
      return 'Gagal';
    default:
      return '-';
  }
}

Color scanStatusColor(String? status) {
  switch (status) {
    case 'pending':
      return AppColors.accent;
    case 'processing':
      return AppColors.primary;
    case 'done':
      return AppColors.secondary;
    case 'failed':
      return AppColors.danger;
    default:
      return AppColors.textSecondary;
  }
}

/// Confirmation dialog for destructive actions (hapus scan / batalkan proses).
Future<bool> confirmDestructive({
  required String title,
  required String message,
  String confirmLabel = 'Hapus',
}) async {
  final result = await Get.dialog<bool>(
    AlertDialog(
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      content: Text(message, style: const TextStyle(fontSize: 14, height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: Text(
            confirmLabel,
            style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
    barrierDismissible: true,
  );
  return result ?? false;
}

/// share_plus ^13 — `Share.shareXFiles` is deprecated; use `SharePlus.instance.share`.
Future<void> shareLocalFile(String path, {String? title, String? text}) =>
    SharePlus.instance.share(ShareParams(files: [XFile(path)], title: title, text: text));

/// Downloads an authenticated export (API.md §4.5/§4.6) into the temp dir and shares it.
Future<void> downloadAndShare({
  required String path,
  required String saveName,
  required String title,
  Map<String, dynamic>? query,
}) async {
  final tmp = await getTemporaryDirectory();
  final savePath = '${tmp.path}/$saveName';
  await ApiClient.downloadFile(path, savePath: savePath, query: query);
  await shareLocalFile(savePath, title: title);
}
