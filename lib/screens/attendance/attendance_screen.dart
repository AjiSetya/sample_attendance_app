import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/dummy_data.dart';
import '../../widgets/attendance_status_badge.dart';
import '../../widgets/custom_button.dart';

/// Halaman untuk mengambil foto presensi (Check-in atau Check-out).
class AttendanceScreen extends StatefulWidget {
  final DummySession session;
  final bool isCheckOut;

  const AttendanceScreen({
    super.key,
    required this.session,
    this.isCheckOut = false,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _capturedImage;
  bool _isSimulated = false;
  bool _isSubmitting = false;

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          _capturedImage = photo;
          _isSimulated = false;
        });
      }
    } catch (e) {
      // Jika kamera tidak dapat diakses (misalnya di simulator atau izin belum ada)
      _useSimulatedPhoto();
    }
  }

  void _useSimulatedPhoto() {
    setState(() {
      _capturedImage = null;
      _isSimulated = true;
    });
  }

  void _handleSubmit() async {
    if (_capturedImage == null && !_isSimulated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan ambil foto bukti presensi terlebih dahulu'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    // Simulasi kompresi dan upload pada Fase 2 (data dummy)
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // Dialog Hasil Presensi
    final isLate = DateTime.now().isAfter(widget.session.checkInOnTimeUntil);
    final status = isLate ? 'late' : 'on_time';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isLate ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
              color: isLate ? const Color(0xFFD97706) : const Color(0xFF16A34A),
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(widget.isCheckOut ? 'Check-Out Berhasil!' : 'Check-In Berhasil!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Presensi Anda pada sesi "${widget.session.title}" telah tercatat.'),
            const SizedBox(height: 12),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                const Text('Status Kehadiran: ', style: TextStyle(fontWeight: FontWeight.w500)),
                AttendanceStatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isLate
                  ? 'Catatan: Anda tercatat terlambat karena melewati batas waktu tepat waktu.'
                  : 'Catatan: Selamat! Anda presensi tepat waktu.',
              style: TextStyle(
                fontSize: 12.5,
                color: isLate ? const Color(0xFFB45309) : const Color(0xFF15803D),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Kembali ke halaman sebelumnya
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
            ),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isCheckOut ? 'Presensi Check-Out' : 'Presensi Check-In';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Sesi
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.session.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lokasi: ${widget.session.location}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Area Kamera / Preview Foto
            const Text(
              'Foto Bukti Kehadiran',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ambil foto selfie Anda di lokasi kegiatan sebagai bukti absensi.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),

            Container(
              height: 280,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildCameraPreview(),
            ),

            const SizedBox(height: 16),

            // Tombol Kamera & Simulasi
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: Text(_capturedImage != null || _isSimulated ? 'Ambil Ulang' : 'Buka Kamera'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFF0284C7)),
                      foregroundColor: const Color(0xFF0284C7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _useSimulatedPhoto,
                    icon: const Icon(Icons.auto_fix_high, size: 18),
                    label: const Text('Foto Dummy'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFF64748B)),
                      foregroundColor: const Color(0xFF475569),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Tombol Konfirmasi Presensi
            CustomButton(
              text: widget.isCheckOut ? 'Konfirmasi Check-Out' : 'Konfirmasi Check-In',
              icon: Icons.send_rounded,
              isLoading: _isSubmitting,
              onPressed: (_capturedImage != null || _isSimulated) ? _handleSubmit : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_capturedImage != null) {
      return Image.file(
        File(_capturedImage!.path),
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }

    if (_isSimulated) {
      return Container(
        color: const Color(0xFF1E293B),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFF334155),
              child: Icon(Icons.person, size: 48, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            const Text(
              'Foto Selfie Terlampir (Mode Dummy)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Ahmad Fauzi • ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined, size: 56, color: Colors.white.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          const Text(
            'Kamera belum aktif',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tekan tombol "Buka Kamera" atau "Foto Dummy"',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
