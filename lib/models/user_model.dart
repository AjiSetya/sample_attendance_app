import 'package:cloud_firestore/cloud_firestore.dart';

/// Model data pengguna (User) sesuai rancangan Cloud Firestore di PRD.
/// Path dokumen: `users/{uid}`
class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String phone;
  final String role; // 'participant' atau 'admin'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.phone = '',
    this.role = 'participant',
    this.createdAt,
    this.updatedAt,
  });

  /// Mengecek apakah pengguna memiliki hak akses Administrator
  bool get isAdmin => role == 'admin';

  /// Mengecek apakah pengguna adalah Peserta
  bool get isParticipant => role == 'participant';

  /// Mengonversi data Map dari Cloud Firestore menjadi objek UserModel
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime? parseTimestamp(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return UserModel(
      uid: documentId,
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: map['role'] as String? ?? 'participant',
      createdAt: parseTimestamp(map['createdAt']),
      updatedAt: parseTimestamp(map['updatedAt']),
    );
  }

  /// Membuat UserModel dari DocumentSnapshot Firestore
  factory UserModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserModel.fromMap(data, doc.id);
  }

  /// Mengonversi objek UserModel menjadi Map untuk disimpan ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'role': role,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Membuat salinan objek dengan nilai baru (berguna untuk pembaruan state)
  UserModel copyWith({
    String? displayName,
    String? email,
    String? phone,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
