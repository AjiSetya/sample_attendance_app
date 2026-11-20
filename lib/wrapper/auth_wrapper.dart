import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/admin_home_screen.dart';
import '../screens/home/participant_home_screen.dart';

/// Pembungkus Autentikasi (Auth Wrapper).
/// Memantau status login pengguna secara reaktif melalui Stream authStateChanges().
/// - Jika belum login: diarahkan ke LoginScreen.
/// - Jika sudah login: membaca profil pengguna di Firestore dan mengarahkan ke Dashboard sesuai Role.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, authSnapshot) {
        // 1. Kondisi saat status koneksi Firebase Auth sedang dimuat
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingSplash(message: 'Memeriksa sesi pengguna...');
        }

        final user = authSnapshot.data;

        // 2. Jika pengguna belum login, arahkan ke LoginScreen
        if (user == null) {
          return const LoginScreen();
        }

        // 3. Jika pengguna sedang login, ambil data profil pengguna dari Firestore
        return StreamBuilder<UserModel?>(
          stream: authService.streamUserProfile(user.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingSplash(message: 'Memuat profil...');
            }

            final userModel = userSnapshot.data;

            // Jika dokumen profil belum ada di Firestore, fallback ke model participant
            if (userModel == null) {
              return ParticipantHomeScreen(
                user: UserModel(
                  uid: user.uid,
                  displayName: user.displayName ?? 'Peserta',
                  email: user.email ?? '',
                  role: 'participant',
                ),
              );
            }

            // 4. Pengarahan berdasarkan role pengguna
            if (userModel.isAdmin) {
              return AdminHomeScreen(user: userModel);
            } else {
              return ParticipantHomeScreen(user: userModel);
            }
          },
        );
      },
    );
  }
}

class _LoadingSplash extends StatelessWidget {
  final String message;
  const _LoadingSplash({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
