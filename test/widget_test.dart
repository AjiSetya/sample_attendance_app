import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_app/screens/auth/login_screen.dart';

void main() {
  testWidgets('Smart Attendance login screen smoke test', (WidgetTester tester) async {
    // Memverifikasi bahwa komponen antarmuka LoginScreen dapat dirender tanpa error
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    // Memverifikasi teks judul aplikasi tampil pada Login Screen
    expect(find.text('Smart Attendance'), findsOneWidget);
  });
}
