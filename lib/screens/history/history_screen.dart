import 'package:flutter/material.dart';
import '../../utils/date_helper.dart';
import '../../utils/dummy_data.dart';
import '../../widgets/attendance_status_badge.dart';
import '../attendance/attendance_detail_screen.dart';

/// Halaman Riwayat Presensi Pribadi untuk Peserta.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Tepat Waktu', 'Terlambat'];

  List<DummyAttendanceRecord> get _filteredRecords {
    if (_selectedFilter == 'Tepat Waktu') {
      return DummyData.participantHistory.where((r) => r.checkInStatus == 'on_time').toList();
    } else if (_selectedFilter == 'Terlambat') {
      return DummyData.participantHistory.where((r) => r.checkInStatus == 'late').toList();
    }
    return DummyData.participantHistory;
  }

  @override
  Widget build(BuildContext context) {
    final records = _filteredRecords;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Riwayat Presensi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedFilter = filter);
                    },
                    selectedColor: const Color(0xFFE0F2FE),
                    checkmarkColor: const Color(0xFF0284C7),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF475569),
                    ),
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF0284C7) : Colors.transparent,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              }).toList(),
            ),
          ),

          // Daftar Riwayat
          Expanded(
            child: records.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak ada riwayat presensi',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Belum ada presensi yang sesuai dengan filter yang dipilih.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final item = records[index];
                      return Card(
                        elevation: 0.5,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        color: Colors.white,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AttendanceDetailScreen(record: item),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.sessionTitle,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    AttendanceStatusBadge(status: item.checkInStatus),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.login_rounded, size: 15, color: Color(0xFF0284C7)),
                                    const SizedBox(width: 6),
                                    Text(
                                      item.checkInAt != null
                                          ? 'Masuk: ${DateHelper.formatDateTime(item.checkInAt!)}'
                                          : 'Masuk: -',
                                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.logout_rounded, size: 15, color: Color(0xFFEA580C)),
                                    const SizedBox(width: 6),
                                    Text(
                                      item.checkOutAt != null
                                          ? 'Keluar: ${DateHelper.formatDateTime(item.checkOutAt!)}'
                                          : 'Keluar: Belum checkout',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: item.checkOutAt != null
                                            ? const Color(0xFF475569)
                                            : const Color(0xFFDC2626),
                                        fontWeight: item.checkOutAt != null ? FontWeight.normal : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Lihat Bukti Foto',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0284C7),
                                      ),
                                    ),
                                    SizedBox(width: 2),
                                    Icon(Icons.chevron_right, size: 16, color: Color(0xFF0284C7)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
