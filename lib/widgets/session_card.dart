import 'package:flutter/material.dart';
import '../models/attendance_session_model.dart';
import '../utils/date_helper.dart';
import 'attendance_status_badge.dart';

/// Reusable Card untuk menampilkan ringkasan sesi kegiatan presensi (Mendukung sesi sekali & rutinan).
class SessionCard extends StatelessWidget {
  final AttendanceSessionModel session;
  final VoidCallback onTap;
  final Widget? trailingAction;

  const SessionCard({
    super.key,
    required this.session,
    required this.onTap,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    final schedule = session.getScheduleForDate(DateTime.now());
    final startAt = schedule['startAt']!;
    final endAt = schedule['endAt']!;

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Judul & Badge Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (session.isRecurring) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.repeat, size: 12, color: Color(0xFF7C3AED)),
                                const SizedBox(width: 4),
                                Text(
                                  'Rutinan: ${session.recurringDaysText}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF7C3AED),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AttendanceStatusBadge(
                    status: session.status,
                    isSessionStatus: true,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Deskripsi ringkas
              Text(
                session.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Info Lokasi
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      session.location,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Info Waktu Pelaksanaan
              Row(
                children: [
                  Icon(
                    session.isRecurring ? Icons.schedule_rounded : Icons.calendar_today_outlined,
                    size: 15,
                    color: const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    session.isRecurring
                        ? '${session.recurringDaysText} • ${DateHelper.formatTime(startAt)} - ${DateHelper.formatTime(endAt)}'
                        : '${DateHelper.formatDate(startAt)} • ${DateHelper.formatTime(startAt)} - ${DateHelper.formatTime(endAt)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),

              // Trailing action opsional (misal: tombol check-in langsung)
              if (trailingAction != null) ...[
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),
                trailingAction!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
