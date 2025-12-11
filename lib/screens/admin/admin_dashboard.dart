import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/supabase_client.dart';
import '../../core/app_theme.dart';
import '../../core/session_manager.dart';
import '../../models/attendance_model.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/modern_stat_card.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../widgets/server_time_display.dart';
import '../../widgets/professional_dialogs.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import '../auth/change_password_screen.dart';
import 'manage_teachers_screen.dart';
import 'manage_classrooms_screen.dart';
import 'manage_schedules_screen.dart';
import 'reports_screen.dart';
import 'analytics_screen.dart';
import 'payroll_screen.dart';
import 'admin_dashboard_modern.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic> _stats = {};
  List<AttendanceModel> _recentAttendance = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Initialize session manager
    SessionManager.initialize(context);
  }
  
  @override
  void dispose() {
    SessionManager.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    // Kita tidak set _isLoading = true di sini jika sedang refresh (optional),
    // tapi untuk inisialisasi awal, ini perlu.
    try {
      // Load stats & attendance secara paralel agar lebih cepat
      // Gunakan cache untuk mengurangi request ke Supabase
      final results = await Future.wait([
        SupabaseService.getTodayAttendanceStats(useCache: !forceRefresh),
        SupabaseService.getAttendanceHistory(
          startDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        
        final allAttendance = results[1] as List<dynamic>;
        _recentAttendance = allAttendance
            .take(10) // Ambil 10 data terakhir saja
            .map((json) => AttendanceModel.fromJson(json))
            .toList();
      });
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
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Tampilkan loading dialog kecil saat proses logout
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await SupabaseService.signOut();
        
        if (!mounted) return;
        // Tutup dialog loading
        Navigator.pop(context); 
        
        // Pindah ke Login Screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Tutup dialog loading jika error
        ProfessionalDialogs.showProfessionalSnackBar(
          context: context,
          message: 'Gagal logout: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        centerTitle: false, // Terlihat lebih modern di kiri (default Android)
        elevation: 0,
        actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : () => _loadData(forceRefresh: true),
              tooltip: 'Refresh Data',
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'change_password') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              } else if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'change_password',
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Ubah Password'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ResponsiveWrapper(
                mobile: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    // --- Server Time Display ---
                    ModernCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ServerTimeDisplay(showFullInfo: true),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // --- Stats Cards ---
                    _buildStatsCards(),
                    const SizedBox(height: 20),

                    // --- Quick Actions ---
                    _buildQuickActions(),
                    const SizedBox(height: 20),

                    // --- Recent Attendance ---
                    _buildRecentAttendance(),
                    const SizedBox(height: 20), // Extra space di bawah
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildStatsCards() {
    final total = _stats['total_teachers'] as int? ?? 0;
    final present = _stats['present'] as int? ?? 0;
    final absent = _stats['absent'] as int? ?? 0;
    
    // Mencegah pembagian dengan nol (Division by Zero)
    final presentPercentage = total > 0 ? (present / total * 100) : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Guru',
                total.toString(),
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Hadir',
                present.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Belum Hadir',
                absent.toString(),
                Icons.cancel,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Persentase',
                '${presentPercentage.toStringAsFixed(1)}%',
                Icons.pie_chart,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return ModernCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16), // Padding internal card
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color, // Menggunakan warna tema card
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.grid_view_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Menu Manajemen',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = AppTheme.isMobile(context);
              final isTablet = AppTheme.isTablet(context);
              final crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 4);
              
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isMobile ? 2.2 : 2.5,
                children: [
                  _buildActionButton(
                    'Data Guru',
                    Icons.person_outline,
                    Colors.blue,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageTeachersScreen())),
                  ),
                  _buildActionButton(
                    'Ruangan',
                    Icons.meeting_room_outlined,
                    Colors.green,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageClassroomsScreen())),
                  ),
                  _buildActionButton(
                    'Jadwal',
                    Icons.calendar_month_outlined,
                    Colors.orange,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageSchedulesScreen())),
                  ),
                  _buildActionButton(
                    'Laporan',
                    Icons.analytics_outlined,
                    Colors.purple,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
                  ),
                  _buildActionButton(
                    'Analytics',
                    Icons.bar_chart,
                    Colors.teal,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
                  ),
                  _buildActionButton(
                    'Penggajian',
                    Icons.account_balance_wallet,
                    Colors.amber,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PayrollScreen())),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentAttendance() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Aktivitas Terkini',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportsScreen()),
                ),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_recentAttendance.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada data absensi',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentAttendance.length,
              itemBuilder: (context, index) {
                return _buildAttendanceItem(_recentAttendance[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem(AttendanceModel attendance) {
    // Default values if data is null
    final teacherName = attendance.teacher?.fullName ?? 'Guru Tidak Dikenal';
    final className = attendance.classroom?.name ?? '-';
    final timeStr = DateFormat('HH:mm').format(attendance.scanTime);
    final dateStr = DateFormat('dd MMM').format(attendance.scanTime);
    
    // Status color
    final isLate = !attendance.isOnTime; // Asumsi di model ada isOnTime
    final statusColor = isLate ? Colors.orange : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLate ? Icons.timer_off_outlined : Icons.check_circle_outline,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacherName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.room, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      className,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isLate ? 'Terlambat' : 'Tepat Waktu',
                  style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}