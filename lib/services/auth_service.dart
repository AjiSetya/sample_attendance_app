import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// Layanan Autentikasi Pengguna & Manajemen Profil Firestore.
/// Menangani proses registrasi, login, logout, sesi, dan pembaruan data pengguna.
class AuthService {
  final FirebaseAuth? _authInstance;
  final FirebaseFirestore? _firestoreInstance;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _authInstance = auth,
        _firestoreInstance = firestore;

  FirebaseAuth get _auth => _authInstance ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => _firestoreInstance ?? FirebaseFirestore.instance;

  /// Pengguna Firebase Auth yang sedang aktif
  User? get currentUser => _auth.currentUser;

  /// Stream perubahan status autentikasi (Login / Logout)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Registrasi akun baru menggunakan Email & Kata Sandi.
  /// Sesuai PRD, role akun baru secara otomatis ditetapkan sebagai 'participant'.
  Future<UserModel> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();
    final cleanPhone = phone?.trim() ?? '';

    // 1. Buat akun di Firebase Authentication
    final credential = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('Gagal membuat akun, user bernilai kosong.');
    }

    // 2. Simpan display name di Firebase Auth profile
    await user.updateDisplayName(cleanName);

    // 3. Buat dokumen profil di Cloud Firestore (users/{uid})
    final userDocRef = _firestore.collection('users').doc(user.uid);
    await userDocRef.set({
      'uid': user.uid,
      'displayName': cleanName,
      'email': cleanEmail,
      'phone': cleanPhone,
      'role': 'participant', // Wajib participant sesuai PRD
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return UserModel(
      uid: user.uid,
      displayName: cleanName,
      email: cleanEmail,
      phone: cleanPhone,
      role: 'participant',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Masuk (Login) menggunakan Email & Kata Sandi.
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Autentikasi di Firebase Auth
    final credential = await _auth.signInWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final user = credential.user;
    if (user == null) return null;

    // 2. Ambil data profil & role dari Firestore
    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (userDoc.exists) {
      return UserModel.fromDocument(userDoc);
    } else {
      // Penanganan pencegahan: Jika dokumen profil belum ada di Firestore, buat profil default
      final newModel = UserModel(
        uid: user.uid,
        displayName: user.displayName ?? cleanEmail.split('@').first,
        email: cleanEmail,
        phone: '',
        role: 'participant',
      );
      await _firestore.collection('users').doc(user.uid).set(newModel.toMap());
      return newModel;
    }
  }

  /// Keluar dari akun (Logout)
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Mengambil data profil pengguna berdasarkan UID satu kali (Future)
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromDocument(doc);
    }
    return null;
  }

  /// Memantau data profil pengguna secara realtime dari Firestore (Stream)
  Stream<UserModel?> streamUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromDocument(doc);
      }
      return null;
    });
  }

  /// Memperbarui nama lengkap dan nomor telepon pengguna
  /// Sesuai PRD: email dan role tidak dapat diubah dari edit profil
  Future<void> updateProfile({
    required String uid,
    required String displayName,
    String? phone,
  }) async {
    final cleanName = displayName.trim();
    final cleanPhone = phone?.trim() ?? '';

    // Perbarui dokumen Firestore
    await _firestore.collection('users').doc(uid).update({
      'displayName': cleanName,
      'phone': cleanPhone,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Perbarui display name di Firebase Auth jika user saat ini aktif
    if (_auth.currentUser?.uid == uid) {
      await _auth.currentUser?.updateDisplayName(cleanName);
    }
  }

  /// Menerjemahkan kode error Firebase Auth menjadi pesan bahasa Indonesia yang mudah dipahami pemula
  static String getFriendlyErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email atau kata sandi tidak cocok. Silakan periksa kembali.';
        case 'email-already-in-use':
          return 'Alamat email ini sudah terdaftar. Silakan gunakan email lain atau langsung masuk.';
        case 'invalid-email':
          return 'Format alamat email tidak valid.';
        case 'weak-password':
          return 'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.';
        case 'user-disabled':
          return 'Akun ini telah dinonaktifkan oleh administrator.';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan gagal. Silakan tunggu beberapa saat lagi.';
        case 'network-request-failed':
          return 'Koneksi gagal. Pastikan perangkat Anda terhubung ke internet.';
        default:
          return error.message ?? 'Terjadi kesalahan autentikasi (${error.code}).';
      }
    } else if (error is FirebaseException) {
      return error.message ?? 'Terjadi kesalahan pada Firebase (${error.code}).';
    }
    return error.toString();
  }
}
