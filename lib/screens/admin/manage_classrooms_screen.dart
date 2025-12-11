import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/supabase_client.dart';
import '../../models/classroom_model.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_bar_widget.dart';
import 'classroom_form_screen.dart';

class ManageClassroomsScreen extends StatefulWidget {
  const ManageClassroomsScreen({super.key});
  
  @override
  State<ManageClassroomsScreen> createState() => _ManageClassroomsScreenState();
}

class _ManageClassroomsScreenState extends State<ManageClassroomsScreen> {
  List<ClassroomModel> _classrooms = [];
  List<ClassroomModel> _filteredClassrooms = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, active, inactive
  
  @override
  void initState() {
    super.initState();
    _loadClassrooms();
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
    _filteredClassrooms = _classrooms.where((classroom) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          classroom.name.toLowerCase().contains(_searchQuery) ||
          classroom.qrSecret.toLowerCase().contains(_searchQuery);
      
      // Status filter
      final matchesStatus = _selectedFilter == 'all' ||
          (_selectedFilter == 'active' && classroom.isActive) ||
          (_selectedFilter == 'inactive' && !classroom.isActive);
      
      return matchesSearch && matchesStatus;
    }).toList();
  }
  
  Future<void> _loadClassrooms({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Gunakan cache untuk mengurangi request
      final classroomsData = await SupabaseService.getAllClassrooms(useCache: !forceRefresh);
      _classrooms = classroomsData
          .map((json) => ClassroomModel.fromJson(json))
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
  
  void _showQRCode(ClassroomModel classroom) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.qr_code_2,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                classroom.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: classroom.qrSecret,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Text(
                      'QR Secret: ${classroom.qrSecret}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Ruangan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ClassroomFormScreen(),
                ),
              );
              if (result == true) {
                _loadClassrooms();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? SkeletonLoader(
              itemCount: 5,
              itemBuilder: (context, index) => const SkeletonCard(),
            )
          : RefreshIndicator(
              onRefresh: () => _loadClassrooms(forceRefresh: true),
              child: Column(
                children: [
                  // Search Bar
                  SearchBarWidget(
                    controller: _searchController,
                    hintText: 'Cari nama ruangan atau QR secret...',
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
                    child: _filteredClassrooms.isEmpty
                        ? _searchQuery.isNotEmpty || _selectedFilter != 'all'
                            ? EmptyStates.search(context, query: _searchQuery)
                            : EmptyStates.classrooms(
                                context,
                                onAdd: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ClassroomFormScreen(),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadClassrooms();
                                  }
                                },
                              )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredClassrooms.length,
                            itemBuilder: (context, index) {
                              final classroom = _filteredClassrooms[index];
                        return ModernCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClassroomFormScreen(classroom: classroom),
                              ),
                            );
                            if (result == true) {
                              _loadClassrooms();
                            }
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.secondary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.room,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            classroom.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: (classroom.isActive ? Colors.green : Colors.red).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                classroom.isActive ? Icons.check_circle : Icons.cancel,
                                                size: 14,
                                                color: classroom.isActive ? Colors.green : Colors.red,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                classroom.isActive ? 'Aktif' : 'Nonaktif',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: classroom.isActive ? Colors.green : Colors.red,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.qr_code, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            classroom.qrSecret,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                              fontFamily: 'monospace',
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.straighten, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Radius: ${classroom.radiusMeter} m',
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
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  Icons.qr_code_scanner,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                onPressed: () => _showQRCode(classroom),
                                tooltip: 'Lihat QR Code',
                                style: IconButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                ),
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

