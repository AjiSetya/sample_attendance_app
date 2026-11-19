import 'package:flutter/material.dart';
import '../../utils/date_helper.dart';
import '../../utils/dummy_data.dart';
import '../../widgets/attendance_status_badge.dart';
import '../../widgets/custom_button.dart';
import '../attendance/attendance_screen.dart';
import 'session_form_screen.dart';
import 'session_monitor_screen.dart';

/// Halaman Detail Informasi Sesi Kegiatan Presensi.
class SessionDetailScreen extends StatelessWidget {
  final DummySession session;
  final bool isAdmin;

  const SessionDetailScreen({
    super.key,
    required this.session,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Detail Sesi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                  MaterialPageRoute(builder: (_) => SessionFormScreen(session: session)),
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
            // Kartu Judul & Status
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
                      AttendanceStatusBadge(status: session.status, isSessionStatus: true),
                      const Spacer(),
                      Text(
                        DateHelper.formatDate(session.startAt),
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    session.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    session.description,
                    style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.4),
                  ),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF0284C7)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          session.location,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
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
              title: 'Jadwal Kegiatan',
              icon: Icons.event,
              items: [
                _ScheduleItem('Waktu Mulai Acara', DateHelper.formatDateTime(session.startAt), Icons.play_circle_outline),
                _ScheduleItem('Waktu Selesai Acara', DateHelper.formatDateTime(session.endAt), Icons.stop_circle_outlined),
              ],
            ),
            const SizedBox(height: 16),

            // Kartu Jadwal Check-In
            _buildScheduleCard(
              title: 'Rentang Waktu Check-In',
              icon: Icons.login_rounded,
              color: const Color(0xFF0284C7),
              items: [
                _ScheduleItem('Check-In Dibuka', DateHelper.formatDateTime(session.checkInOpensAt), Icons.timer_outlined),
                _ScheduleItem('Batas Tepat Waktu', DateHelper.formatDateTime(session.checkInOnTimeUntil), Icons.alarm, isHighlight: true),
                _ScheduleItem('Check-In Ditutup', DateHelper.formatDateTime(session.checkInClosesAt), Icons.timer_off_outlined),
              ],
            ),
            const SizedBox(height: 16),

            // Kartu Jadwal Check-Out
            _buildScheduleCard(
              title: 'Rentang Waktu Check-Out',
              icon: Icons.logout_rounded,
              color: const Color(0xFFEA580C),
              items: [
                _ScheduleItem('Check-Out Dibuka', DateHelper.formatDateTime(session.checkOutOpensAt), Icons.timer_outlined),
                _ScheduleItem('Target Check-Out', DateHelper.formatDateTime(session.checkOutDueAt), Icons.alarm),
                _ScheduleItem('Check-Out Ditutup', DateHelper.formatDateTime(session.checkOutClosesAt), Icons.timer_off_outlined),
              ],
            ),
            const SizedBox(height: 24),

            // Tombol Aksi Berdasarkan Role
            if (isAdmin) ...[
              CustomButton(
                text: 'Monitoring Peserta Sesi',
                icon: Icons.people_outline,
                color: const Color(0xFF7C3AED),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SessionMonitorScreen(session: session)),
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
                    MaterialPageRoute(builder: (_) => SessionFormScreen(session: session)),
                  );
                },
              ),
            ] else ...[
              CustomButton(
                text: 'Lakukan Presensi Check-In',
                icon: Icons.camera_alt_outlined,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttendanceScreen(session: session, isCheckOut: false),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Lakukan Presensi Check-Out',
                icon: Icons.camera_alt_outlined,
                isOutlined: true,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttendanceScreen(session: session, isCheckOut: true),
                    ),
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
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(item.icon, size: 16, color: item.isHighlight ? const Color(0xFFD97706) : const Color(0xFF94A3B8)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                          fontWeight: item.isHighlight ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      item.value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: item.isHighlight ? const Color(0xFFD97706) : const Color(0xFF1E293B),
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
