import 'package:flutter/material.dart';
import '../../core/supabase_client.dart';
import '../../models/user_model.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_bar_widget.dart';
import 'teacher_form_screen.dart';
import 'batch_add_teachers_screen.dart';

class ManageTeachersScreen extends StatefulWidget {
  const ManageTeachersScreen({super.key});
  
  @override
  State<ManageTeachersScreen> createState() => _ManageTeachersScreenState();
}

class _ManageTeachersScreenState extends State<ManageTeachersScreen> {
  List<UserModel> _teachers = [];
  List<UserModel> _filteredTeachers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadTeachers();
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
    _filteredTeachers = _teachers.where((teacher) {
      return _searchQuery.isEmpty ||
          teacher.fullName.toLowerCase().contains(_searchQuery) ||
          teacher.nip.toLowerCase().contains(_searchQuery);
    }).toList();
  }
  
  Future<void> _loadTeachers({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Gunakan cache untuk mengurangi request
      final teachersData = await SupabaseService.getAllTeachers(useCache: !forceRefresh);
      _teachers = teachersData
          .map((json) => UserModel.fromJson(json))
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
        title: const Text('Data Guru'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Tambah Batch',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BatchAddTeachersScreen(),
                ),
              );
              if (result == true) {
                _loadTeachers();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Satu',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TeacherFormScreen(),
                ),
              );
              if (result == true) {
                _loadTeachers();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? SkeletonLoader(
              itemCount: 5,
              itemBuilder: (context, index) => const SkeletonListItem(),
            )
          : RefreshIndicator(
              onRefresh: () => _loadTeachers(forceRefresh: true),
              child: Column(
                children: [
                  // Search Bar
                  SearchBarWidget(
                    controller: _searchController,
                    hintText: 'Cari nama, NIP, atau email guru...',
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                        _applyFilters();
                      });
                    },
                  ),
                  
                  // List or Empty State
                  Expanded(
                    child: _filteredTeachers.isEmpty
                        ? _searchQuery.isNotEmpty
                            ? EmptyStates.search(context, query: _searchQuery)
                            : EmptyStates.teachers(
                                context,
                                onAdd: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const TeacherFormScreen(),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadTeachers();
                                  }
                                },
                              )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredTeachers.length,
                            itemBuilder: (context, index) {
                              final teacher = _filteredTeachers[index];
                        return ModernCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TeacherFormScreen(teacher: teacher),
                              ),
                            );
                            if (result == true) {
                              _loadTeachers();
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
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    teacher.fullName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      teacher.fullName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.badge_outlined, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          'NIP: ${teacher.nip}',
                                          style: TextStyle(
                                            fontSize: 13,
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
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  teacher.formattedPresenceRate,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
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
}

