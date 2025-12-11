import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/supabase_client.dart';
import '../../models/attendance_model.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/professional_dialogs.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_bar_widget.dart';
import '../../services/export_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<AttendanceModel> _attendanceList = [];
  List<AttendanceModel> _filteredAttendanceList = [];
  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, ontime, late, absent
  
  @override
  void initState() {
    super.initState();
    _loadReports();
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }
  
  void _applyFilters() {
    _filteredAttendanceList = _attendanceList.where((attendance) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          (attendance.teacher?.fullName.toLowerCase().contains(_searchQuery) ?? false) ||
          (attendance.classroom?.name.toLowerCase().contains(_searchQuery) ?? false) ||
          attendance.statusLabel.toLowerCase().contains(_searchQuery);
      
      // Status filter
      final matchesStatus = _selectedFilter == 'all' ||
          (_selectedFilter == 'ontime' && attendance.isOnTime) ||
          (_selectedFilter == 'late' && attendance.isLate) ||
          (_selectedFilter == 'absent' && !attendance.isOnTime && !attendance.isLate);
      
      return matchesSearch && matchesStatus;
    }).toList();
  }
  
  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final attendanceData = await SupabaseService.getAttendanceHistory(
        startDate: _startDate,
        endDate: _endDate,
      );
      
      _attendanceList = attendanceData
          .map((json) => AttendanceModel.fromJson(json))
          .toList();
      _applyFilters();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
  
  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReports();
    }
  }
  
  Future<void> _showExportOptions() async {
    if (_attendanceList.isEmpty) {
      ProfessionalDialogs.showInfoDialog(
        context: context,
        title: 'Tidak Ada Data',
        message: 'Tidak ada data untuk diexport. Silakan pilih periode lain.',
      );
      return;
    }

    final option = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export ke Excel'),
              subtitle: const Text('Format .xlsx untuk analisis data'),
              onTap: () => Navigator.pop(context, 'excel'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export ke PDF'),
              subtitle: const Text('Format .pdf untuk laporan resmi'),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );

    if (option == null) return;

    if (option == 'excel') {
      await ExportService.exportToExcel(
        context: context,
        attendanceList: _attendanceList,
        startDate: _startDate,
        endDate: _endDate,
      );
    } else if (option == 'pdf') {
      await ExportService.exportToPDF(
        context: context,
        attendanceList: _attendanceList,
        startDate: _startDate,
        endDate: _endDate,
      );
    }
  }
  
  // Format waktu ke timezone lokal (sudah di-handle di model)
  String _formatLocalTime(DateTime dateTime) {
    // Waktu sudah dikonversi di model, langsung format saja
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Kehadiran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _showExportOptions,
            tooltip: 'Export Laporan',
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Range Selector
          ModernCard(
            margin: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Periode',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.edit_calendar,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: _selectDateRange,
                  tooltip: 'Pilih Periode',
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
          
          // Search Bar
          SearchBarWidget(
            controller: _searchController,
            hintText: 'Cari nama guru, ruangan, atau status...',
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
                _applyFilters();
              });
            },
          ),
          
          // Filter Chips
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('Semua', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Tepat Waktu', 'ontime', Icons.check_circle),
                const SizedBox(width: 8),
                _buildFilterChip('Terlambat', 'late', Icons.schedule),
                const SizedBox(width: 8),
                _buildFilterChip('Absen', 'absent', Icons.cancel),
              ],
            ),
          ),
          
          // Attendance List
          Expanded(
            child: _isLoading
                ? SkeletonLoader(
                    itemCount: 5,
                    itemBuilder: (context, index) => const SkeletonCard(),
                  )
                : RefreshIndicator(
                    onRefresh: _loadReports,
                    child: _filteredAttendanceList.isEmpty
                        ? _searchQuery.isNotEmpty || _selectedFilter != 'all'
                            ? EmptyStates.search(context, query: _searchQuery)
                            : EmptyStates.reports(context)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredAttendanceList.length,
                            itemBuilder: (context, index) {
                              final attendance = _filteredAttendanceList[index];
                              // Tentukan warna berdasarkan status
                              final statusColor = attendance.isOnTime 
                                  ? Colors.green 
                                  : attendance.isLate 
                                      ? Colors.orange 
                                      : Colors.blue;
                              
                              return ModernCard(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            statusColor,
                                            statusColor.withOpacity(0.7),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        attendance.isOnTime 
                                            ? Icons.check_circle 
                                            : attendance.isLate 
                                                ? Icons.schedule 
                                                : Icons.verified,
                                        color: Colors.white,
                                        size: 24,
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
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[600]),
                                              const SizedBox(width: 4),
                                              Text(
                                                attendance.classroom?.name ?? 'Unknown',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  attendance.scanTypeLabel,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: statusColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatLocalTime(attendance.scanTime),
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
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            attendance.statusLabel,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        if (attendance.isLate && attendance.lateMinutes != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '${attendance.lateMinutes} menit',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.orange[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label, String value, [IconData? icon]) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      avatar: icon != null ? Icon(icon, size: 16) : null,
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
          _applyFilters();
        });
      },
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

