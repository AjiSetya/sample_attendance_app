import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';

/// Pembungkus Autentikasi (Auth Wrapper).
/// Pada Fase 2 (UI & Data Dummy), AuthWrapper mengarahkan pengguna ke LoginScreen.
/// Pada Fase 3 berikutnya, widget ini akan membaca Stream authStateChanges() dari FirebaseAuth.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen();
  }
}
