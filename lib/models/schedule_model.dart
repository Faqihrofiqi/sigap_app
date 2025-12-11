import 'classroom_model.dart';
import 'user_model.dart';

class ScheduleModel {
  final int id;
  final String teacherId;
  final int roomId;
  final int dayOfWeek; // 1=Senin, 7=Minggu
  final String startTime; // Format: "HH:mm:ss"
  final String endTime; // Format: "HH:mm:ss"
  final String subject;
  final int lateToleranceMinutes; // Toleransi keterlambatan dalam menit
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Relations
  ClassroomModel? classroom;
  UserModel? teacher;
  
  ScheduleModel({
    required this.id,
    required this.teacherId,
    required this.roomId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.subject,
    this.lateToleranceMinutes = 10,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.classroom,
    this.teacher,
  });
  
  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] as int,
      teacherId: json['teacher_id'] as String? ?? '',
      roomId: (json['room_id'] as num?)?.toInt() ?? 0,
      dayOfWeek: (json['day_of_week'] as num?)?.toInt() ?? 1,
      startTime: json['start_time'] as String? ?? '08:00:00',
      endTime: json['end_time'] as String? ?? '09:00:00',
      subject: json['subject'] as String? ?? '',
      lateToleranceMinutes: (json['late_tolerance_minutes'] as num?)?.toInt() ?? 10,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
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
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'subject': subject,
      'late_tolerance_minutes': lateToleranceMinutes,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
  
  String get dayName {
    const days = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return days[dayOfWeek] ?? 'Unknown';
  }
  
  String get timeRange {
    final start = startTime.substring(0, 5); // HH:mm
    final end = endTime.substring(0, 5); // HH:mm
    return '$start - $end';
  }
}

