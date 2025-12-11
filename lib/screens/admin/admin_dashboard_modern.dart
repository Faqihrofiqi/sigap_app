import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/supabase_client.dart';
import '../../core/app_theme.dart';
import '../../core/session_manager.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/modern_stat_card.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/server_time_display.dart';
import '../../widgets/professional_dialogs.dart';
import '../auth/login_screen.dart';
import '../auth/change_password_screen.dart';
import 'manage_teachers_screen.dart';
import 'manage_classrooms_screen.dart';
import 'manage_schedules_screen.dart';
import 'reports_screen.dart';
import 'analytics_screen.dart';
import 'payroll_screen.dart';

class AdminDashboardModern extends StatefulWidget {
  const AdminDashboardModern({super.key});

  @override
  State<AdminDashboardModern> createState() => _AdminDashboardModernState();
}

class _AdminDashboardModernState extends State<AdminDashboardModern> {
  Map<String, dynamic> _stats = {};
  List<AttendanceModel> _recentAttendance = [];
  bool _isLoading = true;
  UserModel? _currentUser;
  int _selectedMenuIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadData();
    SessionManager.initialize(context);
  }

  @override
  void dispose() {
    SessionManager.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    try {
      final results = await Future.wait([
        SupabaseService.getUserProfile(),
        SupabaseService.getTodayAttendanceStats(useCache: !forceRefresh),
        SupabaseService.getAttendanceHistory(
          startDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ]);

      if (!mounted) return;

      setState(() {
        if (results[0] != null) {
          _currentUser = UserModel.fromJson(results[0] as Map<String, dynamic>);
        }
        _stats = results[1] as Map<String, dynamic>;
        final allAttendance = results[2] as List<dynamic>;
        _recentAttendance = allAttendance
            .take(10)
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

  void _handleMenuSelection(int index) {
    switch (index) {
      case 0: // Dashboard
        // Already here
        break;
      case 1: // Analytics
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
        );
        break;
      case 2: // Data Guru
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ManageTeachersScreen()),
        );
        break;
      case 3: // Ruangan
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ManageClassroomsScreen()),
        );
        break;
      case 4: // Jadwal
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ManageSchedulesScreen()),
        );
        break;
      case 5: // Laporan
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportsScreen()),
        );
        break;
      case 6: // Penggajian
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PayrollScreen()),
        );
        break;
      case 7: // Pengaturan
        // TODO: Settings screen
        break;
      case 8: // Logout
        _handleLogout();
        break;
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await ProfessionalDialogs.showConfirmDialog(
      context: context,
      title: 'Konfirmasi Logout',
      message: 'Apakah Anda yakin ingin keluar dari aplikasi?',
      confirmText: 'Logout',
      cancelText: 'Batal',
    );

    if (confirm == true) {
      try {
        await SupabaseService.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ProfessionalDialogs.showErrorDialog(
            context: context,
            title: 'Error',
            message: 'Gagal logout: ${e.toString()}',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      key: _scaffoldKey,
      appBar: isMobile
          ? AppBar(
              title: const Text('Dashboard'),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {},
                ),
              ],
            )
          : null,
      drawer: isMobile
          ? AdminSidebar(
              selectedIndex: _selectedMenuIndex,
              onItemSelected: (index) {
                Navigator.pop(context);
                setState(() {
                  _selectedMenuIndex = index;
                });
                _handleMenuSelection(index);
              },
              currentUser: _currentUser,
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    // Use LayoutBuilder to get accurate screen size, especially after reload
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use both MediaQuery and constraints for reliability
        final mediaWidth = MediaQuery.of(context).size.width;
        final constraintWidth = constraints.maxWidth;
        // Use the larger value to ensure we get the correct screen width
        final screenWidth = mediaWidth > constraintWidth ? mediaWidth : constraintWidth;
        // Ensure minimum width for web layout
        final isMobile = screenWidth < 768 || (constraintWidth < 768 && mediaWidth == 0);

        if (isMobile) {
          return _buildMobileLayout();
        }

        return _buildWebLayout();
      },
    );
  }

  Widget _buildWebLayout() {
    // Use MediaQuery to get actual screen width, not constraints
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.03; // 3% of screen width
    final spacing = screenWidth * 0.03;
    
    return Row(
      children: [
        AdminSidebar(
          selectedIndex: _selectedMenuIndex,
          onItemSelected: (index) {
            setState(() {
              _selectedMenuIndex = index;
            });
            _handleMenuSelection(index);
          },
          currentUser: _currentUser,
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFF8F9FA),
            child: RefreshIndicator(
              onRefresh: () => _loadData(forceRefresh: true),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildWebHeader(),
                    SizedBox(height: spacing),
                    _buildStatsGrid(),
                    SizedBox(height: spacing),
                    // Always use Row layout for web (since we're in _buildWebLayout)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildRecentAttendance(),
                        ),
                        SizedBox(width: spacing),
                        Expanded(
                          child: _buildQuickActions(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Dashboard /',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Search...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {},
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    _currentUser?.fullName[0].toUpperCase() ?? 'A',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
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
      ],
    );
  }

  Widget _buildStatsGrid() {
    final total = _stats['total_teachers'] as int? ?? 0;
    final present = _stats['present'] as int? ?? 0;
    final absent = _stats['absent'] as int? ?? 0;
    final presentPercentage = total > 0 ? (present / total * 100) : 0.0;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    
    // Responsive grid columns
    final crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 4);
    final spacing = screenWidth * 0.02; // 2% of screen width
    // Increased aspect ratio to give more height and prevent overflow
    final aspectRatio = isMobile ? 1.1 : (isTablet ? 1.3 : 1.5);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: aspectRatio,
      children: [
        ModernStatCard(
          title: 'Total Guru',
          value: total.toString(),
          icon: Icons.people,
          color: AppTheme.primaryColor,
          subtitle: 'Semua guru terdaftar',
        ),
        ModernStatCard(
          title: 'Hadir Hari Ini',
          value: present.toString(),
          icon: Icons.check_circle,
          color: AppTheme.successColor,
          subtitle: 'Guru yang sudah absen',
          trend: '+${present}',
          isPositiveTrend: true,
        ),
        ModernStatCard(
          title: 'Belum Hadir',
          value: absent.toString(),
          icon: Icons.cancel,
          color: Colors.red,
          subtitle: 'Guru yang belum absen',
          trend: '-${absent}',
          isPositiveTrend: false,
        ),
        ModernStatCard(
          title: 'Tingkat Kehadiran',
          value: '${presentPercentage.toStringAsFixed(1)}%',
          icon: Icons.trending_up,
          color: AppTheme.accentColor,
          subtitle: 'Persentase kehadiran',
        ),
      ],
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
              Text(
                'Kehadiran Terkini',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportsScreen()),
                  );
                },
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const Divider(),
          if (_recentAttendance.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada data kehadiran',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._recentAttendance.map((attendance) {
              final statusColor = attendance.isOnTime
                  ? AppTheme.successColor
                  : attendance.isLate
                      ? Colors.orange
                      : Colors.blue;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        attendance.isOnTime
                            ? Icons.check_circle
                            : attendance.isLate
                                ? Icons.schedule
                                : Icons.verified,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            attendance.teacher?.fullName ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                attendance.classroom?.name ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('HH:mm').format(attendance.scanTime),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        attendance.statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Aksi Cepat',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: MediaQuery.of(context).size.width * 0.04),
          ..._buildActionButtonsList(),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtonsList() {
    return [
      _buildActionButton(
        'Data Guru',
        Icons.people_outline,
        AppTheme.primaryColor,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ManageTeachersScreen()),
        ),
      ),
      SizedBox(height: MediaQuery.of(context).size.width * 0.025),
      _buildActionButton(
        'Ruangan',
        Icons.meeting_room_outlined,
        AppTheme.secondaryColor,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ManageClassroomsScreen()),
        ),
      ),
      SizedBox(height: MediaQuery.of(context).size.width * 0.025),
      _buildActionButton(
        'Jadwal',
        Icons.calendar_month_outlined,
        Colors.orange,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ManageSchedulesScreen()),
        ),
      ),
      SizedBox(height: MediaQuery.of(context).size.width * 0.025),
      _buildActionButton(
        'Laporan',
        Icons.assessment_outlined,
        Colors.purple,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportsScreen()),
        ),
      ),
      SizedBox(height: MediaQuery.of(context).size.width * 0.025),
      _buildActionButton(
        'Analytics',
        Icons.bar_chart,
        Colors.teal,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
        ),
      ),
      SizedBox(height: MediaQuery.of(context).size.width * 0.025),
      _buildActionButton(
        'Penggajian',
        Icons.account_balance_wallet_outlined,
        AppTheme.accentColor,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PayrollScreen()),
        ),
      ),
    ];
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final padding = screenWidth * 0.02; // 2% of screen width
        final iconSize = screenWidth * 0.025; // 2.5% of screen width
        final fontSize = screenWidth * 0.015; // 1.5% of screen width
        
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: padding,
              vertical: padding * 0.8,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(padding * 0.6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                  child: Icon(icon, color: color, size: iconSize),
                ),
                SizedBox(width: padding * 0.8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontSize: fontSize.clamp(12.0, 16.0),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: iconSize * 0.7,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final padding = screenWidth * 0.04; // 4% of screen width
        final spacing = screenWidth * 0.05; // 5% of screen width
        
        return RefreshIndicator(
          onRefresh: () => _loadData(forceRefresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Server Time
                ModernCard(
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: ServerTimeDisplay(showFullInfo: true),
                  ),
                ),
                SizedBox(height: spacing),

                // Stats Cards
                _buildMobileStats(),
                SizedBox(height: spacing),

                // Quick Actions
                _buildQuickActions(),
                SizedBox(height: spacing),

                // Recent Attendance
                _buildRecentAttendance(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileStats() {
    final total = _stats['total_teachers'] as int? ?? 0;
    final present = _stats['present'] as int? ?? 0;
    final absent = _stats['absent'] as int? ?? 0;
    final presentPercentage = total > 0 ? (present / total * 100) : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ModernStatCard(
                title: 'Total Guru',
                value: total.toString(),
                icon: Icons.people,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ModernStatCard(
                title: 'Hadir',
                value: present.toString(),
                icon: Icons.check_circle,
                color: AppTheme.successColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ModernStatCard(
                title: 'Belum Hadir',
                value: absent.toString(),
                icon: Icons.cancel,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ModernStatCard(
                title: 'Persentase',
                value: '${presentPercentage.toStringAsFixed(1)}%',
                icon: Icons.trending_up,
                color: AppTheme.accentColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

