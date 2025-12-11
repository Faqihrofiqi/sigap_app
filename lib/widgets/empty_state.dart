import 'package:flutter/material.dart';

/// Widget untuk menampilkan empty state yang informatif
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon dengan background
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (iconColor ?? theme.colorScheme.primary).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: iconColor ?? theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            
            // Message (optional)
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            // Action Button (optional)
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 20),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Predefined empty states untuk berbagai use case
class EmptyStates {
  static Widget schedules(BuildContext context, {VoidCallback? onAdd}) {
    return EmptyState(
      icon: Icons.calendar_today_outlined,
      title: 'Tidak ada jadwal',
      message: 'Tambahkan jadwal baru untuk memulai mengelola aktivitas pembelajaran',
      actionLabel: 'Tambah Jadwal',
      onAction: onAdd,
      iconColor: Colors.orange,
    );
  }
  
  static Widget teachers(BuildContext context, {VoidCallback? onAdd}) {
    return EmptyState(
      icon: Icons.person_outline,
      title: 'Tidak ada data guru',
      message: 'Tambahkan guru baru untuk memulai mengelola data kepegawaian',
      actionLabel: 'Tambah Guru',
      onAction: onAdd,
      iconColor: Colors.blue,
    );
  }
  
  static Widget classrooms(BuildContext context, {VoidCallback? onAdd}) {
    return EmptyState(
      icon: Icons.room_outlined,
      title: 'Tidak ada data ruangan',
      message: 'Tambahkan ruangan baru untuk memulai mengelola lokasi pembelajaran',
      actionLabel: 'Tambah Ruangan',
      onAction: onAdd,
      iconColor: Colors.green,
    );
  }
  
  static Widget reports(BuildContext context) {
    return EmptyState(
      icon: Icons.assessment_outlined,
      title: 'Tidak ada data laporan',
      message: 'Tidak ada data kehadiran pada periode yang dipilih. Coba pilih periode lain.',
      iconColor: Colors.purple,
    );
  }
  
  static Widget search(BuildContext context, {String? query}) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'Tidak ada hasil',
      message: query != null && query.isNotEmpty
          ? 'Tidak ada data yang cocok dengan "$query"'
          : 'Coba gunakan kata kunci lain untuk mencari',
      iconColor: Colors.grey,
    );
  }
  
  static Widget attendance(BuildContext context) {
    return EmptyState(
      icon: Icons.event_busy_outlined,
      title: 'Tidak ada data kehadiran',
      message: 'Belum ada data kehadiran yang tercatat',
      iconColor: Colors.teal,
    );
  }
}

