import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/constants.dart';
import 'location_checker.dart';
import '../core/supabase_client.dart';
import 'server_time_display.dart';

class QRScannerView extends StatefulWidget {
  final String scanType;
  final Function(Map<String, dynamic>) onScanResult;
  
  const QRScannerView({
    super.key,
    this.scanType = AppConstants.scanTypeCheckInSchool,
    required this.onScanResult,
  });
  
  @override
  State<QRScannerView> createState() => _QRScannerViewState();
}

class _QRScannerViewState extends State<QRScannerView> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _isProcessing = false;
  String? _lastScannedCode;
  Timer? _debounceTimer;
  bool _isDisposed = false;
  
  @override
  void initState() {
    super.initState();
    // Start camera
    _controller.start();
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }
  
  Future<void> _processQRCode(String? code) async {
    if (code == null || code.isEmpty) return;
    
    // Prevent duplicate scans
    if (_lastScannedCode == code && _isProcessing) return;
    _lastScannedCode = code;
    
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    // Debounce: wait 2 seconds before processing again
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _lastScannedCode = null;
    });
    
    try {
      // Get current location
      final position = await LocationChecker.getCurrentPosition();
      
      if (position == null) {
        widget.onScanResult({
          'status': 'error',
          'message': 'Gagal mendapatkan lokasi. Pastikan GPS aktif dan izin lokasi diberikan.',
        });
        setState(() {
          _isProcessing = false;
        });
        return;
      }
      
      // Submit attendance to Supabase
      final result = await SupabaseService.submitAttendance(
        qrSecret: code,
        latitude: position.latitude,
        longitude: position.longitude,
        scanType: widget.scanType,
      );
      
      widget.onScanResult(result);
    } catch (e) {
      widget.onScanResult({
        'status': 'error',
        'message': 'Terjadi kesalahan: ${e.toString()}',
      });
    } finally {
      if (!_isDisposed && mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: ServerTimeDisplay(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_isDisposed) return;
              
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && !_isProcessing && !_isDisposed) {
                  _processQRCode(barcode.rawValue);
                }
              }
            },
            errorBuilder: (context, error, child) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Scan QR Code'),
                  backgroundColor: Colors.black,
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${error.toString()}',
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          _controller.start();
                          setState(() {});
                        },
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Overlay with scanning area
          CustomPaint(
            painter: ScannerOverlay(),
            child: Container(),
          ),
          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Memproses...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          // Instructions
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Arahkan kamera ke QR Code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for scanner overlay
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final scanArea = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: size.width * 0.7,
            height: size.width * 0.7,
          ),
          const Radius.circular(20),
        ),
      );
    
    final scanPath = Path.combine(
      PathOperation.difference,
      path,
      scanArea,
    );
    
    canvas.drawPath(scanPath, paint);
    
    // Draw corner borders
    final borderPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    
    final cornerLength = 30.0;
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.7,
      height: size.width * 0.7,
    );
    
    // Top-left corner
    canvas.drawLine(
      scanRect.topLeft,
      scanRect.topLeft + Offset(cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanRect.topLeft,
      scanRect.topLeft + Offset(0, cornerLength),
      borderPaint,
    );
    
    // Top-right corner
    canvas.drawLine(
      scanRect.topRight,
      scanRect.topRight + Offset(-cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanRect.topRight,
      scanRect.topRight + Offset(0, cornerLength),
      borderPaint,
    );
    
    // Bottom-left corner
    canvas.drawLine(
      scanRect.bottomLeft,
      scanRect.bottomLeft + Offset(cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanRect.bottomLeft,
      scanRect.bottomLeft + Offset(0, -cornerLength),
      borderPaint,
    );
    
    // Bottom-right corner
    canvas.drawLine(
      scanRect.bottomRight,
      scanRect.bottomRight + Offset(-cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanRect.bottomRight,
      scanRect.bottomRight + Offset(0, -cornerLength),
      borderPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

