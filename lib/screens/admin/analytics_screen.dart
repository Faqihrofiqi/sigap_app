import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/supabase_client.dart';
import '../../core/app_theme.dart';
import '../../models/attendance_model.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/professional_dialogs.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<AttendanceModel> _attendanceList = [];
  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
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
      _loadAnalytics();
    }
  }

  // Calculate daily attendance stats
  Map<DateTime, Map<String, int>> _getDailyStats() {
    final Map<DateTime, Map<String, int>> dailyStats = {};

    for (var attendance in _attendanceList) {
      final date = DateTime(
        attendance.scanTime.year,
        attendance.scanTime.month,
        attendance.scanTime.day,
      );

      if (!dailyStats.containsKey(date)) {
        dailyStats[date] = {
          'total': 0,
          'onTime': 0,
          'late': 0,
        };
      }

      dailyStats[date]!['total'] = dailyStats[date]!['total']! + 1;
      if (attendance.isOnTime) {
        dailyStats[date]!['onTime'] = dailyStats[date]!['onTime']! + 1;
      } else if (attendance.isLate) {
        dailyStats[date]!['late'] = dailyStats[date]!['late']! + 1;
      }
    }

    return dailyStats;
  }

  // Get attendance by day of week
  Map<int, Map<String, int>> _getDayOfWeekStats() {
    final Map<int, Map<String, int>> dayStats = {};

    for (var attendance in _attendanceList) {
      final dayOfWeek = attendance.scanTime.weekday;

      if (!dayStats.containsKey(dayOfWeek)) {
        dayStats[dayOfWeek] = {
          'total': 0,
          'onTime': 0,
          'late': 0,
        };
      }

      dayStats[dayOfWeek]!['total'] = dayStats[dayOfWeek]!['total']! + 1;
      if (attendance.isOnTime) {
        dayStats[dayOfWeek]!['onTime'] = dayStats[dayOfWeek]!['onTime']! + 1;
      } else if (attendance.isLate) {
        dayStats[dayOfWeek]!['late'] = dayStats[dayOfWeek]!['late']! + 1;
      }
    }

    return dayStats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Statistik'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Date Range Selector
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
                                  Icons.calendar_today,
                                  color: AppTheme.primaryColor,
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
                            onPressed: _selectDateRange,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Summary Cards
                    _buildSummaryCards(),
                    const SizedBox(height: 20),

                    // Daily Attendance Chart
                    ModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trend Kehadiran Harian',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 250,
                            child: _buildDailyChart(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Day of Week Chart
                    ModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kehadiran per Hari',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 250,
                            child: _buildDayOfWeekChart(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Teacher Performance
                    ModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top 5 Guru Paling Disiplin',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 20),
                          _buildTeacherPerformance(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    final total = _attendanceList.length;
    final onTime = _attendanceList.where((a) => a.isOnTime).length;
    final late = _attendanceList.where((a) => a.isLate).length;
    final onTimePercentage = total > 0 ? (onTime / total * 100) : 0.0;

    return Row(
      children: [
        Expanded(
          child: ModernCard(
            child: Column(
              children: [
                Text(
                  total.toString(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Total Kehadiran',
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
                  '${onTimePercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tepat Waktu',
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
                  late.toString(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Terlambat',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyChart() {
    final dailyStats = _getDailyStats();
    if (dailyStats.isEmpty) {
      return const Center(
        child: Text('Tidak ada data untuk ditampilkan'),
      );
    }

    final sortedDates = dailyStats.keys.toList()..sort();
    final maxValue = dailyStats.values
        .map((stats) => stats['total'] ?? 0)
        .fold(0, (a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= sortedDates.length) return const Text('');
                final date = sortedDates[value.toInt()];
                return Text(
                  DateFormat('dd/MM').format(date),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: (sortedDates.length - 1).toDouble(),
        minY: 0,
        maxY: maxValue > 0 ? maxValue.toDouble() : 10,
        lineBarsData: [
          LineChartBarData(
            spots: sortedDates.asMap().entries.map((entry) {
              final index = entry.key;
              final stats = dailyStats[entry.value]!;
              return FlSpot(index.toDouble(), (stats['onTime'] ?? 0).toDouble());
            }).toList(),
            isCurved: true,
            color: AppTheme.successColor,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: AppTheme.successColor.withOpacity(0.2)),
          ),
          LineChartBarData(
            spots: sortedDates.asMap().entries.map((entry) {
              final index = entry.key;
              final stats = dailyStats[entry.value]!;
              return FlSpot(index.toDouble(), (stats['late'] ?? 0).toDouble());
            }).toList(),
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: Colors.orange.withOpacity(0.2)),
          ),
        ],
      ),
    );
  }

  Widget _buildDayOfWeekChart() {
    final dayStats = _getDayOfWeekStats();
    if (dayStats.isEmpty) {
      return const Center(
        child: Text('Tidak ada data untuk ditampilkan'),
      );
    }

    final dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: dayStats.values
            .map((stats) => stats['total'] ?? 0)
            .fold(0, (a, b) => a > b ? a : b)
            .toDouble(),
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final dayIndex = value.toInt();
                if (dayIndex < 1 || dayIndex > 7) return const Text('');
                return Text(dayNames[dayIndex - 1], style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        barGroups: List.generate(7, (index) {
          final day = index + 1;
          final stats = dayStats[day] ?? {'total': 0, 'onTime': 0, 'late': 0};
          return BarChartGroupData(
            x: day,
            barRods: [
              BarChartRodData(
                toY: (stats['onTime'] ?? 0).toDouble(),
                color: AppTheme.successColor,
                width: 12,
              ),
              BarChartRodData(
                toY: (stats['late'] ?? 0).toDouble(),
                color: Colors.orange,
                width: 12,
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTeacherPerformance() {
    final Map<String, Map<String, int>> teacherStats = {};

    for (var attendance in _attendanceList) {
      final teacherName = attendance.teacher?.fullName ?? 'Unknown';
      if (!teacherStats.containsKey(teacherName)) {
        teacherStats[teacherName] = {'total': 0, 'onTime': 0};
      }
      teacherStats[teacherName]!['total'] = teacherStats[teacherName]!['total']! + 1;
      if (attendance.isOnTime) {
        teacherStats[teacherName]!['onTime'] = teacherStats[teacherName]!['onTime']! + 1;
      }
    }

    final sortedTeachers = teacherStats.entries.toList()
      ..sort((a, b) {
        final aPercentage = a.value['total']! > 0
            ? (a.value['onTime']! / a.value['total']!) * 100
            : 0.0;
        final bPercentage = b.value['total']! > 0
            ? (b.value['onTime']! / b.value['total']!) * 100
            : 0.0;
        return bPercentage.compareTo(aPercentage);
      });

    final top5 = sortedTeachers.take(5).toList();

    if (top5.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Tidak ada data untuk ditampilkan'),
        ),
      );
    }

    return Column(
      children: top5.asMap().entries.map((entry) {
        final index = entry.key;
        final teacher = entry.value;
        final total = teacher.value['total'] ?? 0;
        final onTime = teacher.value['onTime'] ?? 0;
        final percentage = total > 0 ? (onTime / total * 100) : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.successColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

