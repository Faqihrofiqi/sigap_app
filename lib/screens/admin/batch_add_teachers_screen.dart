import 'package:flutter/material.dart';
import '../../core/supabase_client.dart';

class BatchAddTeachersScreen extends StatefulWidget {
  const BatchAddTeachersScreen({super.key});
  
  @override
  State<BatchAddTeachersScreen> createState() => _BatchAddTeachersScreenState();
}

class _TeacherRow {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController nipController;
  final TextEditingController fullNameController;
  final TextEditingController baseSalaryController;
  final TextEditingController hourlyRateController;
  final TextEditingController presenceRateController;
  bool isExpanded;
  
  _TeacherRow({
    required this.emailController,
    required this.passwordController,
    required this.nipController,
    required this.fullNameController,
    required this.baseSalaryController,
    required this.hourlyRateController,
    required this.presenceRateController,
    this.isExpanded = true,
  });
  
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nipController.dispose();
    fullNameController.dispose();
    baseSalaryController.dispose();
    hourlyRateController.dispose();
    presenceRateController.dispose();
  }
}

class _BatchAddTeachersScreenState extends State<BatchAddTeachersScreen> {
  final List<_TeacherRow> _teacherRows = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    // Add initial row
    _addRow();
  }
  
  @override
  void dispose() {
    for (var row in _teacherRows) {
      row.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }
  
  void _addRow() {
    setState(() {
      _teacherRows.add(_TeacherRow(
        emailController: TextEditingController(),
        passwordController: TextEditingController(),
        nipController: TextEditingController(),
        fullNameController: TextEditingController(),
        baseSalaryController: TextEditingController(),
        hourlyRateController: TextEditingController(),
        presenceRateController: TextEditingController(),
      ));
    });
    
    // Scroll to bottom after adding row
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void _removeRow(int index) {
    if (_teacherRows.length > 1) {
      setState(() {
        _teacherRows[index].dispose();
        _teacherRows.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal harus ada 1 baris data'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
  
  bool _validateRow(_TeacherRow row) {
    if (row.emailController.text.trim().isEmpty) return false;
    if (row.passwordController.text.trim().isEmpty) return false;
    if (row.nipController.text.trim().isEmpty) return false;
    if (row.fullNameController.text.trim().isEmpty) return false;
    if (!row.emailController.text.contains('@')) return false;
    if (row.passwordController.text.length < 6) return false;
    return true;
  }
  
  Future<void> _handleSubmit() async {
    // Validate all rows
    final validRows = <_TeacherRow>[];
    final invalidIndices = <int>[];
    
    for (int i = 0; i < _teacherRows.length; i++) {
      final row = _teacherRows[i];
      if (_validateRow(row)) {
        validRows.add(row);
      } else {
        invalidIndices.add(i + 1);
      }
    }
    
    if (validRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data yang valid. Pastikan semua field wajib terisi dengan benar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (invalidIndices.isNotEmpty) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Data Tidak Valid'),
          content: Text(
            'Baris ${invalidIndices.join(", ")} tidak valid dan akan dilewati.\n\n'
            'Lanjutkan dengan ${validRows.length} data yang valid?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      );
      
      if (shouldContinue != true) return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final teachersData = validRows.map((row) => <String, dynamic>{
        'email': row.emailController.text.trim(),
        'password': row.passwordController.text,
        'nip': row.nipController.text.trim(),
        'full_name': row.fullNameController.text.trim(),
        'base_salary': int.tryParse(row.baseSalaryController.text) ?? 0,
        'hourly_rate': int.tryParse(row.hourlyRateController.text) ?? 0,
        'presence_rate': int.tryParse(row.presenceRateController.text) ?? 0,
      }).toList();
      
      final result = await SupabaseService.createTeachersBatch(teachersData);
      
      if (mounted) {
        final successCount = result['success_count'] as int;
        final failCount = result['fail_count'] as int;
        final errors = result['errors'] as List<Map<String, dynamic>>;
        
        String message = 'Berhasil menambahkan $successCount guru';
        if (failCount > 0) {
          message += '\nGagal: $failCount guru';
        }
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(failCount > 0 ? 'Hasil Batch Add' : 'Berhasil'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  if (errors.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Detail Error:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...errors.map((error) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${error['email']}: ${error['error']}',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    )),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, successCount > 0);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Show detailed error in dialog for better readability
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error Batch Add'),
            content: SingleChildScrollView(
              child: Text(
                e.toString().replaceAll('\n', '\n\n'),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
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
        title: const Text('Tambah Guru Batch'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addRow,
              tooltip: 'Tambah Baris',
            ),
        ],
      ),
      body: Column(
        children: [
          // Info Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Panduan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Email dan password wajib diisi untuk setiap guru\n'
                  '• NIP dan Nama Lengkap wajib diisi\n'
                  '• Gaji dan insentif bersifat opsional\n'
                  '• Password minimal 6 karakter\n'
                  '• Gunakan tombol + untuk menambah baris\n'
                  '• Baris yang tidak valid akan dilewati',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
          ),
          
          // Table Header (hidden on small screens)
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return const SizedBox.shrink();
              }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 50, child: Text('No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(flex: 2, child: Text('Email *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(flex: 2, child: Text('Password *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(flex: 2, child: Text('NIP *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(flex: 2, child: Text('Nama *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(flex: 1, child: Text('Gaji', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(flex: 1, child: Text('Insentif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    SizedBox(width: 50),
                  ],
                ),
              );
            },
          ),
          
          // Table Body
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _teacherRows.length,
              itemBuilder: (context, index) {
                final row = _teacherRows[index];
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 600;
                    
                    if (isSmallScreen) {
                      // Mobile layout - vertical stack
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Guru #${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _removeRow(index),
                                    tooltip: 'Hapus Baris',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: row.emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email *',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: row.passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Password *',
                                  prefixIcon: Icon(Icons.lock_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: row.nipController,
                                decoration: const InputDecoration(
                                  labelText: 'NIP *',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: row.fullNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nama Lengkap *',
                                  prefixIcon: Icon(Icons.person_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: row.baseSalaryController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Gaji Pokok (Opsional)',
                                  prefixIcon: Icon(Icons.attach_money),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: row.hourlyRateController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Insentif per Jam (Opsional)',
                                  prefixIcon: Icon(Icons.access_time),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: row.presenceRateController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Insentif Kehadiran (Opsional)',
                                  prefixIcon: Icon(Icons.check_circle_outline),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      // Desktop layout - horizontal table
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: row.emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: row.passwordController,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Password',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: row.nipController,
                                      decoration: const InputDecoration(
                                        labelText: 'NIP',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: row.fullNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Nama',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: TextField(
                                      controller: row.baseSalaryController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Gaji',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: TextField(
                                      controller: row.hourlyRateController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Insentif',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _removeRow(index),
                                    tooltip: 'Hapus Baris',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const SizedBox(width: 50),
                                  Expanded(
                                    child: TextField(
                                      controller: row.presenceRateController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Insentif Kehadiran',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
          
          // Submit Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
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
                          'Tambah ${_teacherRows.length} Guru',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

