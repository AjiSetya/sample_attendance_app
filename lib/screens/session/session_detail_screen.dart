import 'package:flutter/material.dart';
import '../../models/attendance_record_model.dart';
import '../../models/attendance_session_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/date_helper.dart';
import '../../widgets/attendance_status_badge.dart';
import '../../widgets/custom_button.dart';
import '../attendance/attendance_detail_screen.dart';
import '../attendance/attendance_screen.dart';
import 'session_form_screen.dart';
import 'session_monitor_screen.dart';

/// Halaman Detail Informasi Sesi Kegiatan Presensi.
/// Menampilkan informasi jadwal (tanggal/rutinan) dan tombol aksi presensi dinamis.
class SessionDetailScreen extends StatelessWidget {
  final AttendanceSessionModel session;
  final bool isAdmin;

  const SessionDetailScreen({
    super.key,
    required this.session,
    this.isAdmin = false,
  });

  String _formatTodayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStr = _formatTodayStr();
    final currentUid = AuthService().currentUser?.uid ?? '';
    final firestoreService = FirestoreService();

    final schedule = session.getScheduleForDate(now);
    final isScheduledToday = session.isScheduledForToday();

    final startAt = schedule['startAt']!;
    final endAt = schedule['endAt']!;
    final checkInOpensAt = schedule['checkInOpensAt']!;
    final checkInOnTimeUntil = schedule['checkInOnTimeUntil']!;
    final checkInClosesAt = schedule['checkInClosesAt']!;
    final checkOutOpensAt = schedule['checkOutOpensAt']!;
    final checkOutDueAt = schedule['checkOutDueAt']!;
    final checkOutClosesAt = schedule['checkOutClosesAt']!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Detail Sesi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF0284C7)),
              tooltip: 'Ubah Sesi',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SessionFormScreen(session: session)),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kartu Judul, Lokasi, dan Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AttendanceStatusBadge(
                          status: session.status, isSessionStatus: true),
                      const Spacer(),
                      if (session.isRecurring)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Rutinan: ${session.recurringDaysText}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        )
                      else
                        Text(
                          DateHelper.formatDate(session.startAt),
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    session.title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    session.description,
                    style: const TextStyle(
                        fontSize: 13.5, color: Color(0xFF475569), height: 1.4),
                  ),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 18, color: Color(0xFF0284C7)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          session.location,
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1E293B)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Kartu Jadwal Pelaksanaan
            _buildScheduleCard(
              title: session.isRecurring
                  ? 'Waktu Kegiatan (${session.recurringDaysText})'
                  : 'Jadwal Pelaksanaan',
              icon: Icons.event,
              items: [
                _ScheduleItem('Mulai Kegiatan',
                    DateHelper.formatTime(startAt), Icons.play_circle_outline),
                _ScheduleItem('Selesai Kegiatan',
                    DateHelper.formatTime(endAt), Icons.stop_circle_outlined),
              ],
            ),
            const SizedBox(height: 16),

            // Kartu Jadwal Check-In
            _buildScheduleCard(
              title: 'Rentang Waktu Check-In',
              icon: Icons.login_rounded,
              color: const Color(0xFF0284C7),
              items: [
                _ScheduleItem('Check-In Dibuka',
                    DateHelper.formatTime(checkInOpensAt), Icons.timer_outlined),
                _ScheduleItem(
                    'Batas Tepat Waktu',
                    DateHelper.formatTime(checkInOnTimeUntil),
                    Icons.alarm,
                    isHighlight: true),
                _ScheduleItem('Check-In Ditutup',
                    DateHelper.formatTime(checkInClosesAt), Icons.timer_off_outlined),
              ],
            ),
            const SizedBox(height: 16),

            // Kartu Jadwal Check-Out
            _buildScheduleCard(
              title: 'Rentang Waktu Check-Out',
              icon: Icons.logout_rounded,
              color: const Color(0xFFEA580C),
              items: [
                _ScheduleItem('Check-Out Dibuka',
                    DateHelper.formatTime(checkOutOpensAt), Icons.timer_outlined),
                _ScheduleItem('Target Waktu Check-Out',
                    DateHelper.formatTime(checkOutDueAt), Icons.alarm),
                _ScheduleItem('Check-Out Ditutup',
                    DateHelper.formatTime(checkOutClosesAt), Icons.timer_off_outlined),
              ],
            ),
            const SizedBox(height: 24),

            // Area Aksi Berdasarkan Role
            if (isAdmin) ...[
              CustomButton(
                text: 'Monitoring Peserta Sesi',
                icon: Icons.people_outline,
                color: const Color(0xFF7C3AED),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SessionMonitorScreen(session: session)),
                  );
                },
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Ubah Jadwal & Data Sesi',
                icon: Icons.edit_note,
                isOutlined: true,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SessionFormScreen(session: session)),
                  );
                },
              ),
            ] else ...[
              // ALUR PESERTA: Reaktif terhadap status presensi hari ini di Firestore
              StreamBuilder<AttendanceRecordModel?>(
                stream: firestoreService.streamAttendanceRecord(
                  sessionId: session.id,
                  participantUid: currentUid,
                  dateStr: todayStr,
                ),
                builder: (context, snapshot) {
                  final record = snapshot.data;
                  final hasCheckedIn = record?.hasCheckedIn ?? false;
                  final hasCheckedOut = record?.hasCheckedOut ?? false;

                  if (!isScheduledToday) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Color(0xFFB45309), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              session.isRecurring
                                  ? 'Sesi ini tidak dijadwalkan untuk hari ini (${session.recurringDaysText}).'
                                  : 'Sesi ini tidak dijadwalkan untuk hari ini.',
                              style: const TextStyle(
                                  color: Color(0xFF92400E), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (hasCheckedIn && hasCheckedOut) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Color(0xFF15803D), size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Anda sudah menyelesaikan presensi Check-In dan Check-Out untuk hari ini.',
                                  style: TextStyle(
                                      color: Color(0xFF166534),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        CustomButton(
                          text: 'Lihat Bukti Presensi',
                          icon: Icons.receipt_long,
                          isOutlined: true,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AttendanceDetailScreen(record: record!),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }

                  if (hasCheckedIn && !hasCheckedOut) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: Color(0xFF1D4ED8), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Anda sudah Check-In pukul ${DateHelper.formatTime(record!.checkInAt!)}. Silakan lakukan Check-Out sebelum waktu berakhir.',
                                  style: const TextStyle(
                                      color: Color(0xFF1E40AF), fontSize: 12.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        CustomButton(
                          text: 'Lakukan Presensi Check-Out',
                          icon: Icons.logout_rounded,
                          color: const Color(0xFFEA580C),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AttendanceScreen(
                                  session: session,
                                  isCheckOut: true,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }

                  // Belum Check-in
                  return CustomButton(
                    text: 'Lakukan Presensi Check-In',
                    icon: Icons.camera_alt_outlined,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AttendanceScreen(
                            session: session,
                            isCheckOut: false,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard({
    required String title,
    required IconData icon,
    Color color = const Color(0xFF0F172A),
    required List<_ScheduleItem> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(item.icon,
                        size: 16,
                        color: item.isHighlight
                            ? const Color(0xFFD97706)
                            : const Color(0xFF94A3B8)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                          fontWeight: item.isHighlight
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      item.value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: item.isHighlight
                            ? const Color(0xFFD97706)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ScheduleItem {
  final String label;
  final String value;
  final IconData icon;
  final bool isHighlight;

  _ScheduleItem(this.label, this.value, this.icon, {this.isHighlight = false});
}
