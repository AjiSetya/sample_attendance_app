/// Kumpulan fungsi validasi sederhana untuk formulir input pengguna.
class Validators {
  /// Memeriksa apakah input teks tidak kosong
  static String? requiredField(String? value, {String fieldName = 'Kolom ini'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }

  /// Memvalidasi format email
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid (contoh: user@email.com)';
    }
    return null;
  }

  /// Memvalidasi kata sandi minimal 6 karakter
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kata sandi tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Kata sandi minimal harus 6 karakter';
    }
    return null;
  }

  /// Memvalidasi nomor telepon opsional
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Nomor telepon opsional
    }
    final phoneRegex = RegExp(r'^[0-9+]{9,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Nomor telepon tidak valid';
    }
    return null;
  }
}
