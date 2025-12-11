import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/user_model.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final UserModel? currentUser;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      return _buildMobileDrawer(context);
    }

    return _buildDesktopSidebar(context);
  }

  Widget _buildDesktopSidebar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = screenWidth * 0.18; // 18% of screen width, max 280
    final padding = sidebarWidth * 0.08; // 8% of sidebar width
    
    return Container(
      width: sidebarWidth.clamp(240.0, 280.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark blue-grey
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo Section
          Container(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: [
                Container(
                  width: sidebarWidth * 0.25,
                  height: sidebarWidth * 0.25,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(sidebarWidth * 0.06),
                  ),
                  child: Center(
                    child: Text(
                      'SI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: sidebarWidth * 0.09,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: padding * 0.5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: const Text(
                    'SIGAP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: padding * 0.25),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Sistem Informasi Guru',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: sidebarWidth * 0.045,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white24, height: 1),

          // User Profile Section
          if (currentUser != null)
            Container(
              padding: EdgeInsets.all(padding * 0.8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: sidebarWidth * 0.15,
                    backgroundColor: AppTheme.accentColor.withOpacity(0.2),
                    child: Text(
                      currentUser!.fullName[0].toUpperCase(),
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: sidebarWidth * 0.09,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: padding * 0.6),
                  Text(
                    currentUser!.fullName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: sidebarWidth * 0.06,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (currentUser!.nip.isNotEmpty) ...[
                    SizedBox(height: padding * 0.2),
                    Text(
                      'NIP: ${currentUser!.nip}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: sidebarWidth * 0.045,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: padding * 0.6),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Navigate to profile edit
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: EdgeInsets.symmetric(vertical: padding * 0.4),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: const Text('Edit Profile'),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const Divider(color: Colors.white24, height: 1),

          // Navigation Menu
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: padding * 0.7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  title: 'Dashboard',
                  index: 0,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.analytics_outlined,
                  activeIcon: Icons.analytics,
                  title: 'Analytics',
                  index: 1,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  title: 'Data Guru',
                  index: 2,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.meeting_room_outlined,
                  activeIcon: Icons.meeting_room,
                  title: 'Ruangan',
                  index: 3,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month,
                  title: 'Jadwal',
                  index: 4,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.assessment_outlined,
                  activeIcon: Icons.assessment,
                  title: 'Laporan',
                  index: 5,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet,
                  title: 'Penggajian',
                  index: 6,
                ),
                ],
              ),
            ),
          ),

          const Divider(color: Colors.white24, height: 1),

          // Bottom Section
          Padding(
            padding: EdgeInsets.all(padding * 0.7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  title: 'Pengaturan',
                  index: 7,
                ),
                SizedBox(height: padding * 0.5),
                _buildMenuItem(
                  context,
                  icon: Icons.logout_outlined,
                  activeIcon: Icons.logout,
                  title: 'Logout',
                  index: 8,
                  isDanger: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'SI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'SIGAP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // User Profile
            if (currentUser != null)
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.accentColor.withOpacity(0.2),
                      child: Text(
                        currentUser!.fullName[0].toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: 20,
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
                            currentUser!.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (currentUser!.nip.isNotEmpty)
                            Text(
                              'NIP: ${currentUser!.nip}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(color: Colors.white24, height: 1),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    title: 'Dashboard',
                    index: 0,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.analytics_outlined,
                    activeIcon: Icons.analytics,
                    title: 'Analytics',
                    index: 1,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.people_outline,
                    activeIcon: Icons.people,
                    title: 'Data Guru',
                    index: 2,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.meeting_room_outlined,
                    activeIcon: Icons.meeting_room,
                    title: 'Ruangan',
                    index: 3,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.calendar_month_outlined,
                    activeIcon: Icons.calendar_month,
                    title: 'Jadwal',
                    index: 4,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.assessment_outlined,
                    activeIcon: Icons.assessment,
                    title: 'Laporan',
                    index: 5,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    activeIcon: Icons.account_balance_wallet,
                    title: 'Penggajian',
                    index: 6,
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  _buildMenuItem(
                    context,
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings,
                    title: 'Pengaturan',
                    index: 7,
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.logout_outlined,
                    activeIcon: Icons.logout,
                    title: 'Logout',
                    index: 8,
                    isDanger: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required int index,
    bool isDanger = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = (screenWidth * 0.18).clamp(240.0, 280.0);
    final padding = sidebarWidth * 0.08;
    final isSelected = selectedIndex == index;
    final color = isDanger
        ? Colors.red[300]
        : isSelected
            ? AppTheme.accentColor
            : Colors.white.withOpacity(0.8);

    return InkWell(
      onTap: () => onItemSelected(index),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: padding * 0.6, vertical: padding * 0.2),
        padding: EdgeInsets.symmetric(horizontal: padding * 0.7, vertical: padding * 0.6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(sidebarWidth * 0.04),
          border: isSelected
              ? Border.all(color: AppTheme.accentColor.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: color,
              size: sidebarWidth * 0.09,
            ),
            SizedBox(width: padding * 0.7),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: sidebarWidth * 0.055,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Container(
                width: sidebarWidth * 0.015,
                height: sidebarWidth * 0.015,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

