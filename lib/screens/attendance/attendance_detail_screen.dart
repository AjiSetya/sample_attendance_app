import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/attendance_record_model.dart';
import '../../utils/date_helper.dart';
import '../../widgets/attendance_status_badge.dart';

/// Halaman Detail Bukti Presensi (Menampilkan foto Base64 dan waktu check-in & check-out).
class AttendanceDetailScreen extends StatelessWidget {
  final AttendanceRecordModel record;

  const AttendanceDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Detail Presensi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kartu Info Sesi & Peserta
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.sessionTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        record.participantName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
                      ),
                      if (record.attendanceDate.isNotEmpty) ...[
                        const Spacer(),
                        Text(
                          record.attendanceDate,
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Kartu Check-In
            _buildAttendanceCard(
              title: 'Presensi Masuk (Check-In)',
              icon: Icons.login,
              time: record.checkInAt,
              status: record.checkInStatus,
              isCompleted: record.checkInAt != null,
              photoData: record.checkInPhotoUrl,
              photoPath: record.checkInPhotoPath,
            ),
            const SizedBox(height: 16),

            // Kartu Check-Out
            _buildAttendanceCard(
              title: 'Presensi Keluar (Check-Out)',
              icon: Icons.logout,
              time: record.checkOutAt,
              status: record.checkOutStatus,
              isCompleted: record.checkOutAt != null,
              photoData: record.checkOutPhotoUrl,
              photoPath: record.checkOutPhotoPath,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard({
    required String title,
    required IconData icon,
    required DateTime? time,
    required String status,
    required bool isCompleted,
    String? photoData,
    String? photoPath,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: const Color(0xFF0284C7)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(width: 8),
              AttendanceStatusBadge(status: status),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),

          if (isCompleted && time != null) ...[
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  'Waktu: ${DateHelper.formatDateTime(time)}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Foto Bukti Kehadiran (Base64 Database):',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            // Tampilan Foto (Mendukung Base64 dari Firebase Database maupun URL gambar)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 220,
                width: double.infinity,
                color: const Color(0xFFF1F5F9),
                child: _buildPhotoWidget(photoData, photoPath),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.hourglass_empty, size: 36, color: Color(0xFF94A3B8)),
                  SizedBox(height: 6),
                  Text(
                    'Belum melakukan presensi pada sesi ini',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoWidget(String? photoData, String? photoPath) {
    if (photoData != null && photoData.trim().isNotEmpty) {
      // 1. Coba decode sebagai string Base64 (penyimpanan Firebase Database)
      try {
        String cleanBase64 = photoData.trim();
        if (cleanBase64.contains(',')) {
          cleanBase64 = cleanBase64.split(',').last;
        }
        final bytes = base64Decode(cleanBase64);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderPhoto(photoPath),
        );
      } catch (_) {
        // 2. Jika bukan Base64, coba render sebagai Image Network URL
        if (photoData.startsWith('http://') || photoData.startsWith('https://')) {
          return Image.network(
            photoData,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            },
            errorBuilder: (context, error, stackTrace) => _buildPlaceholderPhoto(photoPath),
          );
        }
      }
    }
    return _buildPlaceholderPhoto(photoPath);
  }

  Widget _buildPlaceholderPhoto(String? path) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt_outlined, size: 44, color: Colors.blue.shade300),
        const SizedBox(height: 8),
        Text(
          'Foto Bukti Kehadiran (${record.participantName})',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Colors.blueGrey.shade700),
        ),
        if (path != null && path.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Lokasi Database: $path',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
