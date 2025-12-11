import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'supabase_client.dart';
import '../widgets/professional_dialogs.dart';

/// Manager untuk mengelola session timeout
class SessionManager {
  static Timer? _inactivityTimer;
  static DateTime? _lastActivityTime;
  static const Duration _timeoutDuration = Duration(minutes: 30);
  static BuildContext? _context;
  
  /// Initialize session manager
  static void initialize(BuildContext context) {
    _context = context;
    _resetTimer();
  }
  
  /// Reset timer ketika ada aktivitas user
  static void resetTimer() {
    _lastActivityTime = DateTime.now();
    _resetTimer();
  }
  
  /// Reset timer internal
  static void _resetTimer() {
    _inactivityTimer?.cancel();
    
    _inactivityTimer = Timer(_timeoutDuration, () {
      _handleTimeout();
    });
    
    if (kDebugMode) {
      print('Session timer reset. Timeout in ${_timeoutDuration.inMinutes} minutes');
    }
  }
  
  /// Handle session timeout
  static Future<void> _handleTimeout() async {
    if (kDebugMode) {
      print('Session timeout detected. Logging out...');
    }
    
    // Check if user is still authenticated
    if (!SupabaseService.isAuthenticated) {
      return;
    }
    
    // Show warning dialog
    if (_context != null && _context!.mounted) {
      final shouldLogout = await ProfessionalDialogs.showConfirmDialog(
        context: _context!,
        title: 'Sesi Kedaluwarsa',
        message: 'Anda tidak aktif selama 30 menit. Sesi akan berakhir untuk keamanan akun Anda.',
        confirmText: 'OK',
        cancelText: 'Batal',
        confirmColor: Colors.orange,
      );
      
      if (shouldLogout && _context != null && _context!.mounted) {
        await _performLogout();
      } else {
        // User cancelled, reset timer
        resetTimer();
      }
    } else {
      // No context, just logout
      await _performLogout();
    }
  }
  
  /// Perform logout
  static Future<void> _performLogout() async {
    try {
      await SupabaseService.signOut();
      
      if (_context != null && _context!.mounted) {
        // Navigate to login
        Navigator.of(_context!).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
        
        ProfessionalDialogs.showProfessionalSnackBar(
          context: _context!,
          message: 'Sesi telah berakhir karena tidak aktif selama 30 menit',
          type: SnackBarType.info,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during auto-logout: $e');
      }
    }
  }
  
  /// Get remaining time until timeout
  static Duration? getRemainingTime() {
    if (_lastActivityTime == null) return null;
    final elapsed = DateTime.now().difference(_lastActivityTime!);
    final remaining = _timeoutDuration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }
  
  /// Dispose session manager
  static void dispose() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _lastActivityTime = null;
    _context = null;
  }
}

/// Widget untuk track user activity
class ActivityTracker extends StatefulWidget {
  final Widget child;
  
  const ActivityTracker({
    super.key,
    required this.child,
  });
  
  @override
  State<ActivityTracker> createState() => _ActivityTrackerState();
}

class _ActivityTrackerState extends State<ActivityTracker> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SessionManager.initialize(context);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App resumed, reset timer
      SessionManager.resetTimer();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => SessionManager.resetTimer(),
      onPointerMove: (_) => SessionManager.resetTimer(),
      child: GestureDetector(
        onTap: () => SessionManager.resetTimer(),
        onPanUpdate: (_) => SessionManager.resetTimer(),
        child: widget.child,
      ),
    );
  }
}

