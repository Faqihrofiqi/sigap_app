import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/qr_scanner_view.dart';
import '../../widgets/professional_dialogs.dart';

class QRScannerScreen extends StatelessWidget {
  const QRScannerScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return QRScannerView(
      scanType: AppConstants.scanTypeCheckInSchool,
      onScanResult: (result) {
        Navigator.pop(context);
        
        final status = result['status'] as String?;
        final message = result['message'] as String? ?? 'Unknown error';
        
        if (status == 'success') {
          ProfessionalDialogs.showProfessionalSnackBar(
            context: context,
            message: message,
            type: SnackBarType.success,
            duration: const Duration(seconds: 3),
          );
        } else {
          ProfessionalDialogs.showProfessionalSnackBar(
            context: context,
            message: message,
            type: SnackBarType.error,
            duration: const Duration(seconds: 4),
          );
        }
      },
    );
  }
}

