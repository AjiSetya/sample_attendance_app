import 'package:flutter/material.dart';
import '../../models/attendance_session_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/session_card.dart';
import 'session_detail_screen.dart';
import 'session_form_screen.dart';

/// Halaman Daftar Sesi Kegiatan Presensi (Mendukung mode Admin dan Peserta).
/// Terhubung secara realtime dengan Cloud Firestore.
class SessionListScreen extends StatefulWidget {
  final bool isAdmin;

  const SessionListScreen({super.key, this.isAdmin = false});

  @override
  State<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends State<SessionListScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  String _selectedFilter = 'Semua';
  String _searchQuery = '';

  List<String> get _filters => widget.isAdmin
      ? ['Semua', 'Aktif', 'Draft', 'Selesai']
      : ['Semua', 'Aktif', 'Selesai'];

  List<AttendanceSessionModel> _filterList(List<AttendanceSessionModel> allSessions) {
    var list = allSessions;

    // Filter berdasarkan status
    if (_selectedFilter == 'Aktif') {
      list = list.where((s) => s.status == 'published').toList();
    } else if (_selectedFilter == 'Draft') {
      list = list.where((s) => s.status == 'draft').toList();
    } else if (_selectedFilter == 'Selesai') {
      list = list.where((s) => s.status == 'completed').toList();
    }

    // Filter pencarian
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((s) =>
              s.title.toLowerCase().contains(q) ||
              s.location.toLowerCase().contains(q) ||
              s.description.toLowerCase().contains(q))
          .toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final stream = widget.isAdmin
        ? _firestoreService.streamAllSessions()
        : _firestoreService.streamPublishedSessions();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Kelola Sesi Presensi' : 'Daftar Sesi Presensi',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF7C3AED)),
              tooltip: 'Tambah Sesi Baru',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SessionFormScreen()),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Bar Pencarian & Filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Cari judul, lokasi, atau materi...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedFilter = filter),
                          selectedColor: const Color(0xFFE0F2FE),
                          checkmarkColor: const Color(0xFF0284C7),
                          labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF475569),
                          ),
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: BorderSide(
                              color: isSelected ? const Color(0xFF0284C7) : Colors.transparent),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Daftar Sesi dari Cloud Firestore
          Expanded(
            child: StreamBuilder<List<AttendanceSessionModel>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Terjadi kesalahan memuat sesi: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFEF4444))),
                    ),
                  );
                }

                final rawList = snapshot.data ?? [];
                final sessions = _filterList(rawList);

                if (sessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum ada sesi presensi',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isAdmin
                              ? 'Tekan tombol "+" di atas untuk membuat sesi baru.'
                              : 'Belum ada sesi yang dipublikasikan saat ini.',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return SessionCard(
                      session: session,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SessionDetailScreen(
                              session: session,
                              isAdmin: widget.isAdmin,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
