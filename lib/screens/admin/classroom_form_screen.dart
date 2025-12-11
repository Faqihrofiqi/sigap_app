import 'package:flutter/material.dart';
import '../../core/supabase_client.dart';
import '../../models/classroom_model.dart';

class ClassroomFormScreen extends StatefulWidget {
  final ClassroomModel? classroom; // null = add, not null = edit
  
  const ClassroomFormScreen({super.key, this.classroom});
  
  @override
  State<ClassroomFormScreen> createState() => _ClassroomFormScreenState();
}

class _ClassroomFormScreenState extends State<ClassroomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _qrSecretController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _radiusController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEditMode = false;
  
  @override
  void initState() {
    super.initState();
    _isEditMode = widget.classroom != null;
    
    if (_isEditMode) {
      final classroom = widget.classroom!;
      _nameController.text = classroom.name;
      _qrSecretController.text = classroom.qrSecret;
      _latitudeController.text = classroom.latitude.toString();
      _longitudeController.text = classroom.longitude.toString();
      _radiusController.text = classroom.radiusMeter.toString();
    } else {
      _radiusController.text = '20'; // Default radius
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _qrSecretController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _radiusController.dispose();
    super.dispose();
  }
  
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    FocusScope.of(context).unfocus();
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final latitude = double.tryParse(_latitudeController.text);
      final longitude = double.tryParse(_longitudeController.text);
      final radius = int.tryParse(_radiusController.text) ?? 20;
      
      if (latitude == null || longitude == null) {
        throw Exception('Latitude dan Longitude harus berupa angka');
      }
      
      if (_isEditMode) {
        // Update existing classroom
        await SupabaseService.updateClassroom(
          id: widget.classroom!.id,
          name: _nameController.text.trim(),
          qrSecret: _qrSecretController.text.trim(),
          latitude: latitude,
          longitude: longitude,
          radiusMeter: radius,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data ruangan berhasil diperbarui'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Create new classroom
        await SupabaseService.createClassroom(
          name: _nameController.text.trim(),
          qrSecret: _qrSecretController.text.trim(),
          latitude: latitude,
          longitude: longitude,
          radiusMeter: radius,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ruangan baru berhasil ditambahkan'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
        title: Text(_isEditMode ? 'Edit Ruangan' : 'Tambah Ruangan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Ruangan *',
                  prefixIcon: Icon(Icons.room_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama ruangan wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // QR Secret
              TextFormField(
                controller: _qrSecretController,
                decoration: const InputDecoration(
                  labelText: 'QR Secret *',
                  prefixIcon: Icon(Icons.qr_code),
                  helperText: 'String unik untuk QR code (contoh: SECURE-ROOM-7A-V1)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'QR Secret wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Latitude
              TextFormField(
                controller: _latitudeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Latitude *',
                  prefixIcon: Icon(Icons.location_on),
                  helperText: 'Koordinat lintang (contoh: -6.123456)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Latitude wajib diisi';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Latitude harus berupa angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Longitude
              TextFormField(
                controller: _longitudeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Longitude *',
                  prefixIcon: Icon(Icons.location_on),
                  helperText: 'Koordinat bujur (contoh: 106.123456)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Longitude wajib diisi';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Longitude harus berupa angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Radius
              TextFormField(
                controller: _radiusController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Radius (meter) *',
                  prefixIcon: Icon(Icons.radio_button_checked),
                  helperText: 'Toleransi jarak untuk scan (default: 20 meter)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Radius wajib diisi';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Radius harus berupa angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
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
                    : Text(
                        _isEditMode ? 'Simpan Perubahan' : 'Tambah Ruangan',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

