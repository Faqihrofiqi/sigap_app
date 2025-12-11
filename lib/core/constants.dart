class AppConstants {
  // App Info
  static const String appName = 'SIGAP';
  static const String appVersion = '1.0.0';
  
  // Scan Types
  static const String scanTypeCheckInSchool = 'CHECK_IN_SCHOOL';
  static const String scanTypeStartTeaching = 'START_TEACHING';
  static const String scanTypeEndTeaching = 'END_TEACHING';
  
  // Attendance Status
  static const String statusOnTime = 'ON_TIME';
  static const String statusLate = 'LATE';
  static const String statusValid = 'VALID';
  
  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleGuru = 'guru';
  
  // Storage Keys
  static const String keyIsDarkMode = 'is_dark_mode';
  static const String keyUserRole = 'user_role';
  static const String keyLastLocation = 'last_location';
  
  // Error Messages
  static const String errorNoInternet = 'Tidak ada koneksi internet';
  static const String errorLocationDenied = 'Izin lokasi ditolak';
  static const String errorCameraDenied = 'Izin kamera ditolak';
  static const String errorMockLocation = 'Mock Location terdeteksi! Aplikasi tidak dapat digunakan dengan Mock Location aktif.';
  static const String errorQRInvalid = 'QR Code tidak valid';
  static const String errorLocationTooFar = 'Lokasi terlalu jauh dari titik scan';
  
  // Success Messages
  static const String successAttendanceRecorded = 'Presensi berhasil dicatat!';
  static const String successLogin = 'Login berhasil';
  static const String successLogout = 'Logout berhasil';
  
  // Default Values
  static const double defaultRadiusMeter = 20.0;
  static const int defaultPresenceRate = 50000; // Rp 50.000 per hari
  static const int defaultHourlyRate = 50000; // Rp 50.000 per jam
}

