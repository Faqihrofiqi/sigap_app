import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../core/supabase_client.dart';
import '../../core/app_theme.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/professional_dialogs.dart';
import '../../services/export_service.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  List<UserModel> _teachers = [];
  Map<String, PayrollData> _payrollData = {};
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();
  double _baseSalary = 5000000.0; // Default gaji pokok
  double _lateDeduction = 50000.0; // Potongan per keterlambatan
  double _attendanceBonus = 100000.0; // Bonus kehadiran penuh

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    _loadPayrollData();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('id_ID', null);
  }

  Future<void> _loadPayrollData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all teachers
      final teachersData = await SupabaseService.getAllTeachers();
      _teachers = teachersData.map((json) => UserModel.fromJson(json)).toList();

      // Calculate payroll for each teacher
      final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

      _payrollData.clear();

      for (var teacher in _teachers) {
        final attendanceData = await SupabaseService.getAttendanceHistory(
          startDate: startDate,
          endDate: endDate,
          teacherId: teacher.id,
        );

        final attendances = attendanceData
            .map((json) => AttendanceModel.fromJson(json))
            .toList();

        // Calculate stats
        final totalDays = attendances.length;
        final lateCount = attendances.where((a) => a.isLate).length;
        final onTimeCount = attendances.where((a) => a.isOnTime).length;
        final totalLateMinutes = attendances
            .where((a) => a.lateMinutes != null)
            .fold(0, (sum, a) => sum + (a.lateMinutes ?? 0));

        // Calculate salary
        final lateDeductions = lateCount * _lateDeduction;
        final hasFullAttendance = totalDays >= 20; // Minimum 20 hari kerja
        final bonus = hasFullAttendance && lateCount == 0 ? _attendanceBonus : 0.0;
        final finalSalary = _baseSalary - lateDeductions + bonus;

        _payrollData[teacher.id] = PayrollData(
          teacher: teacher,
          totalDays: totalDays,
          onTimeCount: onTimeCount,
          lateCount: lateCount,
          totalLateMinutes: totalLateMinutes,
          baseSalary: _baseSalary,
          lateDeductions: lateDeductions,
          bonus: bonus,
          finalSalary: finalSalary,
        );
      }
    } catch (e) {
      if (mounted) {
        ProfessionalDialogs.showProfessionalSnackBar(
          context: context,
          message: 'Gagal memuat data penggajian: ${e.toString()}',
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

  Future<void> _selectMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Pilih Bulan',
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = picked;
      });
      _loadPayrollData();
    }
  }

  Future<void> _showSalarySettings() async {
    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (context) => SalarySettingsDialog(
        baseSalary: _baseSalary,
        lateDeduction: _lateDeduction,
        attendanceBonus: _attendanceBonus,
      ),
    );

    if (result != null) {
      setState(() {
        _baseSalary = result['baseSalary'] ?? _baseSalary;
        _lateDeduction = result['lateDeduction'] ?? _lateDeduction;
        _attendanceBonus = result['attendanceBonus'] ?? _attendanceBonus;
      });
      _loadPayrollData();
    }
  }

  Future<void> _exportPayroll() async {
    if (_payrollData.isEmpty) {
      ProfessionalDialogs.showInfoDialog(
        context: context,
        title: 'Tidak Ada Data',
        message: 'Tidak ada data penggajian untuk diexport.',
      );
      return;
    }

    // Convert to attendance list format for export
    final List<AttendanceModel> allAttendances = [];
    for (var payroll in _payrollData.values) {
      // Get attendances for this teacher
      final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
      
      final attendanceData = await SupabaseService.getAttendanceHistory(
        startDate: startDate,
        endDate: endDate,
        teacherId: payroll.teacher.id,
      );

      allAttendances.addAll(
        attendanceData.map((json) => AttendanceModel.fromJson(json)),
      );
    }

    await ExportService.exportToPDF(
      context: context,
      attendanceList: allAttendances,
      startDate: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
      endDate: DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penggajian'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSalarySettings,
            tooltip: 'Pengaturan Gaji',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportPayroll,
            tooltip: 'Export Laporan',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPayrollData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Month Selector
                    ModernCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.calendar_month,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Bulan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.edit_calendar,
                              color: AppTheme.primaryColor,
                            ),
                            onPressed: _selectMonth,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Summary
                    _buildSummary(),
                    const SizedBox(height: 20),

                    // Payroll List
                    ..._payrollData.values.map((payroll) => _buildPayrollCard(payroll)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummary() {
    final totalSalary = _payrollData.values
        .fold(0.0, (sum, payroll) => sum + payroll.finalSalary);
    final totalTeachers = _payrollData.length;
    final totalDeductions = _payrollData.values
        .fold(0.0, (sum, payroll) => sum + payroll.lateDeductions);
    final totalBonus = _payrollData.values
        .fold(0.0, (sum, payroll) => sum + payroll.bonus);

    return Row(
      children: [
        Expanded(
          child: ModernCard(
            child: Column(
              children: [
                Text(
                  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                      .format(totalSalary),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Total Gaji',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ModernCard(
            child: Column(
              children: [
                Text(
                  totalTeachers.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Guru',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ModernCard(
            child: Column(
              children: [
                Text(
                  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                      .format(totalDeductions),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Potongan',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayrollCard(PayrollData payroll) {
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  payroll.teacher.fullName[0].toUpperCase(),
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payroll.teacher.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      payroll.teacher.nip ?? '-',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                      .format(payroll.finalSalary),
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Hari Kerja', payroll.totalDays.toString()),
              _buildStatItem('Tepat Waktu', payroll.onTimeCount.toString()),
              _buildStatItem('Terlambat', payroll.lateCount.toString()),
            ],
          ),
          if (payroll.lateCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Keterlambatan: ${payroll.totalLateMinutes} menit',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '- ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(payroll.lateDeductions)}',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (payroll.bonus > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bonus Kehadiran Penuh',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '+ ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(payroll.bonus)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gaji Pokok',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                    .format(payroll.baseSalary),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class PayrollData {
  final UserModel teacher;
  final int totalDays;
  final int onTimeCount;
  final int lateCount;
  final int totalLateMinutes;
  final double baseSalary;
  final double lateDeductions;
  final double bonus;
  final double finalSalary;

  PayrollData({
    required this.teacher,
    required this.totalDays,
    required this.onTimeCount,
    required this.lateCount,
    required this.totalLateMinutes,
    required this.baseSalary,
    required this.lateDeductions,
    required this.bonus,
    required this.finalSalary,
  });
}

class SalarySettingsDialog extends StatefulWidget {
  final double baseSalary;
  final double lateDeduction;
  final double attendanceBonus;

  const SalarySettingsDialog({
    super.key,
    required this.baseSalary,
    required this.lateDeduction,
    required this.attendanceBonus,
  });

  @override
  State<SalarySettingsDialog> createState() => _SalarySettingsDialogState();
}

class _SalarySettingsDialogState extends State<SalarySettingsDialog> {
  late TextEditingController _baseSalaryController;
  late TextEditingController _lateDeductionController;
  late TextEditingController _attendanceBonusController;

  @override
  void initState() {
    super.initState();
    _baseSalaryController = TextEditingController(
      text: widget.baseSalary.toStringAsFixed(0),
    );
    _lateDeductionController = TextEditingController(
      text: widget.lateDeduction.toStringAsFixed(0),
    );
    _attendanceBonusController = TextEditingController(
      text: widget.attendanceBonus.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _baseSalaryController.dispose();
    _lateDeductionController.dispose();
    _attendanceBonusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pengaturan Gaji'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _baseSalaryController,
              decoration: const InputDecoration(
                labelText: 'Gaji Pokok',
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lateDeductionController,
              decoration: const InputDecoration(
                labelText: 'Potongan per Keterlambatan',
                prefixIcon: Icon(Icons.remove_circle_outline),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _attendanceBonusController,
              decoration: const InputDecoration(
                labelText: 'Bonus Kehadiran Penuh',
                prefixIcon: Icon(Icons.card_giftcard),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            final baseSalary = double.tryParse(_baseSalaryController.text) ?? widget.baseSalary;
            final lateDeduction = double.tryParse(_lateDeductionController.text) ?? widget.lateDeduction;
            final attendanceBonus = double.tryParse(_attendanceBonusController.text) ?? widget.attendanceBonus;

            Navigator.pop(context, {
              'baseSalary': baseSalary,
              'lateDeduction': lateDeduction,
              'attendanceBonus': attendanceBonus,
            });
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

