import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_record_model.dart';
import '../models/attendance_session_model.dart';

/// Layanan Cloud Firestore untuk mengelola data Sesi Presensi dan Rekam Kehadiran.
class FirestoreService {
  final FirebaseFirestore? _firestoreInstance;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestoreInstance = firestore;

  FirebaseFirestore get _firestore =>
      _firestoreInstance ?? FirebaseFirestore.instance;

  // =========================================================================
  // MANAJEMEN SESI (ATTENDANCE SESSIONS)
  // =========================================================================

  /// Membuat sesi presensi baru di Firestore
  Future<String> createSession(AttendanceSessionModel session) async {
    final docRef = _firestore.collection('attendance_sessions').doc();
    final data = session.toMap();
    await docRef.set(data);
    return docRef.id;
  }

  /// Memperbarui informasi sesi presensi yang sudah ada
  Future<void> updateSession(AttendanceSessionModel session) async {
    await _firestore
        .collection('attendance_sessions')
        .doc(session.id)
        .update(session.toMap());
  }

  /// Menghapus sesi presensi
  Future<void> deleteSession(String sessionId) async {
    await _firestore.collection('attendance_sessions').doc(sessionId).delete();
  }

  /// Mengambil data satu sesi
  Future<AttendanceSessionModel?> getSession(String sessionId) async {
    final doc =
        await _firestore.collection('attendance_sessions').doc(sessionId).get();
    if (doc.exists) {
      return AttendanceSessionModel.fromDocument(doc);
    }
    return null;
  }

  /// Stream seluruh sesi presensi (untuk Admin)
  Stream<List<AttendanceSessionModel>> streamAllSessions() {
    return _firestore
        .collection('attendance_sessions')
        .orderBy('startAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceSessionModel.fromDocument(doc))
            .toList());
  }

  /// Stream sesi presensi yang dipublikasikan (untuk Peserta)
  Stream<List<AttendanceSessionModel>> streamPublishedSessions() {
    return _firestore
        .collection('attendance_sessions')
        .where('status', isEqualTo: 'published')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => AttendanceSessionModel.fromDocument(doc))
              .toList();
          // Urutkan berdasarkan waktu mulai terdekat
          list.sort((a, b) => a.startAt.compareTo(b.startAt));
          return list;
        });
  }

  // =========================================================================
  // MANAJEMEN PRESENSI (ATTENDANCE RECORDS)
  // =========================================================================

  /// Menghasilkan ID unik rekam kehadiran per hari per peserta: `${sessionId}_${uid}_${dateStr}`
  static String buildRecordId(
      String sessionId, String participantUid, String dateStr) {
    return '${sessionId}_${participantUid}_$dateStr';
  }

  /// Mengambil rekam kehadiran peserta untuk sesi dan tanggal hari ini
  Future<AttendanceRecordModel?> getAttendanceRecord({
    required String sessionId,
    required String participantUid,
    required String dateStr,
  }) async {
    final recordId = buildRecordId(sessionId, participantUid, dateStr);
    final doc =
        await _firestore.collection('attendance_records').doc(recordId).get();
    if (doc.exists) {
      return AttendanceRecordModel.fromDocument(doc);
    }
    return null;
  }

  /// Stream rekam kehadiran peserta hari ini secara realtime
  Stream<AttendanceRecordModel?> streamAttendanceRecord({
    required String sessionId,
    required String participantUid,
    required String dateStr,
  }) {
    final recordId = buildRecordId(sessionId, participantUid, dateStr);
    return _firestore
        .collection('attendance_records')
        .doc(recordId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return AttendanceRecordModel.fromDocument(doc);
      }
      return null;
    });
  }

  /// Mencatat presensi Check-In peserta
  Future<AttendanceRecordModel> recordCheckIn({
    required AttendanceSessionModel session,
    required String participantUid,
    required String participantName,
    required String dateStr,
    required String photoPath,
    required String photoUrl,
    required DateTime scheduleCheckInOnTimeUntil,
  }) async {
    final recordId = buildRecordId(session.id, participantUid, dateStr);
    final now = DateTime.now();
    final isLate = now.isAfter(scheduleCheckInOnTimeUntil);
    final status = isLate ? 'late' : 'on_time';

    final data = {
      'sessionId': session.id,
      'sessionTitle': session.title,
      'participantUid': participantUid,
      'participantName': participantName,
      'attendanceDate': dateStr,
      'checkInAt': FieldValue.serverTimestamp(),
      'checkInStatus': status,
      'checkInPhotoPath': photoPath,
      'checkInPhotoUrl': photoUrl,
      'checkOutAt': null,
      'checkOutStatus': 'not_yet',
      'checkOutPhotoPath': null,
      'checkOutPhotoUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final docRef = _firestore.collection('attendance_records').doc(recordId);
    await docRef.set(data, SetOptions(merge: true));

    return AttendanceRecordModel(
      id: recordId,
      sessionId: session.id,
      sessionTitle: session.title,
      participantUid: participantUid,
      participantName: participantName,
      attendanceDate: dateStr,
      checkInAt: now,
      checkInStatus: status,
      checkInPhotoPath: photoPath,
      checkInPhotoUrl: photoUrl,
      checkOutStatus: 'not_yet',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Mencatat presensi Check-Out peserta
  Future<void> recordCheckOut({
    required String sessionId,
    required String participantUid,
    required String dateStr,
    required String photoPath,
    required String photoUrl,
    required DateTime scheduleCheckOutDueAt,
  }) async {
    final recordId = buildRecordId(sessionId, participantUid, dateStr);
    final now = DateTime.now();
    final isLate = now.isAfter(scheduleCheckOutDueAt);
    final status = isLate ? 'late' : 'on_time';

    final docRef = _firestore.collection('attendance_records').doc(recordId);
    await docRef.update({
      'checkOutAt': FieldValue.serverTimestamp(),
      'checkOutStatus': status,
      'checkOutPhotoPath': photoPath,
      'checkOutPhotoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream riwayat seluruh presensi pribadi seorang peserta
  Stream<List<AttendanceRecordModel>> streamParticipantHistory(
      String participantUid) {
    return _firestore
        .collection('attendance_records')
        .where('participantUid', isEqualTo: participantUid)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => AttendanceRecordModel.fromDocument(doc))
              .toList();
          // Urutkan berdasarkan waktu presensi terbaru
          list.sort((a, b) {
            final aTime = a.checkInAt ?? a.createdAt ?? DateTime(2000);
            final bTime = b.checkInAt ?? b.createdAt ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });
          return list;
        });
  }

  /// Stream daftar kehadiran seluruh peserta pada sesi tertentu (untuk Monitoring Admin)
  Stream<List<AttendanceRecordModel>> streamSessionAttendance(String sessionId) {
    return _firestore
        .collection('attendance_records')
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => AttendanceRecordModel.fromDocument(doc))
              .toList();
          list.sort((a, b) {
            final aTime = a.checkInAt ?? a.createdAt ?? DateTime(2000);
            final bTime = b.checkInAt ?? b.createdAt ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });
          return list;
        });
  }
}
