import 'package:flutter/material.dart';
import '../../models/attendance_record_model.dart';
import '../../models/attendance_session_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/date_helper.dart';
import '../../widgets/attendance_status_badge.dart';
import '../attendance/attendance_detail_screen.dart';

/// Halaman Monitoring Kehadiran Peserta dalam Sesi Tertentu (Khusus Admin).
/// Terhubung secara realtime dengan Cloud Firestore.
class SessionMonitorScreen extends StatefulWidget {
  final AttendanceSessionModel session;

  const SessionMonitorScreen({super.key, required this.session});

  @override
  State<SessionMonitorScreen> createState() => _SessionMonitorScreenState();
}

class _SessionMonitorScreenState extends State<SessionMonitorScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Tepat Waktu', 'Terlambat', 'Belum Checkout'];

  List<AttendanceRecordModel> _filterRecords(List<AttendanceRecordModel> allList) {
    if (_selectedFilter == 'Tepat Waktu') {
      return allList.where((r) => r.checkInStatus == 'on_time').toList();
    } else if (_selectedFilter == 'Terlambat') {
      return allList.where((r) => r.checkInStatus == 'late').toList();
    } else if (_selectedFilter == 'Belum Checkout') {
      return allList.where((r) => r.checkInAt != null && r.checkOutAt == null).toList();
    }
    return allList;
  }

  @override
  Widget build(BuildContext context) {
    final schedule = widget.session.getScheduleForDate(DateTime.now());
    final checkInOnTimeUntil = schedule['checkInOnTimeUntil']!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Monitoring Kehadiran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: StreamBuilder<List<AttendanceRecordModel>>(
        stream: _firestoreService.streamSessionAttendance(widget.session.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allList = snapshot.data ?? [];
          final totalHadir = allList.where((r) => r.checkInAt != null).length;
          final onTimeCount = allList.where((r) => r.checkInStatus == 'on_time').length;
          final lateCount = allList.where((r) => r.checkInStatus == 'late').length;
          final notCheckedOutCount = allList.where((r) => r.checkInAt != null && r.checkOutAt == null).length;

          final records = _filterRecords(allList);

          return Column(
            children: [
              // Header Info Sesi
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.session.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.session.isRecurring
                          ? 'Rutinan: ${widget.session.recurringDaysText} • Batas Tepat Waktu: ${DateHelper.formatTime(checkInOnTimeUntil)} WIB'
                          : 'Batas Tepat Waktu: ${DateHelper.formatTime(checkInOnTimeUntil)} WIB',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),

                    // Kartu Statistik Ringkasan
                    Row(
                      children: [
                        _buildStatCard('Total Hadir', '$totalHadir', const Color(0xFF0284C7)),
                        const SizedBox(width: 8),
                        _buildStatCard('Tepat Waktu', '$onTimeCount', const Color(0xFF16A34A)),
                        const SizedBox(width: 8),
                        _buildStatCard('Terlambat', '$lateCount', const Color(0xFFD97706)),
                        const SizedBox(width: 8),
                        _buildStatCard('Belum Out', '$notCheckedOutCount', const Color(0xFFDC2626)),
                      ],
                    ),
                  ],
                ),
              ),

              // Filter Tabs
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedFilter = filter),
                          selectedColor: const Color(0xFFEDE9FE),
                          labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF475569),
                          ),
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: BorderSide(color: isSelected ? const Color(0xFF7C3AED) : Colors.transparent),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Daftar Peserta Presensi
              Expanded(
                child: records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            const Text(
                              'Belum ada presensi pada kategori ini',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final item = records[index];
                          final initial = item.participantName.isNotEmpty
                              ? item.participantName[0].toUpperCase()
                              : 'P';

                          return Card(
                            elevation: 0.5,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            color: Colors.white,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFE0F2FE),
                                foregroundColor: const Color(0xFF0369A1),
                                child: Text(
                                  initial,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                item.participantName,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.checkInAt != null
                                          ? 'Check-In: ${DateHelper.formatTime(item.checkInAt!)}'
                                          : 'Belum Check-In',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                    if (item.checkOutAt != null)
                                      Text(
                                        'Check-Out: ${DateHelper.formatTime(item.checkOutAt!)}',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      ),
                                    if (item.attendanceDate.isNotEmpty)
                                      Text(
                                        'Tgl: ${item.attendanceDate}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                      ),
                                  ],
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AttendanceStatusBadge(status: item.checkInStatus),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AttendanceDetailScreen(record: item),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
