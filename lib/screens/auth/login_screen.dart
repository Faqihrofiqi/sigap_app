import 'package:flutter/material.dart';
import '../../core/supabase_client.dart';
import '../../core/constants.dart';
import '../../models/user_model.dart';
import '../../widgets/professional_dialogs.dart';
import '../teacher/teacher_dashboard.dart';
import '../admin/admin_dashboard_modern.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // 1. Validasi Form
    if (!_formKey.currentState!.validate()) return;

    // 2. Tutup Keyboard agar UI lebih bersih saat loading
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      // 3. Proses Sign In
      final response = await SupabaseService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Cek apakah widget masih ada (mounted) setelah await
      if (!mounted) return;

      if (response.user != null) {
        // 4. Ambil Profil User untuk cek Role
        final profileData = await SupabaseService.getUserProfile();

        if (!mounted) return; // Cek mounted lagi setelah request kedua

        if (profileData != null) {
          final user = UserModel.fromJson(profileData);

          // 5. Navigasi Berdasarkan Role
          Widget nextScreen;
          if (user.isAdmin) {
            nextScreen = const AdminDashboardModern();
          } else {
            nextScreen = const TeacherDashboard();
          }

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => nextScreen),
            (route) => false,
          );
          
          // Kita tidak perlu set _isLoading = false di sini karena halaman akan berpindah
        } else {
          ProfessionalDialogs.showProfessionalSnackBar(
            context: context,
            message: 'Gagal memuat profil pengguna. Pastikan akun memiliki data profil di database.',
            type: SnackBarType.error,
          );
        }
      } else {
        ProfessionalDialogs.showProfessionalSnackBar(
          context: context,
          message: 'Email atau password salah',
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Terjadi kesalahan saat login';
        final errorString = e.toString().toLowerCase();
        
        if (errorString.contains('invalid') || errorString.contains('wrong')) {
          errorMessage = 'Email atau password salah';
        } else if (errorString.contains('network') || errorString.contains('connection')) {
          errorMessage = 'Tidak ada koneksi internet. Periksa koneksi Anda';
        } else if (errorString.contains('timeout')) {
          errorMessage = 'Waktu koneksi habis. Silakan coba lagi';
        } else {
          errorMessage = 'Terjadi kesalahan: ${e.toString()}';
        }
        
        ProfessionalDialogs.showProfessionalSnackBar(
          context: context,
          message: errorMessage,
          type: SnackBarType.error,
        );
      }
    } finally {
      // 6. Reset loading state HANYA jika widget masih ada
      // dan kemungkinan besar user masih di halaman login (karena error)
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
              Theme.of(context).colorScheme.tertiary ?? Theme.of(context).colorScheme.primary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20), // Sedikit penyesuaian spasi
                    
                    // --- Logo Section ---
                    Image.asset(
                      'assets/images/mainlogo.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 32),

                   

                    // --- Form Card Section ---
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next, // Pindah ke password saat enter
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Email tidak boleh kosong';
                                }
                                if (!value.contains('@')) {
                                  return 'Email tidak valid';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done, // Submit saat enter
                              onFieldSubmitted: (_) => _handleLogin(), // Shortcut submit
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: Colors.grey[600],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password tidak boleh kosong';
                                }
                                if (value.length < 6) {
                                  return 'Password minimal 6 karakter';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),

                            // Login Button
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isLoading ? null : _handleLogin,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    alignment: Alignment.center,
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            'Masuk',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Forgot Password Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Lupa Password?'),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Info Text
                            Text(
                              'Gunakan email dan password yang telah diberikan',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}