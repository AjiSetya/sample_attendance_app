import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class StorageUploadResult {
  final String storagePath;
  final String downloadUrl; // Menyimpan string Base64 atau URL
  final String base64Data;

  StorageUploadResult({
    required this.storagePath,
    required this.downloadUrl,
    required this.base64Data,
  });
}

/// Layanan Penyimpanan Foto Presensi ke Firebase Realtime Database dalam format Base64 (Gratis / Free Tier).
/// Mengompresi foto hingga ukuran sangat kecil (~20-30 KB) lalu menyimpan string Base64 ke Firebase Database.
class StorageService {
  /// URL Realtime Database regional asia-southeast1 milik pengguna
  static const String databaseUrl =
      'https://attendanceapp-9743f-default-rtdb.asia-southeast1.firebasedatabase.app';

  final FirebaseDatabase? _databaseInstance;

  StorageService({FirebaseDatabase? database}) : _databaseInstance = database;

  FirebaseDatabase get _database =>
      _databaseInstance ??
      FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: databaseUrl,
      );

  /// Mengompres foto menggunakan `flutter_image_compress`
  /// Resolusi dibatasi hingga 450x450 piksel dengan kualitas 50 agar ukuran string Base64 sangat ringan (~20 KB)
  Future<File> compressPhoto(File file) async {
    final tempDirPath = Directory.systemTemp.path;
    final targetPath =
        '$tempDirPath/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 50,
      minWidth: 450,
      minHeight: 450,
    );

    if (result != null) {
      return File(result.path);
    }
    return file;
  }

  /// Mengompres foto, mengonversi ke Base64, dan menyimpannya ke Firebase Realtime Database
  /// Path penyimpanan: `attendance_photos/{sessionId}/{participantUid}/{dateStr}_{type}`
  Future<StorageUploadResult> uploadAttendancePhoto({
    required File file,
    required String sessionId,
    required String participantUid,
    required String type, // 'checkin' atau 'checkout'
    required String dateStr, // format 'yyyyMMdd'
  }) async {
    // 1. Kompres foto
    final compressedFile = await compressPhoto(file);
    final bytes = await compressedFile.readAsBytes();

    // 2. Konversi ke string Base64
    final base64String = base64Encode(bytes);

    // 3. Simpan ke Firebase Realtime Database dengan batasan timeout agar tidak hang/stuck
    final dbPath = 'attendance_photos/$sessionId/$participantUid/${dateStr}_$type';

    try {
      final dbRef = _database.ref(dbPath);
      // Timeout 4 detik: jika database lambat merespons atau rules belum diatur, proses tidak akan menggantung
      await dbRef.set({
        'base64': base64String,
        'sessionId': sessionId,
        'participantUid': participantUid,
        'type': type,
        'date': dateStr,
        'createdAt': DateTime.now().toIso8601String(),
      }).timeout(const Duration(seconds: 4));
    } catch (e) {
      // Jika terjadi timeout atau error koneksi ke RTDB, proses presensi tetap berlanjut
      // dengan Base64 yang akan disimpan ke dokumen Cloud Firestore.
    }

    return StorageUploadResult(
      storagePath: dbPath,
      downloadUrl: base64String,
      base64Data: base64String,
    );
  }

  /// Mengambil data foto Base64 dari Firebase Realtime Database
  Future<String?> getPhotoBase64(String dbPath) async {
    try {
      final snapshot = await _database.ref(dbPath).get().timeout(const Duration(seconds: 4));
      if (snapshot.exists && snapshot.value is Map) {
        final map = snapshot.value as Map;
        return map['base64'] as String?;
      }
    } catch (_) {}
    return null;
  }
}
