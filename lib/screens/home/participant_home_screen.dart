import 'package:flutter/material.dart';
import '../../utils/dummy_data.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/session_card.dart';
import '../attendance/attendance_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../session/session_detail_screen.dart';
import '../session/session_list_screen.dart';

/// Dashboard Utama untuk Pengguna dengan Peran Peserta (Participant).
class ParticipantHomeScreen extends StatefulWidget {
  const ParticipantHomeScreen({super.key});

  @override
  State<ParticipantHomeScreen> createState() => _ParticipantHomeScreenState();
}

class _ParticipantHomeScreenState extends State<ParticipantHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(),
      const HistoryScreen(),
      ProfileScreen(user: DummyData.participantUser),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        elevation: 8,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    final user = DummyData.participantUser;
    final publishedSessions = DummyData.sessions.where((s) => s.status == 'published').toList();
    final activeSession = publishedSessions.isNotEmpty ? publishedSessions.first : null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Sambutan Pengguna
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, ${user.displayName} 👋',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Peserta (Participant)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '• Siap presensi hari ini?',
                            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 2), // Buka tab profil
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF0284C7),
                    child: Text(
                      user.displayName[0],
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Kartu Ringkasan Kehadiran
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ringkasan Kehadiran Saya',
                    style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryStat('2', 'Total Hadir'),
                      Container(height: 30, width: 1, color: Colors.white24),
                      _buildSummaryStat('1', 'Tepat Waktu'),
                      Container(height: 30, width: 1, color: Colors.white24),
                      _buildSummaryStat('1', 'Terlambat'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sesi Presensi Aktif Saat Ini
            if (activeSession != null) ...[
              const Text(
                'Sesi Presensi Aktif',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),
              SessionCard(
                session: activeSession,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SessionDetailScreen(session: activeSession),
                    ),
                  );
                },
                trailingAction: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Check-In Sekarang',
                        icon: Icons.camera_alt_outlined,
                        height: 40,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AttendanceScreen(session: activeSession, isCheckOut: false),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Sesi Lainnya
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sesi Kegiatan Lainnya',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SessionListScreen(isAdmin: false)),
                    );
                  },
                  child: const Text('Lihat Semua', style: TextStyle(fontSize: 13, color: Color(0xFF0284C7))),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ...publishedSessions.skip(1).map((s) => SessionCard(
                  session: s,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SessionDetailScreen(session: s)),
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }
}
