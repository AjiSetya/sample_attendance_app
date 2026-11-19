import 'package:intl/intl.dart';

/// Helper sederhana untuk memformat tanggal dan waktu.
/// Menggunakan package `intl` yang sudah terpasang di pubspec.yaml.
class DateHelper {
  /// Format tanggal standar Indonesia: "19 Nov 2024"
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Format jam dan menit: "08:30"
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  /// Format tanggal dan jam lengkap: "19 Nov 2024, 08:30"
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }

  /// Menghitung selisih waktu dalam format yang mudah dibaca (misal: "15 menit yang lalu")
  static String timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
    return '${diff.inDays} hari yang lalu';
  }
}
