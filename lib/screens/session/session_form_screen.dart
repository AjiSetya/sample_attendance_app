import 'package:flutter/material.dart';
import '../../models/attendance_session_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/date_helper.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

/// Form Pembuatan dan Pengubahan Sesi Presensi oleh Admin.
/// Mendukung mode jadwal:
/// 1. Berdasarkan tanggal spesifik (Single Date)
/// 2. Rutinan (Recurring), contoh: Setiap Senin, atau Setiap Senin - Kamis.
class SessionFormScreen extends StatefulWidget {
  final AttendanceSessionModel? session;

  const SessionFormScreen({super.key, this.session});

  @override
  State<SessionFormScreen> createState() => _SessionFormScreenState();
}

class _SessionFormScreenState extends State<SessionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _locationController;

  late String _scheduleType; // 'single' atau 'recurring'
  late String _status; // 'published', 'draft', 'completed', 'cancelled'

  // Properti untuk Single Date
  late DateTime _sessionDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late TimeOfDay _checkInOpens;
  late TimeOfDay _checkInOnTimeUntil;
  late TimeOfDay _checkInCloses;
  late TimeOfDay _checkOutOpens;
  late TimeOfDay _checkOutDue;
  late TimeOfDay _checkOutCloses;

  // Properti untuk Rutinan (Recurring): 1=Senin s/d 7=Minggu
  late List<int> _recurringDays;

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
      _scheduleType = s.scheduleType;
      _status = s.status;

      _sessionDate = s.startAt;
      _startTime = s.isRecurring
          ? (s.recurringStartTime ?? TimeOfDay.fromDateTime(s.startAt))
          : TimeOfDay.fromDateTime(s.startAt);
      _endTime = s.isRecurring
          ? (s.recurringEndTime ?? TimeOfDay.fromDateTime(s.endAt))
          : TimeOfDay.fromDateTime(s.endAt);

      _checkInOpens = s.isRecurring
          ? (s.recurringCheckInOpens ?? TimeOfDay.fromDateTime(s.checkInOpensAt))
          : TimeOfDay.fromDateTime(s.checkInOpensAt);
      _checkInOnTimeUntil = s.isRecurring
          ? (s.recurringCheckInOnTimeUntil ?? TimeOfDay.fromDateTime(s.checkInOnTimeUntil))
          : TimeOfDay.fromDateTime(s.checkInOnTimeUntil);
      _checkInCloses = s.isRecurring
          ? (s.recurringCheckInCloses ?? TimeOfDay.fromDateTime(s.checkInClosesAt))
          : TimeOfDay.fromDateTime(s.checkInClosesAt);

      _checkOutOpens = s.isRecurring
          ? (s.recurringCheckOutOpens ?? TimeOfDay.fromDateTime(s.checkOutOpensAt))
          : TimeOfDay.fromDateTime(s.checkOutOpensAt);
      _checkOutDue = s.isRecurring
          ? (s.recurringCheckOutDue ?? TimeOfDay.fromDateTime(s.checkOutDueAt))
          : TimeOfDay.fromDateTime(s.checkOutDueAt);
      _checkOutCloses = s.isRecurring
          ? (s.recurringCheckOutCloses ?? TimeOfDay.fromDateTime(s.checkOutClosesAt))
          : TimeOfDay.fromDateTime(s.checkOutClosesAt);

      _recurringDays = List<int>.from(s.recurringDays);
    } else {
      _titleController = TextEditingController();
      _descController = TextEditingController();
      _locationController = TextEditingController();
      _scheduleType = 'single';
      _status = 'published';

      _sessionDate = now.add(const Duration(hours: 1));
      _startTime = const TimeOfDay(hour: 8, minute: 0);
      _endTime = const TimeOfDay(hour: 16, minute: 0);

      _checkInOpens = const TimeOfDay(hour: 7, minute: 0);
      _checkInOnTimeUntil = const TimeOfDay(hour: 8, minute: 0);
      _checkInCloses = const TimeOfDay(hour: 9, minute: 0);

      _checkOutOpens = const TimeOfDay(hour: 15, minute: 0);
      _checkOutDue = const TimeOfDay(hour: 16, minute: 0);
      _checkOutCloses = const TimeOfDay(hour: 17, minute: 0);

      _recurringDays = [1]; // Default: Hari Senin
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sessionDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _sessionDate = picked);
    }
  }

  Future<void> _pickTime(TimeOfDay current, ValueChanged<TimeOfDay> onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (picked != null) {
      setState(() => onPicked(picked));
    }
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_scheduleType == 'recurring' && _recurringDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu hari untuk jadwal rutinan sesi.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final startAt = _combineDateAndTime(_sessionDate, _startTime);
    final endAt = _combineDateAndTime(_sessionDate, _endTime);
    final checkInOpensAt = _combineDateAndTime(_sessionDate, _checkInOpens);
    final checkInOnTimeUntil = _combineDateAndTime(_sessionDate, _checkInOnTimeUntil);
    final checkInClosesAt = _combineDateAndTime(_sessionDate, _checkInCloses);
    final checkOutOpensAt = _combineDateAndTime(_sessionDate, _checkOutOpens);
    final checkOutDueAt = _combineDateAndTime(_sessionDate, _checkOutDue);
    final checkOutClosesAt = _combineDateAndTime(_sessionDate, _checkOutCloses);

    // Validasi urutan waktu
    if (endAt.isBefore(startAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jam selesai acara harus setelah jam mulai.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (checkInClosesAt.isBefore(checkInOpensAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jam penutupan check-in harus setelah jam pembukaan check-in.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentUid = _authService.currentUser?.uid ?? 'admin_uid';

      final sessionModel = AttendanceSessionModel(
        id: widget.session?.id ?? '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        location: _locationController.text.trim(),
        scheduleType: _scheduleType,
        startAt: startAt,
        endAt: endAt,
        checkInOpensAt: checkInOpensAt,
        checkInOnTimeUntil: checkInOnTimeUntil,
        checkInClosesAt: checkInClosesAt,
        checkOutOpensAt: checkOutOpensAt,
        checkOutDueAt: checkOutDueAt,
        checkOutClosesAt: checkOutClosesAt,
        recurringDays: _recurringDays,
        recurringStartTime: _startTime,
        recurringEndTime: _endTime,
        recurringCheckInOpens: _checkInOpens,
        recurringCheckInOnTimeUntil: _checkInOnTimeUntil,
        recurringCheckInCloses: _checkInCloses,
        recurringCheckOutOpens: _checkOutOpens,
        recurringCheckOutDue: _checkOutDue,
        recurringCheckOutCloses: _checkOutCloses,
        status: _status,
        createdBy: widget.session?.createdBy ?? currentUid,
        createdAt: widget.session?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.session != null) {
        await _firestoreService.updateSession(sessionModel);
      } else {
        await _firestoreService.createSession(sessionModel);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.session != null
              ? 'Sesi berhasil diperbarui'
              : 'Sesi baru berhasil disimpan ke Firestore'),
          backgroundColor: const Color(0xFF15803D),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan sesi: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.session != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isEdit ? 'Ubah Sesi Presensi' : 'Buat Sesi Presensi Baru',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                    hint: 'Contoh: Workshop Flutter & Firebase / Kerja Harian',
                    prefixIcon: Icons.title,
                    validator: (val) =>
                        Validators.requiredField(val, fieldName: 'Judul sesi'),
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _descController,
                    label: 'Deskripsi Kegiatan',
                    hint: 'Jelaskan tujuan dan materi kegiatan...',
                    prefixIcon: Icons.description_outlined,
                    maxLines: 3,
                    validator: (val) =>
                        Validators.requiredField(val, fieldName: 'Deskripsi kegiatan'),
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _locationController,
                    label: 'Lokasi Kegiatan',
                    hint: 'Contoh: Lab Komputer 3 / Kantor Utama',
                    prefixIcon: Icons.location_on_outlined,
                    validator: (val) =>
                        Validators.requiredField(val, fieldName: 'Lokasi kegiatan'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // PENGATURAN TIPE JADWAL (Single Date vs Rutinan)
              _buildSectionCard(
                title: 'Jenis Jadwal Pelaksanaan',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text('Sekali / Tanggal Tertentu'),
                            ),
                          ),
                          selected: _scheduleType == 'single',
                          onSelected: (val) {
                            if (val) setState(() => _scheduleType = 'single');
                          },
                          selectedColor: const Color(0xFFE0F2FE),
                          labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: _scheduleType == 'single'
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: _scheduleType == 'single'
                                ? const Color(0xFF0284C7)
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text('Rutinan / Berulang'),
                            ),
                          ),
                          selected: _scheduleType == 'recurring',
                          onSelected: (val) {
                            if (val) setState(() => _scheduleType = 'recurring');
                          },
                          selectedColor: const Color(0xFFEDE9FE),
                          labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: _scheduleType == 'recurring'
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: _scheduleType == 'recurring'
                                ? const Color(0xFF7C3AED)
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_scheduleType == 'single') ...[
                    // Pemilih Tanggal Acara
                    InkWell(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, color: Color(0xFF0284C7), size: 20),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tanggal Pelaksanaan Acara',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                const SizedBox(height: 2),
                                Text(
                                  DateHelper.formatDate(_sessionDate),
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Pengaturan Hari Rutinan
                    const Text(
                      'Pilih Hari Rutinan:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 8),

                    // Tombol Preset Cepat
                    Wrap(
                      spacing: 6,
                      children: [
                        ActionChip(
                          label: const Text('Senin - Kamis', style: TextStyle(fontSize: 11.5)),
                          onPressed: () => setState(() => _recurringDays = [1, 2, 3, 4]),
                        ),
                        ActionChip(
                          label: const Text('Senin - Jumat', style: TextStyle(fontSize: 11.5)),
                          onPressed: () => setState(() => _recurringDays = [1, 2, 3, 4, 5]),
                        ),
                        ActionChip(
                          label: const Text('Setiap Hari', style: TextStyle(fontSize: 11.5)),
                          onPressed: () => setState(() => _recurringDays = [1, 2, 3, 4, 5, 6, 7]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Pilihan Hari Mandiri (1=Senin s/d 7=Minggu)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildDayToggleChip(1, 'Senin'),
                        _buildDayToggleChip(2, 'Selasa'),
                        _buildDayToggleChip(3, 'Rabu'),
                        _buildDayToggleChip(4, 'Kamis'),
                        _buildDayToggleChip(5, 'Jumat'),
                        _buildDayToggleChip(6, 'Sabtu'),
                        _buildDayToggleChip(7, 'Minggu'),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Pengaturan Jam Acara
              _buildSectionCard(
                title: 'Waktu Pelaksanaan',
                children: [
                  _buildTimePickerRow('Jam Mulai Kegiatan', _startTime, (t) => _startTime = t),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildTimePickerRow('Jam Selesai Kegiatan', _endTime, (t) => _endTime = t),
                ],
              ),
              const SizedBox(height: 16),

              // Rentang Check-In
              _buildSectionCard(
                title: 'Rentang Waktu Check-In (Absen Masuk)',
                children: [
                  _buildTimePickerRow('Check-In Dibuka', _checkInOpens, (t) => _checkInOpens = t),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildTimePickerRow('Batas Tepat Waktu', _checkInOnTimeUntil, (t) => _checkInOnTimeUntil = t,
                      isHighlight: true),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildTimePickerRow('Check-In Ditutup', _checkInCloses, (t) => _checkInCloses = t),
                ],
              ),
              const SizedBox(height: 16),

              // Rentang Check-Out
              _buildSectionCard(
                title: 'Rentang Waktu Check-Out (Absen Keluar)',
                children: [
                  _buildTimePickerRow('Check-Out Dibuka', _checkOutOpens, (t) => _checkOutOpens = t),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildTimePickerRow('Target Waktu Check-Out', _checkOutDue, (t) => _checkOutDue = t),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildTimePickerRow('Check-Out Ditutup', _checkOutCloses, (t) => _checkOutCloses = t),
                ],
              ),
              const SizedBox(height: 16),

              // Status Publikasi
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
                      DropdownMenuItem(
                        value: 'published',
                        child: Text('Dipublikasikan (Dapat dilihat peserta)',
                            overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'draft',
                        child: Text('Draft (Hanya terlihat oleh admin)',
                            overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text('Selesai'),
                      ),
                      DropdownMenuItem(
                        value: 'cancelled',
                        child: Text('Dibatalkan'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _status = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tombol Simpan Sesi
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

  Widget _buildDayToggleChip(int dayIndex, String dayName) {
    final isSelected = _recurringDays.contains(dayIndex);
    return FilterChip(
      label: Text(dayName),
      selected: isSelected,
      onSelected: (val) {
        setState(() {
          if (val) {
            _recurringDays.add(dayIndex);
          } else {
            _recurringDays.remove(dayIndex);
          }
        });
      },
      selectedColor: const Color(0xFFEDE9FE),
      checkmarkColor: const Color(0xFF7C3AED),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF475569),
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

  Widget _buildTimePickerRow(String label, TimeOfDay time, ValueChanged<TimeOfDay> onPicked,
      {bool isHighlight = false}) {
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} WIB';

    return InkWell(
      onTap: () => _pickTime(time, onPicked),
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
                  Icon(Icons.access_time_rounded,
                      size: 14, color: isHighlight ? const Color(0xFFB45309) : const Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    timeStr,
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
