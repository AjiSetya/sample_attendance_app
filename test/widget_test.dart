import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_app/main.dart';

void main() {
  testWidgets('Smart Attendance initial smoke test', (WidgetTester tester) async {
    // Memastikan widget MyApp dapat dirender dengan baik
    await tester.pumpWidget(const MyApp());

    // Memverifikasi keberadaan teks judul aplikasi pada Login Screen
    expect(find.text('Smart Attendance'), findsOneWidget);
  });
}
