enum ProgressStatus { notStarted, inProgress, completed }

class CourseProgress {
  final int courseId;
  final String courseTitle;
  final int totalItems;
  final int completedItems;
  final double percentage;
  final DateTime? lastAccessed;
  final ProgressStatus status;

  const CourseProgress({
    required this.courseId,
    required this.courseTitle,
    required this.totalItems,
    required this.completedItems,
    required this.percentage,
    this.lastAccessed,
    required this.status,
  });

  bool get isCompleted => status == ProgressStatus.completed;
  bool get isInProgress => status == ProgressStatus.inProgress;

  factory CourseProgress.fromJson(Map<String, dynamic> json) {
    return CourseProgress(
      courseId: json['courseId'] as int? ?? 0,
      courseTitle: json['courseTitle'] as String? ?? '',
      totalItems: json['totalItems'] as int? ?? 0,
      completedItems: json['completedItems'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      lastAccessed: json['lastAccessed'] != null
          ? DateTime.tryParse(json['lastAccessed'] as String)
          : null,
      status: _parseProgressStatus(json['status'] as String? ?? 'notStarted'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'courseTitle': courseTitle,
      'totalItems': totalItems,
      'completedItems': completedItems,
      'percentage': percentage,
      'lastAccessed': lastAccessed?.toIso8601String(),
      'status': status.name,
    };
  }

  static ProgressStatus _parseProgressStatus(String status) {
    switch (status.toLowerCase()) {
      case 'inprogress':
        return ProgressStatus.inProgress;
      case 'completed':
        return ProgressStatus.completed;
      case 'notstarted':
      default:
        return ProgressStatus.notStarted;
    }
  }
}

class LessonProgress {
  final int lessonId;
  final bool isCompleted;
  final String duration;
  final DateTime? completedAt;

  const LessonProgress({
    required this.lessonId,
    required this.isCompleted,
    required this.duration,
    this.completedAt,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    return LessonProgress(
      lessonId: json['lessonId'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      duration: json['duration'] as String? ?? '',
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'isCompleted': isCompleted,
      'duration': duration,
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
