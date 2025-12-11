import 'package:flutter/material.dart';
import '../../core/supabase_client.dart';
import '../../widgets/professional_dialogs.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      await SupabaseService.resetPassword(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _emailSent = true;
      });

      await ProfessionalDialogs.showSuccessDialog(
        context: context,
        title: 'Email Terkirim',
        message:
            'Link reset password telah dikirim ke email ${_emailController.text.trim()}.\n\n'
            'Silakan cek inbox email Anda dan ikuti instruksi untuk reset password.',
        buttonText: 'OK',
      );
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Gagal mengirim email reset password';
      
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('not found') || errorString.contains('user')) {
        errorMessage = 'Email tidak ditemukan dalam sistem';
      } else if (errorString.contains('rate limit') || errorString.contains('too many')) {
        errorMessage = 'Terlalu banyak permintaan. Silakan coba lagi nanti';
      } else {
        errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      }

      await ProfessionalDialogs.showErrorDialog(
        context: context,
        title: 'Gagal',
        message: errorMessage,
      );
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
        title: const Text('Lupa Password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset,
                  size: 50,
                  color: Colors.blue,
                ),
              ),

              // Title
              const Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                _emailSent
                    ? 'Email reset password telah dikirim. Silakan cek inbox email Anda.'
                    : 'Masukkan email Anda untuk menerima link reset password',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              if (!_emailSent) ...[
                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleResetPassword(),
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email_outlined),
                    helperText: 'Email yang terdaftar di sistem',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email wajib diisi';
                    }
                    if (!value.contains('@')) {
                      return 'Email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
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
                          'Kirim Link Reset Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ] else ...[
                // Success State
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Email telah dikirim ke:',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _emailController.text.trim(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _emailSent = false;
                      _emailController.clear();
                    });
                  },
                  child: const Text('Kirim Ulang Email'),
                ),
              ],

              const SizedBox(height: 24),

              // Back to Login
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali ke Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

