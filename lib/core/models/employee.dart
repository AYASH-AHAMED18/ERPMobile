enum EmployeeWorkStatus {
  atWork('At work'),
  onLeave('On leave'),
  offline('Offline'),
  remote('Remote');

  const EmployeeWorkStatus(this.label);
  final String label;
}

class Employee {
  const Employee({
    required this.id,
    required this.employeeCode,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    required this.designation,
    this.avatarUrl,
    this.workStatus = EmployeeWorkStatus.atWork,
    this.role = 'Employee',
    this.joinedAt,
    this.location,
    this.checkedInAt,
    this.checkedOutAt,
    this.noticePostingAllowed,
  });

  final String id;
  final String employeeCode;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String designation;
  final String? avatarUrl;
  final EmployeeWorkStatus workStatus;
  final String role;
  final DateTime? joinedAt;
  final String? location;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final bool? noticePostingAllowed;

  bool get isCurrentlyCheckedIn =>
      checkedOutAt == null &&
      (checkedInAt != null || workStatus == EmployeeWorkStatus.atWork);

  bool get canPostNotices {
    if (noticePostingAllowed != null) return noticePostingAllowed!;
    final value = role.toLowerCase();
    return value.contains('admin') ||
        value.contains('hr') ||
        value.contains('manager') ||
        value.contains('director') ||
        department.toLowerCase() == 'human resources';
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Employee copyWith({
    String? name,
    String? email,
    String? phone,
    String? department,
    String? designation,
    String? avatarUrl,
    EmployeeWorkStatus? workStatus,
    String? location,
    DateTime? checkedInAt,
    DateTime? checkedOutAt,
    bool? noticePostingAllowed,
  }) {
    return Employee(
      id: id,
      employeeCode: employeeCode,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      workStatus: workStatus ?? this.workStatus,
      role: role,
      joinedAt: joinedAt,
      location: location ?? this.location,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      checkedOutAt: checkedOutAt ?? this.checkedOutAt,
      noticePostingAllowed: noticePostingAllowed ?? this.noticePostingAllowed,
    );
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'].toString(),
      employeeCode: (json['employee_code'] ?? json['employeeCode'] ?? '')
          .toString(),
      name: (json['name'] ?? json['full_name'] ?? 'Employee').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      department: (json['department'] ?? 'General').toString(),
      designation: (json['designation'] ?? json['position'] ?? '').toString(),
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl'])?.toString(),
      role: (json['role'] ?? 'Employee').toString(),
      location: json['location']?.toString(),
      joinedAt: DateTime.tryParse(
        (json['joined_at'] ?? json['joinedAt'] ?? '').toString(),
      ),
      workStatus: _statusFrom(json['work_status'] ?? json['workStatus']),
      checkedInAt: DateTime.tryParse(
        (json['checked_in_at'] ?? json['check_in'] ?? json['check_in_at'] ?? '')
            .toString(),
      ),
      checkedOutAt: DateTime.tryParse(
        (json['checked_out_at'] ??
                json['check_out'] ??
                json['check_out_at'] ??
                '')
            .toString(),
      ),
      noticePostingAllowed:
          _boolOrNull(json['can_post_notices']) ??
          _permissionFlag(json['permissions'], 'notices.create'),
    );
  }

  static bool? _boolOrNull(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    return null;
  }

  static bool? _permissionFlag(dynamic value, String permission) {
    if (value is! List) return null;
    return value.any((item) => item.toString() == permission) ? true : null;
  }

  static EmployeeWorkStatus _statusFrom(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'on_leave':
      case 'on leave':
        return EmployeeWorkStatus.onLeave;
      case 'offline':
        return EmployeeWorkStatus.offline;
      case 'remote':
        return EmployeeWorkStatus.remote;
      default:
        return EmployeeWorkStatus.atWork;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employee_code': employeeCode,
    'name': name,
    'email': email,
    'phone': phone,
    'department': department,
    'designation': designation,
    'avatar_url': avatarUrl,
    'role': role,
    'location': location,
    'work_status': workStatus.name,
    'checked_in_at': checkedInAt?.toIso8601String(),
    'checked_out_at': checkedOutAt?.toIso8601String(),
    'can_post_notices': noticePostingAllowed,
  };
}
