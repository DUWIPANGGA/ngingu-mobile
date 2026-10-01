/// Indonesian relative-time + date formatting helpers.
String timeAgo(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  final created = DateTime.tryParse(iso)?.toLocal();
  if (created == null) return '-';
  final diff = DateTime.now().difference(created);

  if (diff.inSeconds < 60) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} minggu lalu';
  return formatDate(iso);
}

/// `28 Sep 2026` (or with time when [withTime]).
String formatDate(String? iso, {bool withTime = false}) {
  if (iso == null || iso.isEmpty) return '-';
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '-';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  final date =
      '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  if (!withTime) return date;
  return '$date • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

/// `2026-09-21` → `21 Sep` (compact axis label).
String shortDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  return '${dt.day} ${months[dt.month - 1]}';
}
