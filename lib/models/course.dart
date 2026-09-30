enum CurriculumItemType { lesson, quiz }

class Course {
  final int id;
  final String title;
  final String description;
  final String shortDescription;
  final String thumbnail;
  final double price;
  final double salePrice;
  final String duration;
  final Instructor instructor;
  final double rating;
  final int ratingCount;
  final int studentsCount;
  final int lessonsCount;
  final int quizzesCount;
  final List<String> categories;
  final List<String> tags;
  final List<CurriculumSection> curriculum;
  final bool isEnrolled;
  final double progress;
  final bool isWishlisted;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.shortDescription,
    required this.thumbnail,
    required this.price,
    required this.salePrice,
    required this.duration,
    required this.instructor,
    required this.rating,
    required this.ratingCount,
    required this.studentsCount,
    required this.lessonsCount,
    required this.quizzesCount,
    required this.categories,
    required this.tags,
    required this.curriculum,
    this.isEnrolled = false,
    this.progress = 0.0,
    this.isWishlisted = false,
  });

  bool get hasDiscount => salePrice > 0 && salePrice < price;
  double get displayPrice => hasDiscount ? salePrice : price;
  bool get isFree => price == 0;

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      shortDescription: json['shortDescription'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      salePrice: (json['salePrice'] as num?)?.toDouble() ?? 0.0,
      duration: json['duration'] as String? ?? '',
      instructor: json['instructor'] != null
          ? Instructor.fromJson(json['instructor'] as Map<String, dynamic>)
          : const Instructor.empty(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['ratingCount'] as int? ?? 0,
      studentsCount: json['studentsCount'] as int? ?? 0,
      lessonsCount: json['lessonsCount'] as int? ?? 0,
      quizzesCount: json['quizzesCount'] as int? ?? 0,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      curriculum: (json['curriculum'] as List<dynamic>?)
              ?.map((e) =>
                  CurriculumSection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isEnrolled: json['isEnrolled'] as bool? ?? false,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      isWishlisted: json['isWishlisted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'shortDescription': shortDescription,
      'thumbnail': thumbnail,
      'price': price,
      'salePrice': salePrice,
      'duration': duration,
      'instructor': instructor.toJson(),
      'rating': rating,
      'ratingCount': ratingCount,
      'studentsCount': studentsCount,
      'lessonsCount': lessonsCount,
      'quizzesCount': quizzesCount,
      'categories': categories,
      'tags': tags,
      'curriculum': curriculum.map((e) => e.toJson()).toList(),
      'isEnrolled': isEnrolled,
      'progress': progress,
      'isWishlisted': isWishlisted,
    };
  }

  Course copyWith({
    int? id,
    String? title,
    String? description,
    String? shortDescription,
    String? thumbnail,
    double? price,
    double? salePrice,
    String? duration,
    Instructor? instructor,
    double? rating,
    int? ratingCount,
    int? studentsCount,
    int? lessonsCount,
    int? quizzesCount,
    List<String>? categories,
    List<String>? tags,
    List<CurriculumSection>? curriculum,
    bool? isEnrolled,
    double? progress,
    bool? isWishlisted,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      thumbnail: thumbnail ?? this.thumbnail,
      price: price ?? this.price,
      salePrice: salePrice ?? this.salePrice,
      duration: duration ?? this.duration,
      instructor: instructor ?? this.instructor,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      studentsCount: studentsCount ?? this.studentsCount,
      lessonsCount: lessonsCount ?? this.lessonsCount,
      quizzesCount: quizzesCount ?? this.quizzesCount,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      curriculum: curriculum ?? this.curriculum,
      isEnrolled: isEnrolled ?? this.isEnrolled,
      progress: progress ?? this.progress,
      isWishlisted: isWishlisted ?? this.isWishlisted,
    );
  }
}

class Instructor {
  final int id;
  final String name;
  final String avatar;
  final String title;
  final String bio;
  final int coursesCount;
  final int studentsCount;
  final double rating;

  const Instructor({
    required this.id,
    required this.name,
    required this.avatar,
    required this.title,
    required this.bio,
    required this.coursesCount,
    required this.studentsCount,
    required this.rating,
  });

  const Instructor.empty()
      : id = 0,
        name = '',
        avatar = '',
        title = '',
        bio = '',
        coursesCount = 0,
        studentsCount = 0,
        rating = 0.0;

  factory Instructor.fromJson(Map<String, dynamic> json) {
    return Instructor(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      title: json['title'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      coursesCount: json['coursesCount'] as int? ?? 0,
      studentsCount: json['studentsCount'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'title': title,
      'bio': bio,
      'coursesCount': coursesCount,
      'studentsCount': studentsCount,
      'rating': rating,
    };
  }
}

class CurriculumSection {
  final String sectionTitle;
  final List<CurriculumItem> items;

  const CurriculumSection({
    required this.sectionTitle,
    required this.items,
  });

  factory CurriculumSection.fromJson(Map<String, dynamic> json) {
    return CurriculumSection(
      sectionTitle: json['sectionTitle'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  CurriculumItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sectionTitle': sectionTitle,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class CurriculumItem {
  final CurriculumItemType type;
  final int id;
  final String title;
  final String duration;
  final bool isCompleted;

  const CurriculumItem({
    required this.type,
    required this.id,
    required this.title,
    required this.duration,
    this.isCompleted = false,
  });

  factory CurriculumItem.fromJson(Map<String, dynamic> json) {
    return CurriculumItem(
      type: _parseCurriculumItemType(json['type'] as String? ?? 'lesson'),
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'id': id,
      'title': title,
      'duration': duration,
      'isCompleted': isCompleted,
    };
  }

  static CurriculumItemType _parseCurriculumItemType(String type) {
    switch (type.toLowerCase()) {
      case 'quiz':
        return CurriculumItemType.quiz;
      case 'lesson':
      default:
        return CurriculumItemType.lesson;
    }
  }
}
