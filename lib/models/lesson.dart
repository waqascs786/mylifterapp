class Lesson {
  final int id;
  final int courseId;
  final String title;
  final String content;
  final String duration;
  final String thumbnail;
  final List<Attachment> attachments;
  final bool isCompleted;
  final int order;

  const Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.content,
    required this.duration,
    required this.thumbnail,
    required this.attachments,
    this.isCompleted = false,
    required this.order,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as int? ?? 0,
      courseId: json['courseId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) =>
                  Attachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isCompleted: json['isCompleted'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'content': content,
      'duration': duration,
      'thumbnail': thumbnail,
      'attachments': attachments.map((e) => e.toJson()).toList(),
      'isCompleted': isCompleted,
      'order': order,
    };
  }

  Lesson copyWith({
    int? id,
    int? courseId,
    String? title,
    String? content,
    String? duration,
    String? thumbnail,
    List<Attachment>? attachments,
    bool? isCompleted,
    int? order,
  }) {
    return Lesson(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      content: content ?? this.content,
      duration: duration ?? this.duration,
      thumbnail: thumbnail ?? this.thumbnail,
      attachments: attachments ?? this.attachments,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order ?? this.order,
    );
  }
}

class Attachment {
  final int id;
  final String name;
  final String url;
  final String type;
  final String size;

  const Attachment({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.size,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      type: json['type'] as String? ?? '',
      size: json['size'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type,
      'size': size,
    };
  }

  bool get isPdf => type.toLowerCase() == 'pdf';
  bool get isVideo => type.toLowerCase() == 'video';
  bool get isDocument =>
      type.toLowerCase() == 'doc' || type.toLowerCase() == 'docx';
  bool get isSpreadsheet =>
      type.toLowerCase() == 'xls' || type.toLowerCase() == 'xlsx';
  bool get isPresentation =>
      type.toLowerCase() == 'ppt' || type.toLowerCase() == 'pptx';
}
