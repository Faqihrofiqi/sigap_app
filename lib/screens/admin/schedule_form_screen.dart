import 'package:flutter/material.dart';
import '../../core/supabase_client.dart';
import '../../models/schedule_model.dart';
import '../../models/user_model.dart';
import '../../models/classroom_model.dart';
import '../../widgets/professional_dialogs.dart';

class ScheduleFormScreen extends StatefulWidget {
  final ScheduleModel? schedule; // null = add, not null = edit
  
  const ScheduleFormScreen({super.key, this.schedule});
  
  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  List<UserModel> _teachers = [];
  List<ClassroomModel> _classrooms = [];
  
  UserModel? _selectedTeacher;
  ClassroomModel? _selectedClassroom;
  int _selectedDayOfWeek = 1; // 1 = Senin
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 0);
  final _subjectController = TextEditingController();
  final _lateToleranceController = TextEditingController(text: '10');
  bool _isActive = true;
  
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isLoadingData = true;
  
  final List<String> _days = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  
  @override
  void initState() {
    super.initState();
    _isEditMode = widget.schedule != null;
    _loadData();
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
      
      if (_isEditMode && widget.schedule != null) {
        final schedule = widget.schedule!;
        _selectedTeacher = _teachers.firstWhere(
          (t) => t.id == schedule.teacherId,
          orElse: () => _teachers.first,
        );
        _selectedClassroom = _classrooms.firstWhere(
          (c) => c.id == schedule.roomId,
          orElse: () => _classrooms.first,
        );
        _selectedDayOfWeek = schedule.dayOfWeek;
        
        // Parse time strings
        final startParts = schedule.startTime.split(':');
        _startTime = TimeOfDay(
          hour: int.parse(startParts[0]),
          minute: int.parse(startParts[1]),
        );
        
        final endParts = schedule.endTime.split(':');
        _endTime = TimeOfDay(
          hour: int.parse(endParts[0]),
          minute: int.parse(endParts[1]),
        );
        
        _subjectController.text = schedule.subject;
        _lateToleranceController.text = schedule.lateToleranceMinutes.toString();
        _isActive = schedule.isActive;
      }
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
  
  @override
  void dispose() {
    _subjectController.dispose();
    _lateToleranceController.dispose();
    super.dispose();
  }
  
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }
  
  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
    
    FocusScope.of(context).unfocus();
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final startTimeStr = '${_formatTime(_startTime)}:00';
      final endTimeStr = '${_formatTime(_endTime)}:00';
      
      final lateTolerance = int.tryParse(_lateToleranceController.text) ?? 10;
      
      if (_isEditMode) {
        // Update existing schedule
        await SupabaseService.updateSchedule(
          id: widget.schedule!.id,
          teacherId: _selectedTeacher!.id,
          roomId: _selectedClassroom!.id,
          dayOfWeek: _selectedDayOfWeek,
          startTime: startTimeStr,
          endTime: endTimeStr,
          subject: _subjectController.text.trim(),
          lateToleranceMinutes: lateTolerance,
          isActive: _isActive,
        );
        
        if (mounted) {
          ProfessionalDialogs.showProfessionalSnackBar(
            context: context,
            message: 'Jadwal berhasil diperbarui',
            type: SnackBarType.success,
          );
          Navigator.pop(context, true);
        }
      } else {
        // Create new schedule
        await SupabaseService.createSchedule(
          teacherId: _selectedTeacher!.id,
          roomId: _selectedClassroom!.id,
          dayOfWeek: _selectedDayOfWeek,
          startTime: startTimeStr,
          endTime: endTimeStr,
          subject: _subjectController.text.trim(),
          lateToleranceMinutes: lateTolerance,
          isActive: _isActive,
        );
        
        if (mounted) {
          ProfessionalDialogs.showProfessionalSnackBar(
            context: context,
            message: 'Jadwal baru berhasil ditambahkan',
            type: SnackBarType.success,
          );
          Navigator.pop(context, true);
        }
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
        title: Text(_isEditMode ? 'Edit Jadwal' : 'Tambah Jadwal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              
              // Day of Week Dropdown
              DropdownButtonFormField<int>(
                value: _selectedDayOfWeek,
                decoration: const InputDecoration(
                  labelText: 'Hari *',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                items: List.generate(7, (index) {
                  final day = index + 1;
                  return DropdownMenuItem(
                    value: day,
                    child: Text(_days[day]),
                  );
                }),
                onChanged: (value) {
                  setState(() {
                    _selectedDayOfWeek = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Start Time
              InkWell(
                onTap: () => _selectTime(context, true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Jam Mulai *',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(_formatTime(_startTime)),
                ),
              ),
              const SizedBox(height: 16),
              
              // End Time
              InkWell(
                onTap: () => _selectTime(context, false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Jam Selesai *',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(_formatTime(_endTime)),
                ),
              ),
              const SizedBox(height: 16),
              
              // Subject
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Mata Pelajaran *',
                  prefixIcon: Icon(Icons.book_outlined),
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
                controller: _lateToleranceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Toleransi Keterlambatan (menit) *',
                  prefixIcon: Icon(Icons.timer_outlined),
                  helperText: 'Waktu maksimal setelah jam mulai untuk tidak dihitung terlambat (default: 10 menit)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Toleransi keterlambatan wajib diisi';
                  }
                  final minutes = int.tryParse(value);
                  if (minutes == null || minutes < 0) {
                    return 'Masukkan angka yang valid (minimal 0)';
                  }
                  return null;
                },
              ),
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
              const SizedBox(height: 32),
              
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
                    : Text(
                        _isEditMode ? 'Simpan Perubahan' : 'Tambah Jadwal',
                        style: const TextStyle(
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
}

