import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase_client.dart';
import 'core/app_theme.dart';
import 'core/session_manager.dart';
import 'core/config.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  try {
    await dotenv.load(fileName: '.env');
    if (kDebugMode) {
      print('✅ Environment variables loaded from .env file');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Could not load .env file: $e');
      print('   Using compile-time environment variables or defaults');
    }
  }
  
  // Initialize Supabase using environment variables
  final supabaseUrl = AppConfig.supabaseUrl;
  final supabaseAnonKey = AppConfig.supabaseAnonKey;
  
  // Validate configuration
  if (!AppConfig.isValid) {
    final error = AppConfig.validationError;
    if (kDebugMode) {
      print('❌ ERROR: Supabase configuration is invalid!');
      print('   $error');
      print('');
      print('📝 Setup Instructions:');
      print('   1. Copy .env.example to .env');
      print('   2. Update .env with your Supabase credentials');
      print('   3. Get credentials from: https://app.supabase.com/project/_/settings/api');
    }
    // Still run the app, but Supabase won't work
    // User will see error when trying to login
  } else {
    try {
      await SupabaseService.initialize(
        supabaseUrl: supabaseUrl,
        supabaseAnonKey: supabaseAnonKey,
      );
      if (kDebugMode) {
        print('✅ Supabase initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Supabase: $e');
      }
    }
  }
  
  runApp(const SIGAPApp());
}

class SIGAPApp extends StatelessWidget {
  const SIGAPApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIGAP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: ActivityTracker(
        child: const SplashScreen(),
      ),
      routes: {
        '/login': (context) => ActivityTracker(
          child: const LoginScreen(),
        ),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  
  @override
  void initState() {
    super.initState();
    _checkAuth();
    _setupAuthListener();
  }
  
  void _setupAuthListener() {
    // Listen to auth state changes
    try {
      SupabaseService.client.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;
        
        if (kDebugMode) {
          print('Auth state changed: $event');
        }
        
        if (mounted) {
          setState(() {
            _isAuthenticated = session != null;
          });
        }
        
        // Handle session expiration
        if (event == AuthChangeEvent.signedOut || session == null) {
          if (mounted) {
            // Clear cache when signed out
            SupabaseService.clearAllCache();
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error setting up auth listener: $e');
      }
    }
  }
  
  Future<void> _checkAuth() async {
    // Check if user is already authenticated
    try {
      final isAuth = SupabaseService.isAuthenticated;
      
      // If authenticated, check if session is expiring and refresh if needed
      if (isAuth && SupabaseService.isSessionExpiring) {
        try {
          await SupabaseService.refreshSession();
          if (kDebugMode) {
            print('Session refreshed successfully');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error refreshing session: $e');
          }
          // If refresh fails, user might need to login again
          await SupabaseService.signOut();
        }
      }
      
      _isAuthenticated = SupabaseService.isAuthenticated;
    } catch (e) {
      // Supabase not initialized yet, show login screen
      _isAuthenticated = false;
      if (kDebugMode) {
        print('Supabase not initialized: $e');
      }
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_isAuthenticated) {
      // User is authenticated, check role and navigate accordingly
      // This will be handled by the login screen after successful login
      // For now, redirect to login to handle navigation
      return const LoginScreen();
    }
    
    return const LoginScreen();
  }
}
