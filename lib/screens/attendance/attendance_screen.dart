import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/attendance_session_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/attendance_status_badge.dart';
import '../../widgets/custom_button.dart';

/// Halaman untuk mengambil foto dan mencatat presensi (Check-in atau Check-out).
/// Terintegrasi dengan Firebase Storage dan Cloud Firestore.
class AttendanceScreen extends StatefulWidget {
  final AttendanceSessionModel session;
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
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

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
      // Jika kamera tidak dapat diakses (misalnya di emulator/simulator)
      _useSimulatedPhoto();
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
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
      _useSimulatedPhoto();
    }
  }

  void _useSimulatedPhoto() {
    setState(() {
      _capturedImage = null;
      _isSimulated = true;
    });
  }

  String _formatTodayDateStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<File> _getPhotoFile() async {
    if (_capturedImage != null) {
      return File(_capturedImage!.path);
    }

    // Buat file foto dummy untuk mode emulator/simulator
    final tempFile = File('${Directory.systemTemp.path}/dummy_attendance_photo.jpg');
    if (!tempFile.existsSync()) {
      // Data gambar JPEG minimal yang valid
      const dummyJpgBytes = [
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
        0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
        0x00, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01, 0x00, 0x01, 0x01, 0x01,
        0x11, 0x00, 0xFF, 0xC4, 0x00, 0x1F, 0x00, 0x00, 0x01, 0x05, 0x01, 0x01,
        0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0xFF,
        0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F, 0x00, 0xBF, 0x00, 0xFF,
        0xD9
      ];
      await tempFile.writeAsBytes(dummyJpgBytes);
    }
    return tempFile;
  }

  void _handleSubmit() async {
    if (_capturedImage == null && !_isSimulated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan ambil foto bukti presensi terlebih dahulu'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = _authService.currentUser;
      final uid = user?.uid ?? 'anon_user';
      final name = user?.displayName ?? 'Peserta';
      final todayStr = _formatTodayDateStr();
      final schedule = widget.session.getScheduleForDate(DateTime.now());

      // 1. Dapatkan file foto & upload ke Firebase Storage
      final photoFile = await _getPhotoFile();
      final type = widget.isCheckOut ? 'checkout' : 'checkin';

      String photoPath = '';
      String photoUrl = '';

      try {
        final uploadResult = await _storageService.uploadAttendancePhoto(
          file: photoFile,
          sessionId: widget.session.id,
          participantUid: uid,
          type: type,
          dateStr: todayStr.replaceAll('-', ''),
        );
        photoPath = uploadResult.storagePath;
        photoUrl = uploadResult.downloadUrl;
      } catch (storageError) {
        // Fallback jika Storage Rules atau emulator offline
        photoPath = 'attendance_photos/${widget.session.id}/$uid/${todayStr}_$type.jpg';
        photoUrl = '';
      }

      // 2. Simpan rekam kehadiran ke Cloud Firestore
      String resultStatus = 'on_time';

      if (!widget.isCheckOut) {
        final checkInOnTimeUntil = schedule['checkInOnTimeUntil']!;
        final record = await _firestoreService.recordCheckIn(
          session: widget.session,
          participantUid: uid,
          participantName: name,
          dateStr: todayStr,
          photoPath: photoPath,
          photoUrl: photoUrl,
          scheduleCheckInOnTimeUntil: checkInOnTimeUntil,
        );
        resultStatus = record.checkInStatus;
      } else {
        final checkOutDueAt = schedule['checkOutDueAt']!;
        await _firestoreService.recordCheckOut(
          sessionId: widget.session.id,
          participantUid: uid,
          dateStr: todayStr,
          photoPath: photoPath,
          photoUrl: photoUrl,
          scheduleCheckOutDueAt: checkOutDueAt,
        );
        final now = DateTime.now();
        resultStatus = now.isAfter(checkOutDueAt) ? 'late' : 'on_time';
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // 3. Tampilkan dialog sukses hasil presensi
      final isLate = resultStatus == 'late';

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
              Expanded(
                child: Text(widget.isCheckOut ? 'Check-Out Berhasil!' : 'Check-In Berhasil!'),
              ),
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
                  AttendanceStatusBadge(status: resultStatus),
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
                Navigator.pop(context); // Kembali ke halaman detail sesi
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mencatat presensi: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.session.location,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
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

            // Tombol Kamera, Galeri & Simulasi
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
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library_outlined, color: Color(0xFF0284C7)),
                  tooltip: 'Pilih dari Galeri',
                  style: IconButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _useSimulatedPhoto,
                  icon: const Icon(Icons.auto_fix_high, color: Color(0xFF64748B)),
                  tooltip: 'Gunakan Foto Dummy',
                  style: IconButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      final user = _authService.currentUser;
      final name = user?.displayName ?? 'Peserta';
      final timeStr =
          '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';

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
              '$name • $timeStr WIB',
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
            'Tekan tombol "Buka Kamera" atau pilih dari Galeri',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
