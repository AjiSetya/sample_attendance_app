import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
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
  final UserModel? user;

  const ParticipantHomeScreen({super.key, this.user});

  @override
  State<ParticipantHomeScreen> createState() => _ParticipantHomeScreenState();
}

class _ParticipantHomeScreenState extends State<ParticipantHomeScreen> {
  int _currentIndex = 0;

  UserModel _getUser() {
    if (widget.user != null) return widget.user!;
    final fbUser = AuthService().currentUser;
    if (fbUser != null) {
      return UserModel(
        uid: fbUser.uid,
        displayName: fbUser.displayName ?? 'Peserta',
        email: fbUser.email ?? '',
        role: 'participant',
      );
    }
    final d = DummyData.participantUser;
    return UserModel(
      uid: d.uid,
      displayName: d.displayName,
      email: d.email,
      phone: d.phone,
      role: d.role,
      createdAt: d.createdAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _getUser();

    final List<Widget> pages = [
      _buildHomeContent(user),
      const HistoryScreen(),
      ProfileScreen(user: user),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF0284C7),
        unselectedItemColor: const Color(0xFF94A3B8),
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(UserModel user) {
    final publishedSessions = DummyData.sessions.where((s) => s.status == 'published').toList();
    final activeSession = publishedSessions.isNotEmpty ? publishedSessions.first : null;

    final displayName = user.displayName.isNotEmpty ? user.displayName : 'Peserta';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P';

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
                        'Halo, $displayName 👋',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        overflow: TextOverflow.ellipsis,
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
                          const Flexible(
                            child: Text(
                              '• Siap presensi hari ini?',
                              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 2), // Buka tab profil
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF0284C7),
                    child: Text(
                      initial,
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
