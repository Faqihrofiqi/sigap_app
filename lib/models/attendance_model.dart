import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart';
import 'classroom_model.dart';
import 'user_model.dart';

class AttendanceModel {
  final int id;
  final String teacherId;
  final int roomId;
  final DateTime scanTime;
  final String scanType;
  final String status;
  final int? lateMinutes; // Menit terlambat (null jika tidak terlambat)
  final double gpsLat;
  final double gpsLong;
  final double? distanceMeters;
  final DateTime? createdAt;
  
  // Relations
  ClassroomModel? classroom;
  UserModel? teacher;
  
  AttendanceModel({
    required this.id,
    required this.teacherId,
    required this.roomId,
    required this.scanTime,
    required this.scanType,
    required this.status,
    this.lateMinutes,
    required this.gpsLat,
    required this.gpsLong,
    this.distanceMeters,
    this.createdAt,
    this.classroom,
    this.teacher,
  });
  
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    // Parse scan_time dari Supabase
    // Supabase menyimpan TIMESTAMP WITH TIME ZONE dalam UTC
    // Format yang dikembalikan: "2025-12-09T07:59:00.000Z" (UTC untuk 14:59 WIB)
    // Kita perlu convert ke WIB (UTC+7) untuk tampilan
    DateTime scanTime;
    try {
      final timeStr = json['scan_time'] as String;
      
      // Debug: log format waktu yang diterima (untuk troubleshooting)
      if (kDebugMode) {
        print('DEBUG scan_time format: $timeStr');
      }
      
      // Parse timestamp
      final parsedTime = DateTime.parse(timeStr);
      
      // Supabase mengembalikan timestamp dalam UTC (berakhir dengan 'Z')
      // Format: "2025-12-09T07:59:00.000Z" (UTC untuk 14:59 WIB)
      // Convert ke WIB (UTC+7) untuk tampilan
      if (timeStr.endsWith('Z')) {
        // Waktu dalam UTC, convert ke WIB (UTC+7)
        final utcTime = parsedTime.toUtc();
        scanTime = utcTime.add(const Duration(hours: 7));
        
        if (kDebugMode) {
          print('DEBUG: UTC ${utcTime.hour.toString().padLeft(2, '0')}:${utcTime.minute.toString().padLeft(2, '0')} -> WIB ${scanTime.hour.toString().padLeft(2, '0')}:${scanTime.minute.toString().padLeft(2, '0')}');
        }
      } else if (parsedTime.isUtc) {
        // Jika isUtc = true, convert ke WIB
        scanTime = parsedTime.add(const Duration(hours: 7));
      } else {
        // Waktu sudah dalam timezone tertentu (bukan UTC)
        // Cek apakah sudah dalam WIB (+07:00)
        if (timeStr.contains('+07:00') || timeStr.contains('+07')) {
          // Sudah dalam WIB, langsung pakai tanpa convert
          scanTime = parsedTime;
        } else {
          // Format tanpa timezone info
          // JANGAN convert - langsung pakai waktu yang dikembalikan
          // Supabase Flutter client mungkin sudah convert ke timezone device
          scanTime = parsedTime;
          
          if (kDebugMode) {
            print('DEBUG: Non-UTC format, using as-is: ${scanTime.hour.toString().padLeft(2, '0')}:${scanTime.minute.toString().padLeft(2, '0')}');
          }
        }
      }
      
      // Pastikan sebagai local time untuk display (bukan UTC)
      scanTime = DateTime(
        scanTime.year,
        scanTime.month,
        scanTime.day,
        scanTime.hour,
        scanTime.minute,
        scanTime.second,
      );
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error parsing scan_time: $e');
      }
      // Fallback ke waktu sekarang jika parsing gagal
      scanTime = DateTime.now();
    }
    
    return AttendanceModel(
      id: (json['id'] as num).toInt(),
      teacherId: json['teacher_id'] as String? ?? '',
      roomId: (json['room_id'] as num?)?.toInt() ?? 0,
      scanTime: scanTime,
      scanType: json['scan_type'] as String? ?? 'CHECK_IN_SCHOOL',
      status: json['status'] as String? ?? 'VALID',
      lateMinutes: (json['late_minutes'] as num?)?.toInt(),
      gpsLat: (json['gps_lat'] as num?)?.toDouble() ?? 0.0,
      gpsLong: (json['gps_long'] as num?)?.toDouble() ?? 0.0,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      classroom: json['classrooms'] != null
          ? ClassroomModel.fromJson(json['classrooms'] as Map<String, dynamic>)
          : null,
      teacher: json['profiles'] != null
          ? UserModel.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'room_id': roomId,
      'scan_time': scanTime.toIso8601String(),
      'scan_type': scanType,
      'status': status,
      'late_minutes': lateMinutes,
      'gps_lat': gpsLat,
      'gps_long': gpsLong,
      'distance_meters': distanceMeters,
      'created_at': createdAt?.toIso8601String(),
    };
  }
  
  String get scanTypeLabel {
    switch (scanType) {
      case 'CHECK_IN_SCHOOL':
        return 'Masuk Sekolah';
      case 'START_TEACHING':
        return 'Mulai Mengajar';
      case 'END_TEACHING':
        return 'Selesai Mengajar';
      default:
        return scanType;
    }
  }
  
  String get statusLabel {
    switch (status) {
      case 'ON_TIME':
        return 'Tepat Waktu';
      case 'LATE':
        if (lateMinutes != null) {
          return 'Terlambat ($lateMinutes menit)';
        }
        return 'Terlambat';
      case 'VALID':
        return 'Valid';
      default:
        return status;
    }
  }
  
  bool get isOnTime => status == 'ON_TIME';
  bool get isLate => status == 'LATE';
  bool get isValid => status == 'VALID';
}

