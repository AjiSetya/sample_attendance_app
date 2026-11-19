import 'package:flutter/material.dart';
import '../../utils/date_helper.dart';
import '../../utils/dummy_data.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

/// Form Pembuatan dan Pengubahan Sesi Presensi oleh Admin.
class SessionFormScreen extends StatefulWidget {
  final DummySession? session;

  const SessionFormScreen({super.key, this.session});

  @override
  State<SessionFormScreen> createState() => _SessionFormScreenState();
}

class _SessionFormScreenState extends State<SessionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _locationController;

  late DateTime _startAt;
  late DateTime _endAt;
  late DateTime _checkInOpensAt;
  late DateTime _checkInOnTimeUntil;
  late DateTime _checkInClosesAt;
  late DateTime _checkOutOpensAt;
  late DateTime _checkOutDueAt;
  late DateTime _checkOutClosesAt;
  late String _status;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    if (widget.session != null) {
      final s = widget.session!;
      _titleController = TextEditingController(text: s.title);
      _descController = TextEditingController(text: s.description);
      _locationController = TextEditingController(text: s.location);
      _startAt = s.startAt;
      _endAt = s.endAt;
      _checkInOpensAt = s.checkInOpensAt;
      _checkInOnTimeUntil = s.checkInOnTimeUntil;
      _checkInClosesAt = s.checkInClosesAt;
      _checkOutOpensAt = s.checkOutOpensAt;
      _checkOutDueAt = s.checkOutDueAt;
      _checkOutClosesAt = s.checkOutClosesAt;
      _status = s.status;
    } else {
      _titleController = TextEditingController();
      _descController = TextEditingController();
      _locationController = TextEditingController();
      _startAt = now.add(const Duration(hours: 1));
      _endAt = now.add(const Duration(hours: 4));
      _checkInOpensAt = now.add(const Duration(minutes: 30));
      _checkInOnTimeUntil = now.add(const Duration(hours: 1));
      _checkInClosesAt = now.add(const Duration(hours: 2));
      _checkOutOpensAt = now.add(const Duration(hours: 3, minutes: 30));
      _checkOutDueAt = now.add(const Duration(hours: 4));
      _checkOutClosesAt = now.add(const Duration(hours: 5));
      _status = 'published';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(String label, DateTime initial, ValueChanged<DateTime> onPicked) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null || !mounted) return;

    final result = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    setState(() => onPicked(result));
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi urutan waktu yang logis
    if (_endAt.isBefore(_startAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waktu selesai acara harus setelah waktu mulai'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (_checkInClosesAt.isBefore(_checkInOpensAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waktu penutupan check-in harus setelah waktu pembukaan check-in'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    // Simulasi penyimpanan sesi pada Fase 2 (data dummy)
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.session != null ? 'Sesi berhasil diperbarui' : 'Sesi baru berhasil dibuat'),
        backgroundColor: const Color(0xFF15803D),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.session != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isEdit ? 'Ubah Sesi' : 'Buat Sesi Baru', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Informasi Dasar Sesi
              _buildSectionCard(
                title: 'Informasi Kegiatan',
                children: [
                  CustomTextField(
                    controller: _titleController,
                    label: 'Judul Sesi Kegiatan',
                    hint: 'Contoh: Workshop Flutter & Firebase',
                    prefixIcon: Icons.title,
                    validator: (val) => Validators.requiredField(val, fieldName: 'Judul sesi'),
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _descController,
                    label: 'Deskripsi Kegiatan',
                    hint: 'Jelaskan tujuan dan materi kegiatan...',
                    prefixIcon: Icons.description_outlined,
                    maxLines: 3,
                    validator: (val) => Validators.requiredField(val, fieldName: 'Deskripsi kegiatan'),
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _locationController,
                    label: 'Lokasi Kegiatan',
                    hint: 'Contoh: Lab Komputer 3 / Ruang Rapat',
                    prefixIcon: Icons.location_on_outlined,
                    validator: (val) => Validators.requiredField(val, fieldName: 'Lokasi kegiatan'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Waktu Pelaksanaan Acara
              _buildSectionCard(
                title: 'Jadwal Acara',
                children: [
                  _buildTimePickerTile('Waktu Mulai Acara', _startAt, (val) => _startAt = val),
                  const Divider(height: 14, color: Color(0xFFF1F5F9)),
                  _buildTimePickerTile('Waktu Selesai Acara', _endAt, (val) => _endAt = val),
                ],
              ),
              const SizedBox(height: 16),

              // Jadwal Check-In
              _buildSectionCard(
                title: 'Jadwal Check-In (Absensi Masuk)',
                children: [
                  _buildTimePickerTile('Check-In Dibuka', _checkInOpensAt, (val) => _checkInOpensAt = val),
                  const Divider(height: 14, color: Color(0xFFF1F5F9)),
                  _buildTimePickerTile('Batas Tepat Waktu', _checkInOnTimeUntil, (val) => _checkInOnTimeUntil = val, isHighlight: true),
                  const Divider(height: 14, color: Color(0xFFF1F5F9)),
                  _buildTimePickerTile('Check-In Ditutup', _checkInClosesAt, (val) => _checkInClosesAt = val),
                ],
              ),
              const SizedBox(height: 16),

              // Jadwal Check-Out
              _buildSectionCard(
                title: 'Jadwal Check-Out (Absensi Keluar)',
                children: [
                  _buildTimePickerTile('Check-Out Dibuka', _checkOutOpensAt, (val) => _checkOutOpensAt = val),
                  const Divider(height: 14, color: Color(0xFFF1F5F9)),
                  _buildTimePickerTile('Target Check-Out', _checkOutDueAt, (val) => _checkOutDueAt = val),
                  const Divider(height: 14, color: Color(0xFFF1F5F9)),
                  _buildTimePickerTile('Check-Out Ditutup', _checkOutClosesAt, (val) => _checkOutClosesAt = val),
                ],
              ),
              const SizedBox(height: 16),

              // Pengaturan Status Sesi
              _buildSectionCard(
                title: 'Status Publikasi',
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Status Sesi',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'published', child: Text('Dipublikasikan (Dapat dilihat peserta)')),
                      DropdownMenuItem(value: 'draft', child: Text('Draft (Hanya terlihat oleh admin)')),
                      DropdownMenuItem(value: 'completed', child: Text('Selesai')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Dibatalkan')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _status = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tombol Simpan
              CustomButton(
                text: isEdit ? 'Simpan Perubahan Sesi' : 'Buat Sesi Sekarang',
                icon: Icons.save_outlined,
                isLoading: _isSaving,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTimePickerTile(String label, DateTime value, ValueChanged<DateTime> onPicked, {bool isHighlight = false}) {
    return InkWell(
      onTap: () => _pickDateTime(label, value, onPicked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isHighlight ? const Color(0xFFD97706) : const Color(0xFF475569),
                  fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isHighlight ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_calendar, size: 14, color: isHighlight ? const Color(0xFFB45309) : const Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    DateHelper.formatDateTime(value),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isHighlight ? const Color(0xFFB45309) : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
