class User {
  final int id;
  final String name;
  final String email;
  final String avatar;
  final String displayName;
  final DateTime registeredDate;
  final List<int> enrolledCourses;
  final int completedCourses;
  final int inProgressCourses;
  final int certificates;
  final String role;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.displayName,
    required this.registeredDate,
    required this.enrolledCourses,
    this.completedCourses = 0,
    this.inProgressCourses = 0,
    this.certificates = 0,
    this.role = 'student',
  });

  List<String> get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return [];
    if (parts.length == 1) return [parts[0][0].toUpperCase()];
    return [
      parts.first[0].toUpperCase(),
      parts.last[0].toUpperCase(),
    ];
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      registeredDate: json['registeredDate'] != null
          ? DateTime.tryParse(json['registeredDate'] as String) ??
              DateTime.now()
          : DateTime.now(),
      enrolledCourses: (json['enrolledCourses'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      completedCourses: json['completedCourses'] as int? ?? 0,
      inProgressCourses: json['inProgressCourses'] as int? ?? 0,
      certificates: json['certificates'] as int? ?? 0,
      role: json['role'] as String? ?? 'student',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'displayName': displayName,
      'registeredDate': registeredDate.toIso8601String(),
      'enrolledCourses': enrolledCourses,
      'completedCourses': completedCourses,
      'inProgressCourses': inProgressCourses,
      'certificates': certificates,
      'role': role,
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? avatar,
    String? displayName,
    DateTime? registeredDate,
    List<int>? enrolledCourses,
    int? completedCourses,
    int? inProgressCourses,
    int? certificates,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      displayName: displayName ?? this.displayName,
      registeredDate: registeredDate ?? this.registeredDate,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
      completedCourses: completedCourses ?? this.completedCourses,
      inProgressCourses: inProgressCourses ?? this.inProgressCourses,
      certificates: certificates ?? this.certificates,
      role: role ?? this.role,
    );
  }
}
