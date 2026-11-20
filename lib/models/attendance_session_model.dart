import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/date_helper.dart';

/// Model Sesi Presensi (Attendance Session)
/// Mendukung mode tanggal tunggal (single date) maupun jadwal rutinan (recurring, misal: Setiap Senin, Senin - Kamis).
class AttendanceSessionModel {
  final String id;
  final String title;
  final String description;
  final String location;

  /// Tipe jadwal: 'single' (tanggal tertentu) atau 'recurring' (rutinan)
  final String scheduleType;

  /// Untuk sesi tunggal (single date):
  final DateTime startAt;
  final DateTime endAt;
  final DateTime checkInOpensAt;
  final DateTime checkInOnTimeUntil;
  final DateTime checkInClosesAt;
  final DateTime checkOutOpensAt;
  final DateTime checkOutDueAt;
  final DateTime checkOutClosesAt;

  /// Untuk sesi rutinan (recurring):
  /// Daftar hari dalam seminggu: 1 = Senin, 2 = Selasa, ..., 7 = Minggu (DateTime.monday s/d DateTime.sunday)
  final List<int> recurringDays;
  final TimeOfDay? recurringStartTime;
  final TimeOfDay? recurringEndTime;
  final TimeOfDay? recurringCheckInOpens;
  final TimeOfDay? recurringCheckInOnTimeUntil;
  final TimeOfDay? recurringCheckInCloses;
  final TimeOfDay? recurringCheckOutOpens;
  final TimeOfDay? recurringCheckOutDue;
  final TimeOfDay? recurringCheckOutCloses;

  /// Status sesi: 'published', 'draft', 'cancelled', 'completed'
  final String status;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AttendanceSessionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    this.scheduleType = 'single',
    required this.startAt,
    required this.endAt,
    required this.checkInOpensAt,
    required this.checkInOnTimeUntil,
    required this.checkInClosesAt,
    required this.checkOutOpensAt,
    required this.checkOutDueAt,
    required this.checkOutClosesAt,
    this.recurringDays = const [],
    this.recurringStartTime,
    this.recurringEndTime,
    this.recurringCheckInOpens,
    this.recurringCheckInOnTimeUntil,
    this.recurringCheckInCloses,
    this.recurringCheckOutOpens,
    this.recurringCheckOutDue,
    this.recurringCheckOutCloses,
    this.status = 'published',
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  bool get isRecurring => scheduleType == 'recurring';
  bool get isSingle => scheduleType == 'single';

  /// Memeriksa apakah sesi dijadwalkan pada hari/tanggal tertentu
  bool isScheduledForDate(DateTime date) {
    if (status == 'cancelled' || status == 'draft') return false;

    if (isSingle) {
      return date.year == startAt.year &&
          date.month == startAt.month &&
          date.day == startAt.day;
    } else {
      // Rutinan: cek apakah hari ini cocok dengan recurringDays
      return recurringDays.contains(date.weekday);
    }
  }

  /// Memeriksa apakah sesi dijadwalkan untuk hari ini
  bool isScheduledForToday() {
    return isScheduledForDate(DateTime.now());
  }

  /// Menghitung jadwal tanggal & jam lengkap untuk tanggal acuan tertentu
  Map<String, DateTime> getScheduleForDate(DateTime targetDate) {
    if (isSingle) {
      return {
        'startAt': startAt,
        'endAt': endAt,
        'checkInOpensAt': checkInOpensAt,
        'checkInOnTimeUntil': checkInOnTimeUntil,
        'checkInClosesAt': checkInClosesAt,
        'checkOutOpensAt': checkOutOpensAt,
        'checkOutDueAt': checkOutDueAt,
        'checkOutClosesAt': checkOutClosesAt,
      };
    }

    // Untuk rutinan, gabungkan targetDate dengan TimeOfDay masing-masing
    DateTime combine(DateTime base, TimeOfDay? time, TimeOfDay fallback) {
      final t = time ?? fallback;
      return DateTime(base.year, base.month, base.day, t.hour, t.minute);
    }

    final sTime = combine(targetDate, recurringStartTime, const TimeOfDay(hour: 8, minute: 0));
    final eTime = combine(targetDate, recurringEndTime, const TimeOfDay(hour: 16, minute: 0));
    final cinOpen = combine(targetDate, recurringCheckInOpens, const TimeOfDay(hour: 7, minute: 0));
    final cinOnTime = combine(targetDate, recurringCheckInOnTimeUntil, const TimeOfDay(hour: 8, minute: 0));
    final cinClose = combine(targetDate, recurringCheckInCloses, const TimeOfDay(hour: 9, minute: 0));
    final coutOpen = combine(targetDate, recurringCheckOutOpens, const TimeOfDay(hour: 15, minute: 0));
    final coutDue = combine(targetDate, recurringCheckOutDue, const TimeOfDay(hour: 16, minute: 0));
    final coutClose = combine(targetDate, recurringCheckOutCloses, const TimeOfDay(hour: 17, minute: 0));

    return {
      'startAt': sTime,
      'endAt': eTime,
      'checkInOpensAt': cinOpen,
      'checkInOnTimeUntil': cinOnTime,
      'checkInClosesAt': cinClose,
      'checkOutOpensAt': coutOpen,
      'checkOutDueAt': coutDue,
      'checkOutClosesAt': coutClose,
    };
  }

  /// Menghasilkan label teks hari rutinan (misal: "Setiap Senin", "Setiap Senin - Kamis", "Setiap Hari")
  String get recurringDaysText {
    if (!isRecurring || recurringDays.isEmpty) {
      return DateHelper.formatDate(startAt);
    }

    final dayNames = {
      1: 'Senin',
      2: 'Selasa',
      3: 'Rabu',
      4: 'Kamis',
      5: 'Jumat',
      6: 'Sabtu',
      7: 'Minggu',
    };

    final sorted = List<int>.from(recurringDays)..sort();

    if (sorted.length == 7) return 'Setiap Hari';
    if (sorted.length == 5 && sorted.every((d) => d >= 1 && d <= 5)) return 'Senin - Jumat';
    if (sorted.length == 4 && sorted.every((d) => d >= 1 && d <= 4)) return 'Senin - Kamis';

    return sorted.map((d) => dayNames[d] ?? '').where((s) => s.isNotEmpty).join(', ');
  }

  /// Mengonversi dari Firestore Map
  factory AttendanceSessionModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseTime(dynamic val, DateTime fallback) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? fallback;
      return fallback;
    }

    TimeOfDay? parseTimeOfDay(Map<String, dynamic>? timeMap) {
      if (timeMap == null) return null;
      return TimeOfDay(
        hour: timeMap['hour'] as int? ?? 0,
        minute: timeMap['minute'] as int? ?? 0,
      );
    }

    final now = DateTime.now();

    return AttendanceSessionModel(
      id: docId,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      location: map['location'] as String? ?? '',
      scheduleType: map['scheduleType'] as String? ?? 'single',
      startAt: parseTime(map['startAt'], now),
      endAt: parseTime(map['endAt'], now.add(const Duration(hours: 4))),
      checkInOpensAt: parseTime(map['checkInOpensAt'], now.subtract(const Duration(minutes: 30))),
      checkInOnTimeUntil: parseTime(map['checkInOnTimeUntil'], now),
      checkInClosesAt: parseTime(map['checkInClosesAt'], now.add(const Duration(hours: 1))),
      checkOutOpensAt: parseTime(map['checkOutOpensAt'], now.add(const Duration(hours: 3))),
      checkOutDueAt: parseTime(map['checkOutDueAt'], now.add(const Duration(hours: 4))),
      checkOutClosesAt: parseTime(map['checkOutClosesAt'], now.add(const Duration(hours: 5))),
      recurringDays: (map['recurringDays'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [],
      recurringStartTime: parseTimeOfDay(map['recurringStartTime'] as Map<String, dynamic>?),
      recurringEndTime: parseTimeOfDay(map['recurringEndTime'] as Map<String, dynamic>?),
      recurringCheckInOpens: parseTimeOfDay(map['recurringCheckInOpens'] as Map<String, dynamic>?),
      recurringCheckInOnTimeUntil: parseTimeOfDay(map['recurringCheckInOnTimeUntil'] as Map<String, dynamic>?),
      recurringCheckInCloses: parseTimeOfDay(map['recurringCheckInCloses'] as Map<String, dynamic>?),
      recurringCheckOutOpens: parseTimeOfDay(map['recurringCheckOutOpens'] as Map<String, dynamic>?),
      recurringCheckOutDue: parseTimeOfDay(map['recurringCheckOutDue'] as Map<String, dynamic>?),
      recurringCheckOutCloses: parseTimeOfDay(map['recurringCheckOutCloses'] as Map<String, dynamic>?),
      status: map['status'] as String? ?? 'published',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: (map['createdAt'] is Timestamp) ? (map['createdAt'] as Timestamp).toDate() : null,
      updatedAt: (map['updatedAt'] is Timestamp) ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  factory AttendanceSessionModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    return AttendanceSessionModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic>? timeOfDayToMap(TimeOfDay? time) {
      if (time == null) return null;
      return {'hour': time.hour, 'minute': time.minute};
    }

    return {
      'title': title,
      'description': description,
      'location': location,
      'scheduleType': scheduleType,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'checkInOpensAt': Timestamp.fromDate(checkInOpensAt),
      'checkInOnTimeUntil': Timestamp.fromDate(checkInOnTimeUntil),
      'checkInClosesAt': Timestamp.fromDate(checkInClosesAt),
      'checkOutOpensAt': Timestamp.fromDate(checkOutOpensAt),
      'checkOutDueAt': Timestamp.fromDate(checkOutDueAt),
      'checkOutClosesAt': Timestamp.fromDate(checkOutClosesAt),
      'recurringDays': recurringDays,
      'recurringStartTime': timeOfDayToMap(recurringStartTime),
      'recurringEndTime': timeOfDayToMap(recurringEndTime),
      'recurringCheckInOpens': timeOfDayToMap(recurringCheckInOpens),
      'recurringCheckInOnTimeUntil': timeOfDayToMap(recurringCheckInOnTimeUntil),
      'recurringCheckInCloses': timeOfDayToMap(recurringCheckInCloses),
      'recurringCheckOutOpens': timeOfDayToMap(recurringCheckOutOpens),
      'recurringCheckOutDue': timeOfDayToMap(recurringCheckOutDue),
      'recurringCheckOutCloses': timeOfDayToMap(recurringCheckOutCloses),
      'status': status,
      'createdBy': createdBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
