import 'package:flutter/material.dart';

/// Reusable Badge untuk menampilkan status kehadiran atau status sesi dengan warna yang kontras & informatif.
class AttendanceStatusBadge extends StatelessWidget {
  final String status;
  final bool isSessionStatus;

  const AttendanceStatusBadge({
    super.key,
    required this.status,
    this.isSessionStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    if (isSessionStatus) {
      switch (status.toLowerCase()) {
        case 'published':
          bg = const Color(0xFFE0F2FE);
          fg = const Color(0xFF0369A1);
          label = 'Dipublikasikan';
          icon = Icons.visibility;
          break;
        case 'draft':
          bg = const Color(0xFFF1F5F9);
          fg = const Color(0xFF475569);
          label = 'Draft';
          icon = Icons.edit_note;
          break;
        case 'completed':
          bg = const Color(0xFFDCFCE7);
          fg = const Color(0xFF15803D);
          label = 'Selesai';
          icon = Icons.check_circle_outline;
          break;
        case 'cancelled':
          bg = const Color(0xFFFEE2E2);
          fg = const Color(0xFFB91C1C);
          label = 'Dibatalkan';
          icon = Icons.cancel_outlined;
          break;
        default:
          bg = const Color(0xFFF1F5F9);
          fg = const Color(0xFF64748B);
          label = status;
          icon = Icons.info_outline;
      }
    } else {
      switch (status.toLowerCase()) {
        case 'on_time':
          bg = const Color(0xFFDCFCE7);
          fg = const Color(0xFF15803D);
          label = 'Tepat Waktu';
          icon = Icons.check_circle;
          break;
        case 'late':
          bg = const Color(0xFFFEF3C7);
          fg = const Color(0xFFB45309);
          label = 'Terlambat';
          icon = Icons.warning_amber_rounded;
          break;
        case 'not_yet':
        case 'missing':
          bg = const Color(0xFFFEE2E2);
          fg = const Color(0xFFB91C1C);
          label = 'Belum Ada';
          icon = Icons.hourglass_empty;
          break;
        default:
          bg = const Color(0xFFF1F5F9);
          fg = const Color(0xFF64748B);
          label = status;
          icon = Icons.help_outline;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
