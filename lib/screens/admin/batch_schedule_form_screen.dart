import 'package:flutter/material.dart';
import '../../core/supabase_client.dart';
import '../../models/user_model.dart';
import '../../models/classroom_model.dart';
import '../../widgets/professional_dialogs.dart';

// Model untuk time slot
class TimeSlot {
  TimeOfDay startTime;
  TimeOfDay endTime;
  final TextEditingController subjectController;
  final TextEditingController lateToleranceController;
  
  TimeSlot({
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? subject,
    int? lateTolerance,
  })  : startTime = startTime ?? const TimeOfDay(hour: 8, minute: 0),
        endTime = endTime ?? const TimeOfDay(hour: 9, minute: 0),
        subjectController = TextEditingController(text: subject ?? ''),
        lateToleranceController = TextEditingController(text: (lateTolerance ?? 10).toString());
  
  void dispose() {
    subjectController.dispose();
    lateToleranceController.dispose();
  }
}

class BatchScheduleFormScreen extends StatefulWidget {
  const BatchScheduleFormScreen({super.key});
  
  @override
  State<BatchScheduleFormScreen> createState() => _BatchScheduleFormScreenState();
}

class _BatchScheduleFormScreenState extends State<BatchScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  List<UserModel> _teachers = [];
  List<ClassroomModel> _classrooms = [];
  
  UserModel? _selectedTeacher;
  ClassroomModel? _selectedClassroom;
  final Set<int> _selectedDays = {}; // Set untuk multiple selection
  List<TimeSlot> _timeSlots = [];
  bool _isActive = true;
  
  bool _isLoading = false;
  bool _isLoadingData = true;
  
  final List<String> _days = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  
  @override
  void initState() {
    super.initState();
    // Tambahkan satu time slot default
    _timeSlots.add(TimeSlot());
    _loadData();
  }
  
  @override
  void dispose() {
    for (var slot in _timeSlots) {
      slot.dispose();
    }
    super.dispose();
  }
  
  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        SupabaseService.getAllTeachers(),
        SupabaseService.getAllClassrooms(),
      ]);
      
      _teachers = (results[0] as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
      
      _classrooms = (results[1] as List)
          .map((json) => ClassroomModel.fromJson(json))
          .toList();
    } catch (e) {
      if (mounted) {
        ProfessionalDialogs.showProfessionalSnackBar(
          context: context,
          message: 'Gagal memuat data: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }
  
  Future<void> _selectTime(BuildContext context, TimeSlot slot, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? slot.startTime : slot.endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          slot.startTime = picked;
        } else {
          slot.endTime = picked;
        }
      });
    }
  }
  
  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
  
  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }
  
  void _addTimeSlot() {
    setState(() {
      // Set start time dari slot terakhir + 1 jam
      final lastSlot = _timeSlots.isNotEmpty ? _timeSlots.last : null;
      final nextHour = lastSlot != null 
          ? (lastSlot.endTime.hour + (lastSlot.endTime.minute > 0 ? 1 : 0))
          : 8;
      
      _timeSlots.add(TimeSlot(
        startTime: TimeOfDay(hour: nextHour.clamp(0, 23), minute: 0),
        endTime: TimeOfDay(hour: (nextHour + 1).clamp(0, 23), minute: 0),
      ));
    });
  }
  
  void _removeTimeSlot(int index) {
    if (_timeSlots.length > 1) {
      setState(() {
        _timeSlots[index].dispose();
        _timeSlots.removeAt(index);
      });
    } else {
      ProfessionalDialogs.showProfessionalSnackBar(
        context: context,
        message: 'Minimal harus ada satu waktu jadwal',
        type: SnackBarType.warning,
      );
    }
  }
  
  bool _validateTimeSlots() {
    for (int i = 0; i < _timeSlots.length; i++) {
      final slot = _timeSlots[i];
      
      // Validasi subject
      if (slot.subjectController.text.trim().isEmpty) {
        ProfessionalDialogs.showProfessionalSnackBar(
          context: context,
          message: 'Mata pelajaran pada waktu ${i + 1} wajib diisi',
          type: SnackBarType.warning,
        );
        return false;
      }
      
      // Validasi waktu
      final startMinutes = slot.startTime.hour * 60 + slot.startTime.minute;
      final endMinutes = slot.endTime.hour * 60 + slot.endTime.minute;
      
      if (endMinutes <= startMinutes) {
        ProfessionalDialogs.showProfessionalSnackBar(
          context: context,
          message: 'Jam selesai harus lebih besar dari jam mulai pada waktu ${i + 1}',
          type: SnackBarType.warning,
        );
        return false;
      }
      
      // Validasi late tolerance
      final lateTolerance = int.tryParse(slot.lateToleranceController.text);
      if (lateTolerance == null || lateTolerance < 0) {
        ProfessionalDialogs.showProfessionalSnackBar(
          context: context,
          message: 'Toleransi keterlambatan pada waktu ${i + 1} tidak valid',
          type: SnackBarType.warning,
        );
        return false;
      }
    }
    return true;
  }
  
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedTeacher == null || _selectedClassroom == null) {
      ProfessionalDialogs.showProfessionalSnackBar(
        context: context,
        message: 'Pilih guru dan ruangan terlebih dahulu',
        type: SnackBarType.warning,
      );
      return;
    }
    
    if (_selectedDays.isEmpty) {
      ProfessionalDialogs.showProfessionalSnackBar(
        context: context,
        message: 'Pilih minimal satu hari',
        type: SnackBarType.warning,
      );
      return;
    }
    
    if (!_validateTimeSlots()) {
      return;
    }
    
    FocusScope.of(context).unfocus();
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Prepare all schedule data
      final List<Map<String, dynamic>> allSchedules = [];
      
      for (final day in _selectedDays) {
        for (final slot in _timeSlots) {
          final startTimeStr = '${_formatTime(slot.startTime)}:00';
          final endTimeStr = '${_formatTime(slot.endTime)}:00';
          final lateTolerance = int.tryParse(slot.lateToleranceController.text) ?? 10;
          
          allSchedules.add({
            'teacher_id': _selectedTeacher!.id,
            'room_id': _selectedClassroom!.id,
            'day_of_week': day,
            'start_time': startTimeStr,
            'end_time': endTimeStr,
            'subject': slot.subjectController.text.trim(),
            'late_tolerance_minutes': lateTolerance,
            'is_active': _isActive,
          });
        }
      }
      
      // Validasi semua jadwal sebelum insert
      final List<String> conflicts = [];
      final List<String> duplicates = [];
      final dayNames = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      
      for (final schedule in allSchedules) {
        final day = schedule['day_of_week'] as int;
        final startTime = schedule['start_time'] as String;
        final endTime = schedule['end_time'] as String;
        final subject = schedule['subject'] as String;
        
        // Check conflict
        final hasConflict = await SupabaseService.hasScheduleConflict(
          teacherId: _selectedTeacher!.id,
          roomId: _selectedClassroom!.id,
          dayOfWeek: day,
          startTime: startTime,
          endTime: endTime,
        );
        
        if (hasConflict) {
          conflicts.add(dayNames[day]);
        }
        
        // Check duplicate
        final isDuplicate = await SupabaseService.hasDuplicateSchedule(
          teacherId: _selectedTeacher!.id,
          roomId: _selectedClassroom!.id,
          dayOfWeek: day,
          startTime: startTime,
          endTime: endTime,
          subject: subject,
        );
        
        if (isDuplicate) {
          duplicates.add(dayNames[day]);
        }
      }
      
      // Throw error jika ada conflict atau duplicate
      if (conflicts.isNotEmpty) {
        throw Exception(
          'Jadwal bertabrakan pada hari: ${conflicts.join(', ')}. Silakan periksa kembali.'
        );
      }
      
      if (duplicates.isNotEmpty) {
        throw Exception(
          'Jadwal duplikat ditemukan pada hari: ${duplicates.join(', ')}. Silakan periksa kembali.'
        );
      }
      
      // Insert all schedules at once
      final response = await SupabaseService.client
          .from('schedules')
          .insert(allSchedules)
          .select();
      
      final results = (response as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
      
      // Clear cache by calling getAllSchedules with force refresh
      await SupabaseService.getAllSchedules(useCache: false);
      
      if (mounted) {
        ProfessionalDialogs.showProfessionalSnackBar(
          context: context,
          message: '${results.length} jadwal berhasil ditambahkan',
          type: SnackBarType.success,
          duration: const Duration(seconds: 3),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ProfessionalDialogs.showProfessionalSnackBar(
          context: context,
          message: 'Terjadi kesalahan: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  
  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(
        appBar: null,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Jadwal Batch'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tambahkan beberapa waktu jadwal sekaligus untuk hari yang dipilih. Anda bisa menambah atau menghapus waktu jadwal sesuai kebutuhan.',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Teacher Dropdown
              DropdownButtonFormField<UserModel>(
                value: _selectedTeacher,
                decoration: const InputDecoration(
                  labelText: 'Guru *',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
                items: _teachers.map((teacher) {
                  return DropdownMenuItem(
                    value: teacher,
                    child: Text('${teacher.fullName} (${teacher.nip})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTeacher = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Pilih guru terlebih dahulu';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Classroom Dropdown
              DropdownButtonFormField<ClassroomModel>(
                value: _selectedClassroom,
                decoration: const InputDecoration(
                  labelText: 'Ruangan *',
                  prefixIcon: Icon(Icons.room_outlined),
                ),
                items: _classrooms.map((classroom) {
                  return DropdownMenuItem(
                    value: classroom,
                    child: Text(classroom.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedClassroom = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Pilih ruangan terlebih dahulu';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Days Selection
              const Text(
                'Pilih Hari *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (index) {
                  final day = index + 1;
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(_days[day]),
                    selected: isSelected,
                    onSelected: (_) => _toggleDay(day),
                    selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              
              // Time Slots Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Waktu Jadwal *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addTimeSlot,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah Waktu'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // List of Time Slots
              ...List.generate(_timeSlots.length, (index) {
                final slot = _timeSlots[index];
                return _buildTimeSlotCard(slot, index);
              }),
              
              const SizedBox(height: 16),
              
              // Is Active Switch
              SwitchListTile(
                title: const Text('Aktif'),
                subtitle: const Text('Jadwal akan muncul di aplikasi guru'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              
              // Preview Card
              if (_selectedDays.isNotEmpty && _timeSlots.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preview:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Akan dibuat ${_selectedDays.length * _timeSlots.length} jadwal:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedDays.length} hari × ${_timeSlots.length} waktu = ${_selectedDays.length * _timeSlots.length} jadwal',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              
              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Tambah Jadwal Batch',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTimeSlotCard(TimeSlot slot, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan nomor dan tombol hapus
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Waktu Jadwal',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (_timeSlots.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeTimeSlot(index),
                  tooltip: 'Hapus waktu ini',
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Time Picker Row
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(context, slot, true),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Jam Mulai *',
                      prefixIcon: Icon(Icons.access_time, size: 20),
                      isDense: true,
                    ),
                    child: Text(_formatTime(slot.startTime)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(context, slot, false),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Jam Selesai *',
                      prefixIcon: Icon(Icons.access_time, size: 20),
                      isDense: true,
                    ),
                    child: Text(_formatTime(slot.endTime)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Subject
          TextFormField(
            controller: slot.subjectController,
            decoration: const InputDecoration(
              labelText: 'Mata Pelajaran *',
              prefixIcon: Icon(Icons.book_outlined),
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Mata pelajaran wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Late Tolerance
          TextFormField(
            controller: slot.lateToleranceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Toleransi Keterlambatan (menit) *',
              prefixIcon: Icon(Icons.timer_outlined),
              helperText: 'Default: 10 menit',
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Toleransi wajib diisi';
              }
              final minutes = int.tryParse(value);
              if (minutes == null || minutes < 0) {
                return 'Masukkan angka yang valid';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
