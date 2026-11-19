/// Struktur data sederhana untuk keperluan UI Dummy pada Fase 2.
class DummyUser {
  final String uid;
  final String displayName;
  final String email;
  final String phone;
  final String role; // 'admin' atau 'participant'
  final DateTime createdAt;

  DummyUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.role,
    required this.createdAt,
  });
}

class DummySession {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime checkInOpensAt;
  final DateTime checkInOnTimeUntil;
  final DateTime checkInClosesAt;
  final DateTime checkOutOpensAt;
  final DateTime checkOutDueAt;
  final DateTime checkOutClosesAt;
  final String status; // 'draft', 'published', 'cancelled', 'completed'
  final String createdBy;

  DummySession({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startAt,
    required this.endAt,
    required this.checkInOpensAt,
    required this.checkInOnTimeUntil,
    required this.checkInClosesAt,
    required this.checkOutOpensAt,
    required this.checkOutDueAt,
    required this.checkOutClosesAt,
    required this.status,
    required this.createdBy,
  });

  bool get isCheckInOpen {
    final now = DateTime.now();
    return now.isAfter(checkInOpensAt) && now.isBefore(checkInClosesAt);
  }

  bool get isCheckOutOpen {
    final now = DateTime.now();
    return now.isAfter(checkOutOpensAt) && now.isBefore(checkOutClosesAt);
  }
}

class DummyAttendanceRecord {
  final String sessionId;
  final String sessionTitle;
  final String participantUid;
  final String participantName;
  final DateTime? checkInAt;
  final String checkInStatus; // 'on_time', 'late', 'not_yet'
  final String? checkInPhotoUrl;
  final DateTime? checkOutAt;
  final String checkOutStatus; // 'on_time', 'late', 'not_yet'
  final String? checkOutPhotoUrl;

  DummyAttendanceRecord({
    required this.sessionId,
    required this.sessionTitle,
    required this.participantUid,
    required this.participantName,
    this.checkInAt,
    required this.checkInStatus,
    this.checkInPhotoUrl,
    this.checkOutAt,
    required this.checkOutStatus,
    this.checkOutPhotoUrl,
  });
}

/// Kumpulan data tiruan (dummy data) untuk pengujian UI.
class DummyData {
  static final DummyUser participantUser = DummyUser(
    uid: 'user_peserta_01',
    displayName: 'Ahmad Fauzi',
    email: 'ahmad.fauzi@email.com',
    phone: '081234567890',
    role: 'participant',
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
  );

  static final DummyUser adminUser = DummyUser(
    uid: 'user_admin_01',
    displayName: 'Budi Pratama (Admin)',
    email: 'admin.budi@email.com',
    phone: '081987654321',
    role: 'admin',
    createdAt: DateTime.now().subtract(const Duration(days: 60)),
  );

  static final List<DummySession> sessions = [
    DummySession(
      id: 'session_001',
      title: 'Workshop Flutter & Firebase',
      description: 'Pelatihan dasar pengembangan aplikasi mobile menggunakan Flutter dan integrasi Firebase backend.',
      location: 'Lab Komputer 3, Gedung Utama',
      startAt: DateTime.now().add(const Duration(hours: 1)),
      endAt: DateTime.now().add(const Duration(hours: 5)),
      checkInOpensAt: DateTime.now().subtract(const Duration(minutes: 30)),
      checkInOnTimeUntil: DateTime.now().add(const Duration(hours: 1)),
      checkInClosesAt: DateTime.now().add(const Duration(hours: 2)),
      checkOutOpensAt: DateTime.now().add(const Duration(hours: 4)),
      checkOutDueAt: DateTime.now().add(const Duration(hours: 5)),
      checkOutClosesAt: DateTime.now().add(const Duration(hours: 6)),
      status: 'published',
      createdBy: 'user_admin_01',
    ),
    DummySession(
      id: 'session_002',
      title: 'Seminar AI & Machine Learning',
      description: 'Pengenalan teknologi AI modern dan penerapannya di dunia industri terkini.',
      location: 'Auditorium Lantai 2',
      startAt: DateTime.now().add(const Duration(days: 1, hours: 2)),
      endAt: DateTime.now().add(const Duration(days: 1, hours: 6)),
      checkInOpensAt: DateTime.now().add(const Duration(days: 1, hours: 1)),
      checkInOnTimeUntil: DateTime.now().add(const Duration(days: 1, hours: 2)),
      checkInClosesAt: DateTime.now().add(const Duration(days: 1, hours: 3)),
      checkOutOpensAt: DateTime.now().add(const Duration(days: 1, hours: 5)),
      checkOutDueAt: DateTime.now().add(const Duration(days: 1, hours: 6)),
      checkOutClosesAt: DateTime.now().add(const Duration(days: 1, hours: 7)),
      status: 'published',
      createdBy: 'user_admin_01',
    ),
    DummySession(
      id: 'session_003',
      title: 'Pelatihan Cloud Architecture',
      description: 'Membahas arsitektur microservices dan serverless di platform cloud.',
      location: 'Ruang Teori B-102',
      startAt: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
      endAt: DateTime.now().subtract(const Duration(days: 2)),
      checkInOpensAt: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      checkInOnTimeUntil: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
      checkInClosesAt: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      checkOutOpensAt: DateTime.now().subtract(const Duration(days: 2, hours: 1)),
      checkOutDueAt: DateTime.now().subtract(const Duration(days: 2)),
      checkOutClosesAt: DateTime.now().subtract(const Duration(days: 2, hours: -1)),
      status: 'completed',
      createdBy: 'user_admin_01',
    ),
    DummySession(
      id: 'session_004',
      title: 'Rapat Koordinasi Mentor (Draft)',
      description: 'Rapat persiapan kurikulum pembelajaran semester genap.',
      location: 'Ruang Rapat Direksi',
      startAt: DateTime.now().add(const Duration(days: 5)),
      endAt: DateTime.now().add(const Duration(days: 5, hours: 2)),
      checkInOpensAt: DateTime.now().add(const Duration(days: 5, minutes: -30)),
      checkInOnTimeUntil: DateTime.now().add(const Duration(days: 5)),
      checkInClosesAt: DateTime.now().add(const Duration(days: 5, minutes: 30)),
      checkOutOpensAt: DateTime.now().add(const Duration(days: 5, hours: 1, minutes: 45)),
      checkOutDueAt: DateTime.now().add(const Duration(days: 5, hours: 2)),
      checkOutClosesAt: DateTime.now().add(const Duration(days: 5, hours: 2, minutes: 30)),
      status: 'draft',
      createdBy: 'user_admin_01',
    ),
  ];

  static final List<DummyAttendanceRecord> participantHistory = [
    DummyAttendanceRecord(
      sessionId: 'session_001',
      sessionTitle: 'Workshop Flutter & Firebase',
      participantUid: 'user_peserta_01',
      participantName: 'Ahmad Fauzi',
      checkInAt: DateTime.now().subtract(const Duration(minutes: 20)),
      checkInStatus: 'on_time',
      checkInPhotoUrl: null,
      checkOutAt: null,
      checkOutStatus: 'not_yet',
      checkOutPhotoUrl: null,
    ),
    DummyAttendanceRecord(
      sessionId: 'session_003',
      sessionTitle: 'Pelatihan Cloud Architecture',
      participantUid: 'user_peserta_01',
      participantName: 'Ahmad Fauzi',
      checkInAt: DateTime.now().subtract(const Duration(days: 2, hours: 3, minutes: 45)),
      checkInStatus: 'late',
      checkInPhotoUrl: null,
      checkOutAt: DateTime.now().subtract(const Duration(days: 2, minutes: 5)),
      checkOutStatus: 'on_time',
      checkOutPhotoUrl: null,
    ),
  ];

  static final List<DummyAttendanceRecord> session001Monitoring = [
    DummyAttendanceRecord(
      sessionId: 'session_001',
      sessionTitle: 'Workshop Flutter & Firebase',
      participantUid: 'user_peserta_01',
      participantName: 'Ahmad Fauzi',
      checkInAt: DateTime.now().subtract(const Duration(minutes: 25)),
      checkInStatus: 'on_time',
      checkOutAt: null,
      checkOutStatus: 'not_yet',
    ),
    DummyAttendanceRecord(
      sessionId: 'session_001',
      sessionTitle: 'Workshop Flutter & Firebase',
      participantUid: 'user_peserta_02',
      participantName: 'Siti Nurhaliza',
      checkInAt: DateTime.now().subtract(const Duration(minutes: 10)),
      checkInStatus: 'late',
      checkOutAt: null,
      checkOutStatus: 'not_yet',
    ),
    DummyAttendanceRecord(
      sessionId: 'session_001',
      sessionTitle: 'Workshop Flutter & Firebase',
      participantUid: 'user_peserta_03',
      participantName: 'Rian Pratama',
      checkInAt: DateTime.now().subtract(const Duration(minutes: 28)),
      checkInStatus: 'on_time',
      checkOutAt: null,
      checkOutStatus: 'not_yet',
    ),
    DummyAttendanceRecord(
      sessionId: 'session_001',
      sessionTitle: 'Workshop Flutter & Firebase',
      participantUid: 'user_peserta_04',
      participantName: 'Dewi Lestari',
      checkInAt: null,
      checkInStatus: 'not_yet',
      checkOutAt: null,
      checkOutStatus: 'not_yet',
    ),
  ];
}
