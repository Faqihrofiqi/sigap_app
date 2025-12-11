import 'package:flutter/material.dart';
import '../../core/supabase_client.dart';
import '../../models/schedule_model.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_bar_widget.dart';
import 'schedule_form_screen.dart';
import 'batch_schedule_form_screen.dart';

class ManageSchedulesScreen extends StatefulWidget {
  const ManageSchedulesScreen({super.key});
  
  @override
  State<ManageSchedulesScreen> createState() => _ManageSchedulesScreenState();
}

class _ManageSchedulesScreenState extends State<ManageSchedulesScreen> {
  List<ScheduleModel> _schedules = [];
  List<ScheduleModel> _filteredSchedules = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, active, inactive
  
  @override
  void initState() {
    super.initState();
    _loadSchedules();
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
    _filteredSchedules = _schedules.where((schedule) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          schedule.subject.toLowerCase().contains(_searchQuery) ||
          (schedule.teacher?.fullName.toLowerCase().contains(_searchQuery) ?? false) ||
          (schedule.classroom?.name.toLowerCase().contains(_searchQuery) ?? false) ||
          schedule.dayName.toLowerCase().contains(_searchQuery);
      
      // Status filter
      final matchesStatus = _selectedFilter == 'all' ||
          (_selectedFilter == 'active' && schedule.isActive) ||
          (_selectedFilter == 'inactive' && !schedule.isActive);
      
      return matchesSearch && matchesStatus;
    }).toList();
  }
  
  Future<void> _loadSchedules({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Gunakan cache untuk mengurangi request
      final schedulesData = await SupabaseService.getAllSchedules(useCache: !forceRefresh);
      _schedules = schedulesData
          .map((json) => ScheduleModel.fromJson(json))
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Jadwal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Jadwal',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ScheduleFormScreen(),
                ),
              );
              if (result == true) {
                _loadSchedules();
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'batch') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BatchScheduleFormScreen(),
                  ),
                );
                if (result == true) {
                  _loadSchedules();
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'batch',
                child: Row(
                  children: [
                    Icon(Icons.batch_prediction, size: 20),
                    SizedBox(width: 8),
                    Text('Tambah Batch'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? SkeletonLoader(
              itemCount: 5,
              itemBuilder: (context, index) => const SkeletonCard(),
            )
          : RefreshIndicator(
              onRefresh: () => _loadSchedules(forceRefresh: true),
              child: Column(
                children: [
                  // Search Bar
                  SearchBarWidget(
                    controller: _searchController,
                    hintText: 'Cari jadwal, guru, atau ruangan...',
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
                        _buildFilterChip('Aktif', 'active'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Nonaktif', 'inactive'),
                      ],
                    ),
                  ),
                  
                  // List or Empty State
                  Expanded(
                    child: _filteredSchedules.isEmpty
                        ? _searchQuery.isNotEmpty || _selectedFilter != 'all'
                            ? EmptyStates.search(context, query: _searchQuery)
                            : EmptyStates.schedules(
                                context,
                                onAdd: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ScheduleFormScreen(),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadSchedules();
                                  }
                                },
                              )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredSchedules.length,
                            itemBuilder: (context, index) {
                              final schedule = _filteredSchedules[index];
                        return ModernCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ScheduleFormScreen(schedule: schedule),
                              ),
                            );
                            if (result == true) {
                              _loadSchedules();
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.book_outlined,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          schedule.subject,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                schedule.teacher?.fullName ?? 'Unknown',
                                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: schedule.isActive
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      schedule.isActive ? 'Aktif' : 'Nonaktif',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: schedule.isActive ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    schedule.dayName,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    schedule.timeRange,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(Icons.room, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      schedule.classroom?.name ?? 'Unknown',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
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

