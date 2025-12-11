class UserModel {
  final String id;
  final String nip;
  final String fullName;
  final String role;
  final int baseSalary;
  final int hourlyRate;
  final int presenceRate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  UserModel({
    required this.id,
    required this.nip,
    required this.fullName,
    required this.role,
    this.baseSalary = 0,
    this.hourlyRate = 0,
    this.presenceRate = 0,
    this.createdAt,
    this.updatedAt,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      nip: json['nip'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      role: json['role'] as String? ?? 'guru',
      baseSalary: (json['base_salary'] as num?)?.toInt() ?? 0,
      hourlyRate: (json['hourly_rate'] as num?)?.toInt() ?? 0,
      presenceRate: (json['presence_rate'] as num?)?.toInt() ?? 0,
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
      'nip': nip,
      'full_name': fullName,
      'role': role,
      'base_salary': baseSalary,
      'hourly_rate': hourlyRate,
      'presence_rate': presenceRate,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
  
  bool get isAdmin => role == 'admin';
  bool get isGuru => role == 'guru';
  
  String get formattedSalary => _formatCurrency(baseSalary);
  String get formattedHourlyRate => _formatCurrency(hourlyRate);
  String get formattedPresenceRate => _formatCurrency(presenceRate);
  
  String _formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }
}

