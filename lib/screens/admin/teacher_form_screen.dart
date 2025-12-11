import 'package:flutter/material.dart';
import '../../core/supabase_client.dart';
import '../../models/user_model.dart';
import 'package:intl/intl.dart';

class TeacherFormScreen extends StatefulWidget {
  final UserModel? teacher; // null = add, not null = edit
  
  const TeacherFormScreen({super.key, this.teacher});
  
  @override
  State<TeacherFormScreen> createState() => _TeacherFormScreenState();
}

class _TeacherFormScreenState extends State<TeacherFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userIdController = TextEditingController();
  final _nipController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _baseSalaryController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _presenceRateController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isEditMode = false;
  bool _useExistingUser = false; // Default: create new user via Edge Function
  
  @override
  void initState() {
    super.initState();
    _isEditMode = widget.teacher != null;
    
    if (_isEditMode) {
      final teacher = widget.teacher!;
      _nipController.text = teacher.nip;
      _fullNameController.text = teacher.fullName;
      _baseSalaryController.text = teacher.baseSalary.toString();
      _hourlyRateController.text = teacher.hourlyRate.toString();
      _presenceRateController.text = teacher.presenceRate.toString();
    }
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _userIdController.dispose();
    _nipController.dispose();
    _fullNameController.dispose();
    _baseSalaryController.dispose();
    _hourlyRateController.dispose();
    _presenceRateController.dispose();
    super.dispose();
  }
  
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    FocusScope.of(context).unfocus();
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (_isEditMode) {
        // Update existing teacher
        await SupabaseService.updateTeacher(
          id: widget.teacher!.id,
          nip: _nipController.text.trim(),
          fullName: _fullNameController.text.trim(),
          baseSalary: int.tryParse(_baseSalaryController.text) ?? 0,
          hourlyRate: int.tryParse(_hourlyRateController.text) ?? 0,
          presenceRate: int.tryParse(_presenceRateController.text) ?? 0,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data guru berhasil diperbarui'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        // Create new teacher
        if (_useExistingUser) {
          // Create profile for existing user
          if (_userIdController.text.trim().isEmpty) {
            throw Exception('User ID wajib diisi. Dapatkan dari Supabase Dashboard > Authentication > Users');
          }
          
          await SupabaseService.createTeacherProfile(
            userId: _userIdController.text.trim(),
            nip: _nipController.text.trim(),
            fullName: _fullNameController.text.trim(),
            baseSalary: int.tryParse(_baseSalaryController.text) ?? 0,
            hourlyRate: int.tryParse(_hourlyRateController.text) ?? 0,
            presenceRate: int.tryParse(_presenceRateController.text) ?? 0,
          );
        } else {
          // Try to create user + profile (will fail without service role)
          if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
            throw Exception('Email dan password wajib diisi');
          }
          
          await SupabaseService.createTeacher(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            nip: _nipController.text.trim(),
            fullName: _fullNameController.text.trim(),
            baseSalary: int.tryParse(_baseSalaryController.text) ?? 0,
            hourlyRate: int.tryParse(_hourlyRateController.text) ?? 0,
            presenceRate: int.tryParse(_presenceRateController.text) ?? 0,
          );
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Guru baru berhasil ditambahkan'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Guru' : 'Tambah Guru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mode selection (only for new teacher)
              if (!_isEditMode) ...[
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Cara Menambah Guru',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        RadioListTile<bool>(
                          title: const Text('Buat User Baru (Recommended)'),
                          subtitle: const Text('Menggunakan Edge Function - otomatis membuat user + profile'),
                          value: false,
                          groupValue: _useExistingUser,
                          onChanged: (value) {
                            setState(() {
                              _useExistingUser = value!;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<bool>(
                          title: const Text('Gunakan User yang Sudah Ada'),
                          subtitle: const Text('User sudah dibuat di Supabase Dashboard'),
                          value: true,
                          groupValue: _useExistingUser,
                          onChanged: (value) {
                            setState(() {
                              _useExistingUser = value!;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // User ID (for existing user)
                if (_useExistingUser) ...[
                  TextFormField(
                    controller: _userIdController,
                    decoration: const InputDecoration(
                      labelText: 'User ID (UUID) *',
                      prefixIcon: Icon(Icons.person_outlined),
                      helperText: 'Dapatkan dari Supabase Dashboard > Authentication > Users',
                      hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'User ID wajib diisi';
                      }
                      // Basic UUID format check
                      if (!RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(value.trim())) {
                        return 'Format User ID tidak valid (harus UUID)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Email (only for new user creation)
                if (!_useExistingUser) ...[
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email wajib diisi';
                      }
                      if (!value.contains('@')) {
                        return 'Email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Password (only for new user creation)
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password *',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password wajib diisi';
                      }
                      if (value.length < 6) {
                        return 'Password minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ],
              
              // NIP
              TextFormField(
                controller: _nipController,
                decoration: const InputDecoration(
                  labelText: 'NIP *',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'NIP wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Full Name
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap *',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama lengkap wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Base Salary
              TextFormField(
                controller: _baseSalaryController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Gaji Pokok (Rp)',
                  prefixIcon: Icon(Icons.attach_money),
                  helperText: 'Opsional',
                ),
              ),
              const SizedBox(height: 16),
              
              // Hourly Rate
              TextFormField(
                controller: _hourlyRateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Insentif per Jam (Rp)',
                  prefixIcon: Icon(Icons.access_time),
                  helperText: 'Opsional',
                ),
              ),
              const SizedBox(height: 16),
              
              // Presence Rate
              TextFormField(
                controller: _presenceRateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Insentif Kehadiran (Rp)',
                  prefixIcon: Icon(Icons.check_circle_outline),
                  helperText: 'Opsional',
                ),
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
                        _isEditMode ? 'Simpan Perubahan' : 'Tambah Guru',
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

