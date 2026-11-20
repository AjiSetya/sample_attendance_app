import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../utils/date_helper.dart';
import '../../utils/dummy_data.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

/// Halaman Profil Pengguna (Terintegrasi dengan Firebase Auth & Cloud Firestore).
class ProfileScreen extends StatefulWidget {
  final UserModel? user;

  const ProfileScreen({super.key, this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  late UserModel _currentUser;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Gunakan user yang diberikan, atau ambil dari currentUser jika ada, atau fallback ke dummy
    if (widget.user != null) {
      _currentUser = widget.user!;
    } else {
      final fbUser = _authService.currentUser;
      if (fbUser != null) {
        _currentUser = UserModel(
          uid: fbUser.uid,
          displayName: fbUser.displayName ?? '',
          email: fbUser.email ?? '',
          phone: '',
          role: 'participant',
          createdAt: DateTime.now(),
        );
      } else {
        final d = DummyData.participantUser;
        _currentUser = UserModel(
          uid: d.uid,
          displayName: d.displayName,
          email: d.email,
          phone: d.phone,
          role: d.role,
          createdAt: d.createdAt,
        );
      }
    }

    _nameController = TextEditingController(text: _currentUser.displayName);
    _phoneController = TextEditingController(text: _currentUser.phone);
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user != null && widget.user != oldWidget.user && !_isEditing) {
      setState(() {
        _currentUser = widget.user!;
        _nameController.text = _currentUser.displayName;
        _phoneController.text = _currentUser.phone;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Simpan perubahan ke Cloud Firestore dan Firebase Auth
      await _authService.updateProfile(
        uid: _currentUser.uid,
        displayName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _isEditing = false;
        _currentUser = _currentUser.copyWith(
          displayName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          updatedAt: DateTime.now(),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui'),
          backgroundColor: Color(0xFF15803D),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.getFriendlyErrorMessage(e)),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _authService.signOut();
              // AuthWrapper akan mendeteksi status logout dan otomatis mengarahkan ke LoginScreen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _currentUser.isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF0284C7)),
              tooltip: 'Ubah Profil',
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar dan Info Singkat
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: isAdmin ? const Color(0xFF7C3AED) : const Color(0xFF0284C7),
                      child: Text(
                        _currentUser.displayName.isNotEmpty ? _currentUser.displayName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currentUser.displayName.isNotEmpty ? _currentUser.displayName : 'Pengguna',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAdmin ? const Color(0xFFF3E8FF) : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        isAdmin ? 'Role: Administrator' : 'Role: Peserta (Participant)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isAdmin ? const Color(0xFF6B21A8) : const Color(0xFF0369A1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Kartu Form Profil
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Field Nama Lengkap (Editable)
                    CustomTextField(
                      controller: _nameController,
                      label: 'Nama Lengkap',
                      prefixIcon: Icons.person_outline,
                      readOnly: !_isEditing,
                      validator: (val) => Validators.requiredField(val, fieldName: 'Nama lengkap'),
                    ),
                    const SizedBox(height: 16),

                    // Field Nomor Telepon (Editable)
                    CustomTextField(
                      controller: _phoneController,
                      label: 'Nomor Telepon',
                      hint: '0812xxxxxxxx',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      readOnly: !_isEditing,
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 16),

                    // Field Email (Read-Only sesuai PRD)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Alamat Email',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                              child: const Text('Tetap', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.email_outlined, size: 20, color: Color(0xFF64748B)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _currentUser.email,
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tanggal Bergabung
                    if (_currentUser.createdAt != null)
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Text(
                            'Bergabung sejak: ${DateHelper.formatDate(_currentUser.createdAt!)}',
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Tombol Simpan saat dalam mode edit
              if (_isEditing) ...[
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Batal',
                        isOutlined: true,
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            _nameController.text = _currentUser.displayName;
                            _phoneController.text = _currentUser.phone;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Simpan',
                        isLoading: _isSaving,
                        onPressed: _handleSaveProfile,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Tombol Logout
              CustomButton(
                text: 'Keluar dari Akun',
                icon: Icons.logout,
                color: const Color(0xFFEF4444),
                isOutlined: true,
                onPressed: _handleLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
