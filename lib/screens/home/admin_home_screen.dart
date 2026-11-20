import 'package:flutter/material.dart';
import '../../models/attendance_session_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/dummy_data.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/session_card.dart';
import '../profile/profile_screen.dart';
import '../session/session_detail_screen.dart';
import '../session/session_form_screen.dart';
import '../session/session_list_screen.dart';
import '../session/session_monitor_screen.dart';

/// Dashboard Utama untuk Pengguna dengan Peran Admin (Administrator).
/// Terhubung secara realtime dengan Cloud Firestore.
class AdminHomeScreen extends StatefulWidget {
  final UserModel? user;

  const AdminHomeScreen({super.key, this.user});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  int _currentIndex = 0;

  UserModel _getUser() {
    if (widget.user != null) return widget.user!;
    final fbUser = _authService.currentUser;
    if (fbUser != null) {
      return UserModel(
        uid: fbUser.uid,
        displayName: fbUser.displayName ?? 'Admin',
        email: fbUser.email ?? '',
        role: 'admin',
      );
    }
    final d = DummyData.adminUser;
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
      _buildAdminHomeContent(user),
      const SessionListScreen(isAdmin: true),
      ProfileScreen(user: user),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF7C3AED),
        unselectedItemColor: const Color(0xFF94A3B8),
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note),
            label: 'Kelola Sesi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil Admin',
          ),
        ],
      ),
    );
  }

  Widget _buildAdminHomeContent(UserModel user) {
    final displayName = user.displayName.isNotEmpty ? user.displayName : 'Admin';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';

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
                        'Panel Admin: $displayName',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        overflow: TextOverflow.ellipsis,
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
                          const Flexible(
                            child: Text(
                              '• Kelola sesi & presensi',
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
                  onTap: () => setState(() => _currentIndex = 2),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF7C3AED),
                    child: Text(
                      initial,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Kartu Ringkasan Statistik Realtime dari Cloud Firestore
            StreamBuilder<List<AttendanceSessionModel>>(
              stream: _firestoreService.streamAllSessions(),
              builder: (context, snapshot) {
                final allSessions = snapshot.data ?? [];
                final activeSessions = allSessions.where((s) => s.status == 'published').toList();
                final recurringCount = allSessions.where((s) => s.isRecurring).length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _buildMetricCard('Total Sesi', '${allSessions.length}', Icons.event, const Color(0xFF7C3AED)),
                        const SizedBox(width: 10),
                        _buildMetricCard('Sesi Aktif', '${activeSessions.length}', Icons.play_circle_outline, const Color(0xFF0284C7)),
                        const SizedBox(width: 10),
                        _buildMetricCard('Sesi Rutinan', '$recurringCount', Icons.repeat, const Color(0xFF16A34A)),
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

                    // Daftar Sesi dari Cloud Firestore
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daftar Sesi Terbaru',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _currentIndex = 1),
                          child: const Text('Kelola Semua', style: TextStyle(fontSize: 13, color: Color(0xFF7C3AED))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                    else if (allSessions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.event_note, size: 48, color: Color(0xFF94A3B8)),
                            SizedBox(height: 10),
                            Text(
                              'Belum Ada Sesi yang Dibuat',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tekan tombol "Buat Sesi Presensi Baru" di atas untuk menambahkan acara atau sesi rutinan.',
                              style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ...allSessions.take(4).map((session) => SessionCard(
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
                );
              },
            ),
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
