import 'package:flutter/material.dart';
import '../../utils/dummy_data.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/session_card.dart';
import '../profile/profile_screen.dart';
import '../session/session_detail_screen.dart';
import '../session/session_form_screen.dart';
import '../session/session_list_screen.dart';
import '../session/session_monitor_screen.dart';

/// Dashboard Utama untuk Pengguna dengan Peran Admin (Administrator).
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildAdminHomeContent(),
      const SessionListScreen(isAdmin: true),
      ProfileScreen(user: DummyData.adminUser),
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
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Kelola Sesi',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil Admin',
          ),
        ],
      ),
    );
  }

  Widget _buildAdminHomeContent() {
    final user = DummyData.adminUser;
    final allSessions = DummyData.sessions;
    final activeSessions = allSessions.where((s) => s.status == 'published').toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Admin
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Panel Admin: ${user.displayName}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Administrator',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '• Kelola sesi & presensi',
                            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 2),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF7C3AED),
                    child: Text(
                      user.displayName[0],
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Kartu Ringkasan Statistik
            Row(
              children: [
                _buildMetricCard('Total Sesi', '${allSessions.length}', Icons.event, const Color(0xFF7C3AED)),
                const SizedBox(width: 10),
                _buildMetricCard('Sesi Aktif', '${activeSessions.length}', Icons.play_circle_outline, const Color(0xFF0284C7)),
                const SizedBox(width: 10),
                _buildMetricCard('Total Hadir', '12', Icons.how_to_reg_outlined, const Color(0xFF16A34A)),
              ],
            ),
            const SizedBox(height: 20),

            // Tombol Cepat Tambah Sesi
            CustomButton(
              text: 'Buat Sesi Presensi Baru',
              icon: Icons.add,
              color: const Color(0xFF7C3AED),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SessionFormScreen()),
                );
              },
            ),
            const SizedBox(height: 24),

            // Daftar Sesi yang Sedang Berjalan / Aktif
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sesi Aktif & Terjadwal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                TextButton(
                  onPressed: () => setState(() => _currentIndex = 1),
                  child: const Text('Kelola Semua', style: TextStyle(fontSize: 13, color: Color(0xFF7C3AED))),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ...allSessions.take(3).map((session) => SessionCard(
                  session: session,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SessionDetailScreen(session: session, isAdmin: true),
                      ),
                    );
                  },
                  trailingAction: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SessionMonitorScreen(session: session),
                              ),
                            );
                          },
                          icon: const Icon(Icons.people_alt_outlined, size: 16),
                          label: const Text('Monitoring Peserta'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF7C3AED)),
                            foregroundColor: const Color(0xFF7C3AED),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF64748B), size: 20),
                        tooltip: 'Edit Sesi',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SessionFormScreen(session: session),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 6),
            Text(
              count,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
