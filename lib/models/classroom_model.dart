class ClassroomModel {
  final int id;
  final String name;
  final String qrSecret;
  final double latitude;
  final double longitude;
  final int radiusMeter;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  ClassroomModel({
    required this.id,
    required this.name,
    required this.qrSecret,
    required this.latitude,
    required this.longitude,
    this.radiusMeter = 20,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });
  
  factory ClassroomModel.fromJson(Map<String, dynamic> json) {
    return ClassroomModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      qrSecret: json['qr_secret'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      radiusMeter: (json['radius_meter'] as num?)?.toInt() ?? 20,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'qr_secret': qrSecret,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meter': radiusMeter,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

