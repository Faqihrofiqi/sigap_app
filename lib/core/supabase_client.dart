import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cache_service.dart';

class SupabaseService {
  static bool _isInitialized = false;
  
  // Initialize Supabase
  // IMPORTANT: Replace with your Supabase URL and Anon Key
  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }
  
  static SupabaseClient get client {
    if (!_isInitialized) {
      // Try to get instance anyway (might be initialized elsewhere)
      try {
        return Supabase.instance.client;
      } catch (e) {
        throw Exception('Supabase belum diinisialisasi. Panggil SupabaseService.initialize() terlebih dahulu.');
      }
    }
    return Supabase.instance.client;
  }
  
  // Get current user
  static User? get currentUser => client.auth.currentUser;
  
  // Check if user is authenticated
  static bool get isAuthenticated {
    try {
      return currentUser != null;
    } catch (e) {
      return false;
    }
  }
  
  // Sign in
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  // Sign out with proper cleanup
  static Future<void> signOut() async {
    try {
      // Clear cache first
      await clearAllCache();
      // Then sign out
      await client.auth.signOut();
    } catch (e) {
      // Even if cache clear fails, still try to sign out
      await client.auth.signOut();
      rethrow;
    }
  }
  
  // Change password (requires current password)
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // First verify current password by attempting to re-authenticate
      final user = currentUser;
      if (user?.email == null) {
        throw Exception('User tidak terautentikasi');
      }
      
      // Re-authenticate with current password
      await client.auth.signInWithPassword(
        email: user!.email!,
        password: currentPassword,
      );
      
      // Update password
      await client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error changing password: $e');
      }
      rethrow;
    }
  }
  
  // Reset password (forgot password) - sends email
  static Future<void> resetPassword({required String email}) async {
    try {
      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: null, // Supabase will handle the redirect
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting password: $e');
      }
      rethrow;
    }
  }
  
  // Update password after reset (when user clicks link from email)
  static Future<void> updatePasswordAfterReset({
    required String newPassword,
  }) async {
    try {
      await client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating password after reset: $e');
      }
      rethrow;
    }
  }
  
  // Refresh session
  static Future<void> refreshSession() async {
    try {
      await client.auth.refreshSession();
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing session: $e');
      }
      rethrow;
    }
  }
  
  // Get session state
  static Session? get session => client.auth.currentSession;
  
  // Check if session is expired or about to expire (within 5 minutes)
  static bool get isSessionExpiring {
    final sess = session;
    if (sess == null) return true;
    final expiresAt = sess.expiresAt;
    if (expiresAt == null) return false;
    final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
    final now = DateTime.now();
    final timeUntilExpiry = expiryTime.difference(now);
    // Consider expiring if less than 5 minutes remaining
    return timeUntilExpiry.inMinutes < 5;
  }
  
  // Helper method to ensure session is valid before making API calls
  // Automatically refreshes session if needed
  static Future<void> ensureValidSession() async {
    if (!isAuthenticated) {
      throw Exception('User tidak terautentikasi');
    }
    
    // Refresh session if it's expiring
    if (isSessionExpiring) {
      try {
        await refreshSession();
        if (kDebugMode) {
          print('Session refreshed automatically');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to refresh session: $e');
        }
        // If refresh fails, session might be invalid
        throw Exception('Sesi telah kedaluwarsa. Silakan login kembali.');
      }
    }
  }
  
  // Submit attendance via RPC
  static Future<Map<String, dynamic>> submitAttendance({
    required String qrSecret,
    required double latitude,
    required double longitude,
    String scanType = 'CHECK_IN_SCHOOL',
  }) async {
    try {
      final response = await client.rpc(
        'submit_attendance',
        params: {
          'p_qr_secret': qrSecret,
          'p_user_lat': latitude,
          'p_user_long': longitude,
          'p_scan_type': scanType,
        },
      );
      
      return response as Map<String, dynamic>;
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }
  
  // Get server time (for timezone verification)
  static Future<Map<String, dynamic>> getServerTime() async {
    try {
      final response = await client.rpc('get_server_time');
      return response as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting server time: $e');
      }
      // Fallback to local time if function not available
      final now = DateTime.now();
      return {
        'server_time_utc': now.toUtc().toIso8601String(),
        'server_time_local': now.toIso8601String(),
        'timezone': 'Local',
        'timezone_offset': '+07:00',
        'day_of_week': now.weekday,
        'date': now.toIso8601String().split('T')[0],
        'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
      };
    }
  }
  
  // Get today's attendance stats (Admin) - with cache
  static Future<Map<String, dynamic>> getTodayAttendanceStats({bool useCache = true}) async {
    // Try cache first
    if (useCache) {
      final cached = await CacheService.getCache('today_stats');
      if (cached != null) {
        return cached as Map<String, dynamic>;
      }
    }
    
    try {
      final response = await client.rpc('get_today_attendance_stats');
      final result = response as Map<String, dynamic>;
      
      // Cache for 2 minutes
      await CacheService.saveCache('today_stats', result, duration: const Duration(minutes: 2));
      
      return result;
    } catch (e) {
      return {
        'total_teachers': 0,
        'present': 0,
        'absent': 0,
        'error': e.toString(),
      };
    }
  }
  
  // Get user profile - with cache
  static Future<Map<String, dynamic>?> getUserProfile({bool useCache = true}) async {
    if (!isAuthenticated) return null;
    
    final userId = currentUser!.id;
    final cacheKey = 'user_profile_$userId';
    
    // Try cache first
    if (useCache) {
      final cached = await CacheService.getCache(cacheKey);
      if (cached != null) {
        return cached as Map<String, dynamic>;
      }
    }
    
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      final result = response as Map<String, dynamic>;
      
      // Cache for 10 minutes (profile doesn't change often)
      await CacheService.saveCache(cacheKey, result, duration: const Duration(minutes: 10));
      
      return result;
    } catch (e) {
      // Log error for debugging
      if (kDebugMode) {
        print('Error getting user profile: $e');
        print('User ID: $userId');
      }
      return null;
    }
  }
  
  // Get today's schedules for teacher
  static Future<List<Map<String, dynamic>>> getTodaySchedules() async {
    if (!isAuthenticated) return [];
    
    final today = DateTime.now();
    final dayOfWeek = today.weekday; // 1 = Monday, 7 = Sunday
    
    try {
      final response = await client
          .from('schedules')
          .select('''
            *,
            classrooms:room_id (
              id,
              name,
              qr_secret
            )
          ''')
          .eq('teacher_id', currentUser!.id)
          .eq('day_of_week', dayOfWeek)
          .eq('is_active', true)
          .order('start_time');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
  
  // Get attendance history
  static Future<List<Map<String, dynamic>>> getAttendanceHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? teacherId,
  }) async {
    try {
      var queryBuilder = client
          .from('attendance_logs')
          .select('''
            *,
            classrooms:room_id (
              id,
              name
            ),
            profiles:teacher_id (
              id,
              full_name,
              nip
            )
          ''');
      
      // Apply filters
      if (teacherId != null) {
        queryBuilder = queryBuilder.eq('teacher_id', teacherId);
      }
      
      if (startDate != null) {
        // Convert ke UTC untuk query
        queryBuilder = queryBuilder.gte('scan_time', startDate.toUtc().toIso8601String());
      }
      
      if (endDate != null) {
        // Convert ke UTC untuk query
        queryBuilder = queryBuilder.lte('scan_time', endDate.toUtc().toIso8601String());
      }
      
      // Apply order and limit
      final response = await queryBuilder
          .order('scan_time', ascending: false)
          .limit(100);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting attendance history: $e');
      }
      return [];
    }
  }
  
  // Get all classrooms (Admin) - with cache
  static Future<List<Map<String, dynamic>>> getAllClassrooms({bool useCache = true}) async {
    // Try cache first
    if (useCache) {
      final cached = await CacheService.getCache('all_classrooms');
      if (cached != null) {
        return List<Map<String, dynamic>>.from(cached);
      }
    }
    
    try {
      final response = await client
          .from('classrooms')
          .select()
          .order('name');
      
      final result = List<Map<String, dynamic>>.from(response);
      
      // Cache for 5 minutes
      await CacheService.saveCache('all_classrooms', result, duration: const Duration(minutes: 5));
      
      return result;
    } catch (e) {
      return [];
    }
  }
  
  // Get all teachers (Admin) - with cache
  static Future<List<Map<String, dynamic>>> getAllTeachers({bool useCache = true}) async {
    // Try cache first
    if (useCache) {
      final cached = await CacheService.getCache('all_teachers');
      if (cached != null) {
        return List<Map<String, dynamic>>.from(cached);
      }
    }
    
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('role', 'guru')
          .order('full_name');
      
      final result = List<Map<String, dynamic>>.from(response);
      
      // Cache for 5 minutes
      await CacheService.saveCache('all_teachers', result, duration: const Duration(minutes: 5));
      
      return result;
    } catch (e) {
      return [];
    }
  }
  
  // Get all schedules (Admin) - with cache
  static Future<List<Map<String, dynamic>>> getAllSchedules({bool useCache = true}) async {
    // Try cache first
    if (useCache) {
      final cached = await CacheService.getCache('all_schedules');
      if (cached != null) {
        return List<Map<String, dynamic>>.from(cached);
      }
    }
    
    try {
      final response = await client
          .from('schedules')
          .select('''
            *,
            profiles:teacher_id (
              id,
              full_name,
              nip
            ),
            classrooms:room_id (
              id,
              name
            )
          ''')
          .order('day_of_week')
          .order('start_time');
      
      final result = List<Map<String, dynamic>>.from(response);
      
      // Cache for 5 minutes
      await CacheService.saveCache('all_schedules', result, duration: const Duration(minutes: 5));
      
      return result;
    } catch (e) {
      return [];
    }
  }
  
  // ========== CRUD Operations for Teachers ==========
  
  // Clear cache after CRUD operations
  static Future<void> _clearRelatedCache(List<String> keys) async {
    for (final key in keys) {
      await CacheService.clearCache(key);
    }
  }
  
  // Create teacher profile for existing user (Admin)
  // User harus sudah dibuat terlebih dahulu di Supabase Dashboard > Authentication > Users
  static Future<Map<String, dynamic>?> createTeacherProfile({
    required String userId, // UUID dari auth.users
    required String nip,
    required String fullName,
    int? baseSalary,
    int? hourlyRate,
    int? presenceRate,
  }) async {
    try {
      // Create profile for existing user
      final profileData = {
        'id': userId,
        'nip': nip,
        'full_name': fullName,
        'role': 'guru',
        if (baseSalary != null) 'base_salary': baseSalary,
        if (hourlyRate != null) 'hourly_rate': hourlyRate,
        if (presenceRate != null) 'presence_rate': presenceRate,
      };
      
      final response = await client
          .from('profiles')
          .insert(profileData)
          .select()
          .single();
      
      final result = response as Map<String, dynamic>;
      
      // Clear cache
      await _clearRelatedCache(['all_teachers']);
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating teacher profile: $e');
      }
      rethrow;
    }
  }
  
  // Create teacher using Edge Function (recommended method)
  // This uses Supabase Edge Function which has access to service role key
  static Future<Map<String, dynamic>?> createTeacher({
    required String email,
    required String password,
    required String nip,
    required String fullName,
    int? baseSalary,
    int? hourlyRate,
    int? presenceRate,
  }) async {
    try {
      // Call Edge Function
      final response = await client.functions.invoke(
        'create-user',
        body: {
          'email': email,
          'password': password,
          'nip': nip,
          'full_name': fullName,
          'base_salary': baseSalary ?? 0,
          'hourly_rate': hourlyRate ?? 0,
          'presence_rate': presenceRate ?? 0,
        },
      );

      if (response.status != 200) {
        final errorData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        final errorMsg = errorData['error'] ?? 'Gagal membuat user';
        final details = errorData['details'] != null ? ' (${errorData['details']})' : '';
        throw Exception('$errorMsg$details');
      }

      final result = response.data as Map<String, dynamic>;
      
      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Gagal membuat user');
      }

      // Clear cache
      await _clearRelatedCache(['all_teachers']);

      // Return profile data
      return result['profile'] as Map<String, dynamic>?;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating teacher via Edge Function: $e');
      }
      
      // If Edge Function fails, provide helpful error message
      String errorMessage = e.toString().toLowerCase();
      
      // Handle different types of errors
      if (errorMessage.contains('function not found') || 
          errorMessage.contains('404') ||
          errorMessage.contains('not found')) {
        throw Exception(
          'Edge Function belum di-deploy.\n\n'
          'Silakan deploy Edge Function terlebih dahulu:\n'
          '1. Baca file SETUP_EDGE_FUNCTION.md untuk instruksi\n'
          '2. Atau gunakan opsi "Gunakan User yang Sudah Ada"'
        );
      }
      
      if (errorMessage.contains('failed to fetch') ||
          errorMessage.contains('network') ||
          errorMessage.contains('connection') ||
          errorMessage.contains('timeout')) {
        throw Exception(
          'Gagal terhubung ke Edge Function.\n\n'
          'Kemungkinan penyebab:\n'
          '1. Edge Function belum di-deploy\n'
          '2. Masalah koneksi internet\n'
          '3. URL Supabase tidak benar\n\n'
          'Solusi:\n'
          '• Deploy Edge Function (lihat SETUP_EDGE_FUNCTION.md)\n'
          '• Atau gunakan opsi "Gunakan User yang Sudah Ada"'
        );
      }
      
      if (errorMessage.contains('unauthorized') || 
          errorMessage.contains('401') ||
          errorMessage.contains('403')) {
        throw Exception(
          'Tidak memiliki izin untuk memanggil Edge Function.\n\n'
          'Pastikan:\n'
          '1. Anon key sudah benar\n'
          '2. Edge Function sudah di-deploy dengan benar'
        );
      }
      
      // Generic error with helpful message
      throw Exception(
        'Gagal membuat user melalui Edge Function.\n\n'
        'Error: ${e.toString()}\n\n'
        'Solusi:\n'
        '1. Pastikan Edge Function sudah di-deploy\n'
        '2. Cek koneksi internet\n'
        '3. Gunakan opsi "Gunakan User yang Sudah Ada" sebagai alternatif'
      );
    }
  }
  
  // Create multiple teachers in batch
  // Returns summary with success_count, fail_count, and errors list
  static Future<Map<String, dynamic>> createTeachersBatch(
    List<Map<String, dynamic>> teachersData,
  ) async {
    int successCount = 0;
    int failCount = 0;
    final List<Map<String, dynamic>> errors = [];
    
    try {
      // Process each teacher sequentially to avoid overwhelming the server
      for (final teacherData in teachersData) {
        try {
          await createTeacher(
            email: teacherData['email'] as String,
            password: teacherData['password'] as String,
            nip: teacherData['nip'] as String,
            fullName: teacherData['full_name'] as String,
            baseSalary: teacherData['base_salary'] as int?,
            hourlyRate: teacherData['hourly_rate'] as int?,
            presenceRate: teacherData['presence_rate'] as int?,
          );
          successCount++;
        } catch (e) {
          failCount++;
          errors.add({
            'email': teacherData['email'] as String? ?? 'Unknown',
            'error': e.toString(),
          });
          
          if (kDebugMode) {
            print('Error creating teacher ${teacherData['email']}: $e');
          }
        }
      }
      
      // Clear cache after batch operation
      await _clearRelatedCache(['all_teachers']);
      
      return {
        'success_count': successCount,
        'fail_count': failCount,
        'errors': errors,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error in batch create: $e');
      }
      rethrow;
    }
  }
  
  // Get user by email (to find existing user ID)
  static Future<String?> getUserIdByEmail(String email) async {
    try {
      // Note: This requires admin access or a custom RPC function
      // For now, we'll return null and let user input the ID manually
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Update teacher (Admin)
  static Future<Map<String, dynamic>?> updateTeacher({
    required String id,
    String? nip,
    String? fullName,
    int? baseSalary,
    int? hourlyRate,
    int? presenceRate,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (nip != null) updateData['nip'] = nip;
      if (fullName != null) updateData['full_name'] = fullName;
      if (baseSalary != null) updateData['base_salary'] = baseSalary;
      if (hourlyRate != null) updateData['hourly_rate'] = hourlyRate;
      if (presenceRate != null) updateData['presence_rate'] = presenceRate;
      
      final response = await client
          .from('profiles')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();
      
      final result = response as Map<String, dynamic>;
      
      // Clear cache
      await _clearRelatedCache(['all_teachers', 'user_profile_$id']);
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating teacher: $e');
      }
      rethrow;
    }
  }
  
  // Delete teacher (Admin) - Note: This only deletes profile, auth user deletion requires admin API
  static Future<void> deleteTeacher(String id) async {
    try {
      await client
          .from('profiles')
          .delete()
          .eq('id', id);
      
      // Clear cache
      await _clearRelatedCache(['all_teachers', 'user_profile_$id']);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting teacher: $e');
      }
      rethrow;
    }
  }
  
  // ========== CRUD Operations for Classrooms ==========
  
  // Create classroom (Admin)
  static Future<Map<String, dynamic>?> createClassroom({
    required String name,
    required String qrSecret,
    required double latitude,
    required double longitude,
    int radiusMeter = 20,
  }) async {
    try {
      final response = await client
          .from('classrooms')
          .insert({
            'name': name,
            'qr_secret': qrSecret,
            'latitude': latitude,
            'longitude': longitude,
            'radius_meter': radiusMeter,
          })
          .select()
          .single();
      
      final result = response as Map<String, dynamic>;
      
      // Clear cache
      await _clearRelatedCache(['all_classrooms']);
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating classroom: $e');
      }
      rethrow;
    }
  }
  
  // Update classroom (Admin)
  static Future<Map<String, dynamic>?> updateClassroom({
    required int id,
    String? name,
    String? qrSecret,
    double? latitude,
    double? longitude,
    int? radiusMeter,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (qrSecret != null) updateData['qr_secret'] = qrSecret;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;
      if (radiusMeter != null) updateData['radius_meter'] = radiusMeter;
      
      final response = await client
          .from('classrooms')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();
      
      final result = response as Map<String, dynamic>;
      
      // Clear cache
      await _clearRelatedCache(['all_classrooms']);
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating classroom: $e');
      }
      rethrow;
    }
  }
  
  // Delete classroom (Admin)
  static Future<void> deleteClassroom(int id) async {
    try {
      await client
          .from('classrooms')
          .delete()
          .eq('id', id);
      
      // Clear cache
      await _clearRelatedCache(['all_classrooms']);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting classroom: $e');
      }
      rethrow;
    }
  }
  
  // ========== CRUD Operations for Schedules ==========
  
  // Check for schedule conflicts (overlapping time)
  static Future<bool> hasScheduleConflict({
    required String teacherId,
    required int roomId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    int? excludeScheduleId, // Exclude this schedule when checking (for update)
  }) async {
    try {
      // Query untuk cek conflict
      var query = client
          .from('schedules')
          .select('id, start_time, end_time')
          .eq('teacher_id', teacherId)
          .eq('room_id', roomId)
          .eq('day_of_week', dayOfWeek)
          .eq('is_active', true);
      
      // Exclude schedule tertentu jika sedang update
      if (excludeScheduleId != null) {
        query = query.neq('id', excludeScheduleId);
      }
      
      final existingSchedules = await query;
      
      if (existingSchedules.isEmpty) return false;
      
      // Parse waktu
      final newStart = _parseTime(startTime);
      final newEnd = _parseTime(endTime);
      
      // Cek overlap dengan setiap jadwal yang ada
      for (final schedule in existingSchedules) {
        final existingStart = _parseTime(schedule['start_time'] as String);
        final existingEnd = _parseTime(schedule['end_time'] as String);
        
        // Check overlap: new start < existing end AND new end > existing start
        if (newStart < existingEnd && newEnd > existingStart) {
          return true; // Conflict found
        }
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking schedule conflict: $e');
      }
      rethrow;
    }
  }
  
  // Check for duplicate schedule
  static Future<bool> hasDuplicateSchedule({
    required String teacherId,
    required int roomId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required String subject,
    int? excludeScheduleId, // Exclude this schedule when checking (for update)
  }) async {
    try {
      var query = client
          .from('schedules')
          .select('id')
          .eq('teacher_id', teacherId)
          .eq('room_id', roomId)
          .eq('day_of_week', dayOfWeek)
          .eq('start_time', startTime)
          .eq('end_time', endTime)
          .eq('subject', subject)
          .eq('is_active', true);
      
      // Exclude schedule tertentu jika sedang update
      if (excludeScheduleId != null) {
        query = query.neq('id', excludeScheduleId);
      }
      
      final duplicates = await query;
      return duplicates.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking duplicate schedule: $e');
      }
      rethrow;
    }
  }
  
  // Helper untuk parse time string ke minutes
  static int _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts.length > 1 ? int.parse(parts[1]) : 0;
    return hour * 60 + minute;
  }
  
  // Create schedule (Admin) with validation
  static Future<Map<String, dynamic>?> createSchedule({
    required String teacherId,
    required int roomId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required String subject,
    int lateToleranceMinutes = 10,
    bool isActive = true,
  }) async {
    try {
      // Validasi conflict
      final hasConflict = await hasScheduleConflict(
        teacherId: teacherId,
        roomId: roomId,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
      );
      
      if (hasConflict) {
        throw Exception(
          'Jadwal bertabrakan dengan jadwal yang sudah ada pada hari dan waktu yang sama!'
        );
      }
      
      // Validasi duplicate
      final isDuplicate = await hasDuplicateSchedule(
        teacherId: teacherId,
        roomId: roomId,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        subject: subject,
      );
      
      if (isDuplicate) {
        throw Exception(
          'Jadwal yang sama sudah ada! Silakan periksa kembali data yang akan ditambahkan.'
        );
      }
      
      final response = await client
          .from('schedules')
          .insert({
            'teacher_id': teacherId,
            'room_id': roomId,
            'day_of_week': dayOfWeek,
            'start_time': startTime,
            'end_time': endTime,
            'subject': subject,
            'late_tolerance_minutes': lateToleranceMinutes,
            'is_active': isActive,
          })
          .select()
          .single();
      
      final result = response as Map<String, dynamic>;
      
      // Clear cache
      await _clearRelatedCache(['all_schedules']);
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating schedule: $e');
      }
      rethrow;
    }
  }
  
  // Update schedule (Admin) with validation
  static Future<Map<String, dynamic>?> updateSchedule({
    required int id,
    String? teacherId,
    int? roomId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? subject,
    int? lateToleranceMinutes,
    bool? isActive,
  }) async {
    try {
      // Get current schedule data untuk validasi
      final currentSchedule = await client
          .from('schedules')
          .select()
          .eq('id', id)
          .single();
      
      final finalTeacherId = teacherId ?? currentSchedule['teacher_id'] as String;
      final finalRoomId = roomId ?? currentSchedule['room_id'] as int;
      final finalDayOfWeek = dayOfWeek ?? currentSchedule['day_of_week'] as int;
      final finalStartTime = startTime ?? currentSchedule['start_time'] as String;
      final finalEndTime = endTime ?? currentSchedule['end_time'] as String;
      final finalSubject = subject ?? currentSchedule['subject'] as String;
      
      // Validasi conflict (exclude current schedule)
      final hasConflict = await hasScheduleConflict(
        teacherId: finalTeacherId,
        roomId: finalRoomId,
        dayOfWeek: finalDayOfWeek,
        startTime: finalStartTime,
        endTime: finalEndTime,
        excludeScheduleId: id,
      );
      
      if (hasConflict) {
        throw Exception(
          'Jadwal bertabrakan dengan jadwal yang sudah ada pada hari dan waktu yang sama!'
        );
      }
      
      // Validasi duplicate (exclude current schedule)
      final isDuplicate = await hasDuplicateSchedule(
        teacherId: finalTeacherId,
        roomId: finalRoomId,
        dayOfWeek: finalDayOfWeek,
        startTime: finalStartTime,
        endTime: finalEndTime,
        subject: finalSubject,
        excludeScheduleId: id,
      );
      
      if (isDuplicate) {
        throw Exception(
          'Jadwal yang sama sudah ada! Silakan periksa kembali data yang akan diubah.'
        );
      }
      
      final updateData = <String, dynamic>{};
      if (teacherId != null) updateData['teacher_id'] = teacherId;
      if (roomId != null) updateData['room_id'] = roomId;
      if (dayOfWeek != null) updateData['day_of_week'] = dayOfWeek;
      if (startTime != null) updateData['start_time'] = startTime;
      if (endTime != null) updateData['end_time'] = endTime;
      if (subject != null) updateData['subject'] = subject;
      if (lateToleranceMinutes != null) updateData['late_tolerance_minutes'] = lateToleranceMinutes;
      if (isActive != null) updateData['is_active'] = isActive;
      
      final response = await client
          .from('schedules')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();
      
      final result = response as Map<String, dynamic>;
      
      // Clear cache
      await _clearRelatedCache(['all_schedules']);
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating schedule: $e');
      }
      rethrow;
    }
  }
  
  // Delete schedule (Admin)
  static Future<void> deleteSchedule(int id) async {
    try {
      await client
          .from('schedules')
          .delete()
          .eq('id', id);
      
      // Clear cache
      await _clearRelatedCache(['all_schedules']);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting schedule: $e');
      }
      rethrow;
    }
  }
  
  // Create multiple schedules in batch (Admin) with validation
  static Future<List<Map<String, dynamic>>> createSchedulesBatch({
    required String teacherId,
    required int roomId,
    required List<int> daysOfWeek, // List of day numbers (1-7)
    required String startTime,
    required String endTime,
    required String subject,
    int lateToleranceMinutes = 10,
    bool isActive = true,
  }) async {
    try {
      // Validasi semua jadwal sebelum insert
      final List<String> conflicts = [];
      final List<String> duplicates = [];
      
      for (final day in daysOfWeek) {
        // Check conflict
        final hasConflict = await hasScheduleConflict(
          teacherId: teacherId,
          roomId: roomId,
          dayOfWeek: day,
          startTime: startTime,
          endTime: endTime,
        );
        
        if (hasConflict) {
          final dayNames = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
          conflicts.add(dayNames[day]);
        }
        
        // Check duplicate
        final isDuplicate = await hasDuplicateSchedule(
          teacherId: teacherId,
          roomId: roomId,
          dayOfWeek: day,
          startTime: startTime,
          endTime: endTime,
          subject: subject,
        );
        
        if (isDuplicate) {
          final dayNames = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
          duplicates.add(dayNames[day]);
        }
      }
      
      // Throw error jika ada conflict atau duplicate
      if (conflicts.isNotEmpty) {
        throw Exception(
          'Jadwal bertabrakan pada hari: ${conflicts.join(', ')}. Silakan periksa kembali.'
        );
      }
      
      if (duplicates.isNotEmpty) {
        throw Exception(
          'Jadwal duplikat ditemukan pada hari: ${duplicates.join(', ')}. Silakan periksa kembali.'
        );
      }
      
      // Prepare batch data
      final batchData = daysOfWeek.map((day) => {
        'teacher_id': teacherId,
        'room_id': roomId,
        'day_of_week': day,
        'start_time': startTime,
        'end_time': endTime,
        'subject': subject,
        'late_tolerance_minutes': lateToleranceMinutes,
        'is_active': isActive,
      }).toList();
      
      // Insert all at once
      final response = await client
          .from('schedules')
          .insert(batchData)
          .select();
      
      final results = (response as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
      
      // Clear cache
      await _clearRelatedCache(['all_schedules']);
      
      return results;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating batch schedules: $e');
      }
      rethrow;
    }
  }
  
  // Clear all cache (useful for logout)
  static Future<void> clearAllCache() async {
    await CacheService.clearAllCache();
  }
}

