import 'package:cloud_firestore/cloud_firestore.dart';

/// Model Rekam Kehadiran (Attendance Record)
/// Path dokumen: `attendance_records/{sessionId}_{participantUid}_{dateStr}`
class AttendanceRecordModel {
  final String id;
  final String sessionId;
  final String sessionTitle;
  final String participantUid;
  final String participantName;
  final String attendanceDate; // Format 'yyyy-MM-dd'

  final DateTime? checkInAt;
  final String checkInStatus; // 'on_time', 'late', 'not_yet'
  final String? checkInPhotoPath;
  final String? checkInPhotoUrl;

  final DateTime? checkOutAt;
  final String checkOutStatus; // 'on_time', 'late', 'not_yet'
  final String? checkOutPhotoPath;
  final String? checkOutPhotoUrl;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AttendanceRecordModel({
    required this.id,
    required this.sessionId,
    required this.sessionTitle,
    required this.participantUid,
    required this.participantName,
    required this.attendanceDate,
    this.checkInAt,
    this.checkInStatus = 'not_yet',
    this.checkInPhotoPath,
    this.checkInPhotoUrl,
    this.checkOutAt,
    this.checkOutStatus = 'not_yet',
    this.checkOutPhotoPath,
    this.checkOutPhotoUrl,
    this.createdAt,
    this.updatedAt,
  });

  bool get hasCheckedIn => checkInAt != null;
  bool get hasCheckedOut => checkOutAt != null;

  factory AttendanceRecordModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return AttendanceRecordModel(
      id: docId,
      sessionId: map['sessionId'] as String? ?? '',
      sessionTitle: map['sessionTitle'] as String? ?? '',
      participantUid: map['participantUid'] as String? ?? '',
      participantName: map['participantName'] as String? ?? '',
      attendanceDate: map['attendanceDate'] as String? ?? '',
      checkInAt: parseTimestamp(map['checkInAt']),
      checkInStatus: map['checkInStatus'] as String? ?? 'not_yet',
      checkInPhotoPath: map['checkInPhotoPath'] as String?,
      checkInPhotoUrl: map['checkInPhotoUrl'] as String?,
      checkOutAt: parseTimestamp(map['checkOutAt']),
      checkOutStatus: map['checkOutStatus'] as String? ?? 'not_yet',
      checkOutPhotoPath: map['checkOutPhotoPath'] as String?,
      checkOutPhotoUrl: map['checkOutPhotoUrl'] as String?,
      createdAt: parseTimestamp(map['createdAt']),
      updatedAt: parseTimestamp(map['updatedAt']),
    );
  }

  factory AttendanceRecordModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    return AttendanceRecordModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'sessionTitle': sessionTitle,
      'participantUid': participantUid,
      'participantName': participantName,
      'attendanceDate': attendanceDate,
      'checkInAt': checkInAt != null ? Timestamp.fromDate(checkInAt!) : null,
      'checkInStatus': checkInStatus,
      'checkInPhotoPath': checkInPhotoPath,
      'checkInPhotoUrl': checkInPhotoUrl,
      'checkOutAt': checkOutAt != null ? Timestamp.fromDate(checkOutAt!) : null,
      'checkOutStatus': checkOutStatus,
      'checkOutPhotoPath': checkOutPhotoPath,
      'checkOutPhotoUrl': checkOutPhotoUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AttendanceRecordModel copyWith({
    String? sessionTitle,
    String? participantName,
    DateTime? checkInAt,
    String? checkInStatus,
    String? checkInPhotoPath,
    String? checkInPhotoUrl,
    DateTime? checkOutAt,
    String? checkOutStatus,
    String? checkOutPhotoPath,
    String? checkOutPhotoUrl,
    DateTime? updatedAt,
  }) {
    return AttendanceRecordModel(
      id: id,
      sessionId: sessionId,
      sessionTitle: sessionTitle ?? this.sessionTitle,
      participantUid: participantUid,
      participantName: participantName ?? this.participantName,
      attendanceDate: attendanceDate,
      checkInAt: checkInAt ?? this.checkInAt,
      checkInStatus: checkInStatus ?? this.checkInStatus,
      checkInPhotoPath: checkInPhotoPath ?? this.checkInPhotoPath,
      checkInPhotoUrl: checkInPhotoUrl ?? this.checkInPhotoUrl,
      checkOutAt: checkOutAt ?? this.checkOutAt,
      checkOutStatus: checkOutStatus ?? this.checkOutStatus,
      checkOutPhotoPath: checkOutPhotoPath ?? this.checkOutPhotoPath,
      checkOutPhotoUrl: checkOutPhotoUrl ?? this.checkOutPhotoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
