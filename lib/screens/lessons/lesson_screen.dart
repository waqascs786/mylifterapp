import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';

import '../../services/api_service.dart';
import '../../config/app_config.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class Lesson {
  final String id;
  final String title;
  final String? content;
  final String? videoUrl;
  final List<LessonAttachment> attachments;
  final bool isCompleted;
  final int sortOrder;
  final String sectionId;

  const Lesson({
    required this.id,
    required this.title,
    this.content,
    this.videoUrl,
    this.attachments = const [],
    this.isCompleted = false,
    required this.sortOrder,
    required this.sectionId,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String?,
      videoUrl: (json['videoUrl'] as String?)?.isNotEmpty == true
          ? json['videoUrl'] as String
          : (json['video_embed'] as String?)?.isNotEmpty == true
              ? json['video_embed'] as String
              : null,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => LessonAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isCompleted: json['isCompleted'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
      sectionId: json['sectionId'] as String? ?? '',
    );
  }
}

class LessonAttachment {
  final String id;
  final String name;
  final String url;
  final String? fileSize;
  final String? type;

  const LessonAttachment({
    required this.id,
    required this.name,
    required this.url,
    this.fileSize,
    this.type,
  });

  factory LessonAttachment.fromJson(Map<String, dynamic> json) {
    return LessonAttachment(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      fileSize: json['fileSize'] as String?,
      type: json['type'] as String?,
    );
  }
}

class CourseSection {
  final String id;
  final String title;
  final List<Lesson> lessons;
  final int sortOrder;

  const CourseSection({
    required this.id,
    required this.title,
    this.lessons = const [],
    required this.sortOrder,
  });

  factory CourseSection.fromJson(Map<String, dynamic> json) {
    return CourseSection(
      id: json['id'] as String,
      title: json['title'] as String,
      lessons: (json['lessons'] as List<dynamic>?)
              ?.map((e) => Lesson.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}

// ─── Lesson Provider ─────────────────────────────────────────────────────────

class LessonProvider extends ChangeNotifier {
  List<CourseSection> _sections = [];
  Lesson? _currentLesson;
  int _currentIndex = 0;
  bool _isLoading = false;
  String? _error;
  Map<String, String> _notes = {};

  List<CourseSection> get sections => _sections;
  Lesson? get currentLesson => _currentLesson;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasPrevious => _currentIndex > 0;
  bool get hasNext => _currentIndex < _flatLessons.length - 1;

  List<Lesson> get _flatLessons =>
      _sections.expand((s) => s.lessons).toList();

  int get totalLessons => _flatLessons.length;
  int get completedLessons => _flatLessons.where((l) => l.isCompleted).length;
  double get progress =>
      totalLessons == 0 ? 0 : completedLessons / totalLessons;

  String get currentNote => _notes[_currentLesson?.id] ?? '';

  Future<void> loadCourseContent(String courseId, {String? startLessonId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.instance.get(
        'courseCurriculum',
        pathParams: {'id': courseId},
      );
      
      final List<dynamic> sectionsData = result['data'] as List<dynamic>? ?? [];

      _sections = [];
      for (final secJson in sectionsData) {
        final sec = secJson as Map<String, dynamic>;
        final items = (sec['items'] as List<dynamic>? ?? []);
        final lessons = items.where((item) => item['type'] == 'lesson').map((item) {
          final id = item['id'].toString();
          return Lesson(
            id: id,
            title: item['title'] as String? ?? '',
            content: item['content'] as String?,
            videoUrl: item['videoUrl'] as String? ??
                item['video_embed'] as String? ??
                item['video_embed_url'] as String?,
            isCompleted: item['isCompleted'] as bool? ?? false,
            sortOrder: 0,
            sectionId: '',
          );
        }).toList();
        if (lessons.isNotEmpty) {
          _sections.add(CourseSection(
            id: sec['sectionTitle']?.toString() ?? '',
            title: sec['sectionTitle'] as String? ?? '',
            lessons: lessons,
            sortOrder: 0,
          ));
        }
      }

      if (_flatLessons.isNotEmpty) {
        // Start at the requested lesson when deep-linked from the course page.
        var startIndex = 0;
        if (startLessonId != null && startLessonId.isNotEmpty) {
          final idx = _flatLessons.indexWhere((l) => l.id == startLessonId);
          if (idx >= 0) startIndex = idx;
        }
        _currentIndex = startIndex;
        _currentLesson = _flatLessons[startIndex];
      }
    } catch (e) {
      _error = 'Failed to load course content: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void navigateToLesson(int index) {
    if (index >= 0 && index < _flatLessons.length) {
      _currentIndex = index;
      _currentLesson = _flatLessons[index];
      notifyListeners();
    }
  }

  void nextLesson() {
    if (hasNext) navigateToLesson(_currentIndex + 1);
  }

  void previousLesson() {
    if (hasPrevious) navigateToLesson(_currentIndex - 1);
  }

  Future<void> markAsComplete(String lessonId) async {
    try {
      final result = await ApiService.instance.post(
        'lessonComplete',
        pathParams: {'id': lessonId},
      );

      for (var section in _sections) {
        for (var i = 0; i < section.lessons.length; i++) {
          if (section.lessons[i].id == lessonId) {
            section.lessons[i] = Lesson(
              id: section.lessons[i].id,
              title: section.lessons[i].title,
              content: section.lessons[i].content,
              videoUrl: section.lessons[i].videoUrl,
              attachments: section.lessons[i].attachments,
              isCompleted: true,
              sortOrder: section.lessons[i].sortOrder,
              sectionId: section.lessons[i].sectionId,
            );
            // Keep the current lesson reference in sync so the bottom bar
            // switches from "Mark Complete" to "Next" immediately.
            if (_currentLesson?.id == lessonId) {
              _currentLesson = section.lessons[i];
            }
          }
        }
      }
      _error = null;
      notifyListeners();
      // result may include updated progress — refresh is handled by UI.
      return;
    } catch (e) {
      _error = 'Failed to mark lesson as complete';
      notifyListeners();
      rethrow;
    }
  }

  void updateNote(String lessonId, String note) {
    _notes[lessonId] = note;
    _saveNotesLocally();
    notifyListeners();
  }

  Future<void> _saveNotesLocally() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/lesson_notes.json');
      await file.writeAsString(jsonEncode(_notes));
    } catch (_) {}
  }

  Future<void> loadNotes() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/lesson_notes.json');
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        _notes = data.map((k, v) => MapEntry(k, v as String));
        notifyListeners();
      }
    } catch (_) {}
  }

  static List<CourseSection> _getDemoSections() {
    return [
      CourseSection(
        id: 's1',
        title: 'Getting Started',
        sortOrder: 0,
        lessons: [
          const Lesson(
            id: 'l1',
            title: 'Introduction to Flutter',
            content: '<h2>Welcome to Flutter!</h2><p>Flutter is an open-source UI toolkit for building natively compiled applications.</p><ul><li>Cross-platform</li><li>Hot reload</li><li>Rich widget library</li></ul>',
            sortOrder: 0,
            sectionId: 's1',
          ),
          const Lesson(
            id: 'l2',
            title: 'Setting Up Your Environment',
            content: '<h2>Environment Setup</h2><p>Install Flutter SDK and configure your IDE.</p><p>Run <code>flutter doctor</code> to verify your setup.</p>',
            sortOrder: 1,
            sectionId: 's1',
            attachments: [
              LessonAttachment(id: 'a1', name: 'Setup Guide.pdf', url: '', fileSize: '2.4 MB', type: 'pdf'),
              LessonAttachment(id: 'a2', name: 'Checklist.docx', url: '', fileSize: '156 KB', type: 'doc'),
            ],
          ),
        ],
      ),
      CourseSection(
        id: 's2',
        title: 'Dart Basics',
        sortOrder: 1,
        lessons: [
          const Lesson(
            id: 'l3',
            title: 'Variables and Types',
            content: '<h2>Dart Variables</h2><p>Dart uses <strong>static typing</strong> with type inference.</p><pre><code>var name = "PagePilot";\nint count = 42;\ndouble price = 9.99;\nbool isActive = true;</code></pre>',
            sortOrder: 0,
            sectionId: 's2',
          ),
          const Lesson(
            id: 'l4',
            title: 'Functions and Classes',
            content: '<h2>Functions</h2><p>Dart supports first-class functions, optional parameters, and arrow syntax.</p>',
            videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bumblebee.mp4',
            sortOrder: 1,
            sectionId: 's2',
          ),
        ],
      ),
      CourseSection(
        id: 's3',
        title: 'Widgets Deep Dive',
        sortOrder: 2,
        lessons: [
          const Lesson(
            id: 'l5',
            title: 'Stateless vs Stateful',
            content: '<h2>Widget Types</h2><p><strong>StatelessWidget</strong> is immutable. <strong>StatefulWidget</strong> maintains mutable state.</p>',
            sortOrder: 0,
            sectionId: 's3',
          ),
          const Lesson(
            id: 'l6',
            title: 'Layout Widgets',
            content: '<h2>Layouts</h2><p>Use Row, Column, Flex, Stack, and Wrap for layout.</p>',
            sortOrder: 1,
            sectionId: 's3',
          ),
        ],
      ),
    ];
  }
}

// ─── Lesson Screen ───────────────────────────────────────────────────────────

class LessonScreen extends StatefulWidget {
  static const route = '/lesson';
  final String courseId;
  final String courseTitle;
  final String? lessonId;

  const LessonScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    this.lessonId,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final LessonProvider _provider;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _noteController = TextEditingController();
  bool _isNoteEditing = false;

  @override
  void initState() {
    super.initState();
    _provider = LessonProvider();
    _provider.addListener(_onProviderUpdate);
    _provider.loadCourseContent(widget.courseId, startLessonId: widget.lessonId);
    _provider.loadNotes();
  }

  void _onProviderUpdate() {
    if (mounted) {
      _noteController.text = _provider.currentNote;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderUpdate);
    _provider.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _showCurriculumSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.menu_book, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Course Content',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '${(_provider.progress * 100).toInt()}% complete',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _provider.sections.fold<int>(0, (sum, s) => sum + s.lessons.length + 1),
                itemBuilder: (context, index) {
                  int runningIndex = 0;
                  for (final section in _provider.sections) {
                    if (index == runningIndex) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        child: Text(
                          section.title,
                          style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                        ),
                      );
                    }
                    runningIndex++;
                    for (final lesson in section.lessons) {
                      if (index == runningIndex) {
                        final lessonIndex = _provider._flatLessons.indexOf(lesson);
                        final isCurrent = lesson.id == _provider.currentLesson?.id;
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            lesson.isCompleted
                                ? Icons.check_circle
                                : isCurrent
                                    ? Icons.play_circle
                                    : Icons.play_circle_outline,
                            size: 22,
                            color: lesson.isCompleted
                                ? Colors.green
                                : isCurrent
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                          ),
                          title: Text(
                            lesson.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                              color: isCurrent ? theme.colorScheme.primary : null,
                            ),
                          ),
                          onTap: () {
                            _provider.navigateToLesson(lessonIndex);
                            Navigator.pop(context);
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        );
                      }
                      runningIndex++;
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(
            _provider.currentLesson?.title ?? widget.courseTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (_provider.currentLesson != null &&
                !_provider.currentLesson!.isCompleted)
              TextButton.icon(
                onPressed: () async {
                  try {
                    await _provider.markAsComplete(_provider.currentLesson!.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lesson marked complete')),
                      );
                    }
                  } catch (_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to mark complete')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text('Complete'),
              ),
            if (_provider.currentLesson?.isCompleted == true)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.check_circle, color: Colors.green, size: 24),
              ),
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () => _showCurriculumSheet(context),
              tooltip: 'Course content',
            ),
          ],
        ),
        body: _provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _provider.error != null
                ? _buildErrorState(theme)
                : _buildLessonContent(context, theme),
        bottomNavigationBar: _buildBottomNavigation(context, theme),
      ),
    );
  }

  Widget _buildCurriculumDrawer(BuildContext context, ThemeData theme) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Course Content',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _provider.progress,
                            minHeight: 6,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(_provider.progress * 100).toInt()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_provider.completedLessons}/${_provider.totalLessons} lessons completed',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _provider.sections.length,
                itemBuilder: (context, sectionIndex) {
                  final section = _provider.sections[sectionIndex];
                  return ExpansionTile(
                    title: Text(
                      section.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    initiallyExpanded: true,
                    children: section.lessons.map((lesson) {
                      final lessonIndex =
                          _provider._flatLessons.indexOf(lesson);
                      final isCurrent =
                          lesson.id == _provider.currentLesson?.id;
                      return ListTile(
                        leading: Icon(
                          lesson.isCompleted
                              ? Icons.check_circle
                              : isCurrent
                                  ? Icons.play_circle
                                  : Icons.circle_outlined,
                          color: lesson.isCompleted
                              ? Colors.green
                              : isCurrent
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                          size: 22,
                        ),
                        title: Text(
                          lesson.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isCurrent ? FontWeight.w600 : FontWeight.normal,
                            color: isCurrent
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                        subtitle: lesson.videoUrl != null
                            ? Row(
                                children: [
                                  Icon(Icons.play_circle_outline,
                                      size: 14,
                                      color:
                                          theme.colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Video',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              )
                            : null,
                        onTap: () {
                          _provider.navigateToLesson(lessonIndex);
                          Navigator.pop(context);
                        },
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 2),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonContent(BuildContext context, ThemeData theme) {
    final lesson = _provider.currentLesson;
    if (lesson == null) {
      return const Center(child: Text('No lesson selected'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar at top
          if (_provider.totalLessons > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _provider.progress,
                  minHeight: 4,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ),

          // Video player
          if (lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              // Key on lesson id so the WebView is recreated (and the new
              // video actually loads) when navigating between lessons.
              child: _LessonVideoPlayer(
                key: ValueKey('lesson_video_${lesson.id}'),
                url: lesson.videoUrl!,
              ),
            ),

          // HTML content
          if (lesson.content != null && lesson.content!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Html(
                data: lesson.content!,
                style: {
                  'body': Style(
                    fontSize: FontSize(16),
                    lineHeight: const LineHeight(1.6),
                  ),
                  'h2': Style(
                    fontSize: FontSize(22),
                    fontWeight: FontWeight.w700,
                  ),
                  'code': Style(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    padding: HtmlPaddings.all(4),
                    fontSize: FontSize(14),
                    fontFamily: 'monospace',
                  ),
                  'pre': Style(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    padding: HtmlPaddings.all(12),
                    whiteSpace: WhiteSpace.pre,
                  ),
                },
              ),
            ),

          // Attachments
          if (lesson.attachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _AttachmentSection(attachments: lesson.attachments),
            ),

          // Notes section
          Padding(
            padding: const EdgeInsets.all(16),
            child: _NotesSection(
              controller: _noteController,
              isEditing: _isNoteEditing,
              onEditToggle: () {
                setState(() => _isNoteEditing = !_isNoteEditing);
                if (!_isNoteEditing) {
                  _provider.updateNote(lesson.id, _noteController.text);
                }
              },
              onChanged: (value) {
                _provider.updateNote(lesson.id, value);
              },
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, ThemeData theme) {
    final current = _provider.currentLesson;
    final isComplete = current?.isCompleted == true;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back to Course'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (isComplete && _provider.hasNext)
            Expanded(
              child: FilledButton.icon(
                onPressed: _provider.nextLesson,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Next'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            )
          else if (!isComplete)
            Expanded(
              child: FilledButton.icon(
                onPressed: () async {
                  if (current == null) return;
                  try {
                    await _provider.markAsComplete(current.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lesson complete — back to course or continue')),
                      );
                    }
                  } catch (_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to mark complete')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Mark Complete'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            )
          else
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Done — Back'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              _provider.error ?? 'Something went wrong',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  _provider.loadCourseContent(widget.courseId),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Video Player Widget ─────────────────────────────────────────────────────

class _LessonVideoPlayer extends StatefulWidget {
  final String url;

  const _LessonVideoPlayer({super.key, required this.url});

  @override
  State<_LessonVideoPlayer> createState() => _LessonVideoPlayerState();
}

class _LessonVideoPlayerState extends State<_LessonVideoPlayer> {
  late final WebViewController _webController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black);
    _loadVideo(widget.url);
  }

  @override
  void didUpdateWidget(covariant _LessonVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _loadVideo(widget.url);
    }
  }

  void _loadVideo(String url) {
    final embedUrl = _buildEmbedUrl(url);

    if (embedUrl == null) {
      _error = 'Unsupported video format';
      return;
    }
    _error = null;

    if (embedUrl.contains('youtube.com/embed/')) {
      // YouTube rejects embeds without a Referer header (Error 153).
      // Loading a wrapper page with an iframe — instead of navigating the
      // WebView straight to the embed URL — makes the request carry the
      // site URL as referrer, which YouTube accepts.
      _webController.loadHtmlString(
        _buildYouTubeWrapper(embedUrl),
        baseUrl: _referrerUrl(),
      );
    } else {
      _webController.loadRequest(Uri.parse(embedUrl));
    }
  }

  /// Origin used as the document URL (and thus Referer) for the YouTube
  /// wrapper page.
  String _referrerUrl() {
    String site = '';
    try {
      site = AppConfig.instance.siteUrl;
      if (site.isEmpty) site = AppConfig.instance.apiBaseUrl;
    } catch (_) {}
    site = site.trim();
    if (site.isEmpty || !site.startsWith('http')) return 'https://www.youtube.com';
    return site.replaceAll(RegExp(r'/+$'), '');
  }

  String _buildYouTubeWrapper(String embedUrl) {
    final src = embedUrl.replaceAll('"', '&quot;');
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
<meta name="referrer" content="strict-origin-when-cross-origin">
<style>
  html, body { margin: 0; padding: 0; background: #000; height: 100%; overflow: hidden; }
  iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0; }
</style>
</head>
<body>
<iframe src="$src" referrerpolicy="strict-origin" allow="autoplay; encrypted-media; picture-in-picture" allowfullscreen webkitallowfullscreen></iframe>
</body>
</html>''';
  }

  String? _buildEmbedUrl(String url) {
    var raw = url.trim();

    // LifterLMS often stores a full iframe HTML string in _llms_video_embed.
    if (raw.contains('<iframe') || raw.contains('<video')) {
      final srcMatch = RegExp('src=["\']([^"\']+)["\']').firstMatch(raw);
      if (srcMatch != null) {
        raw = srcMatch.group(1)!;
      } else {
        final videoMatch = RegExp('<source[^>]+src=["\']([^"\']+)["\']').firstMatch(raw);
        if (videoMatch != null) {
          raw = videoMatch.group(1)!;
        }
      }
    }

    // YouTube (watch, youtu.be, embed, shorts)
    final ytMatch = RegExp(
      r'(?:youtube\.com/watch\?v=|youtu\.be/|youtube\.com/embed/|youtube\.com/shorts/)([A-Za-z0-9_-]{11})',
    ).firstMatch(raw);
    if (ytMatch != null) {
      final id = ytMatch.group(1);
      return 'https://www.youtube.com/embed/$id?playsinline=1&rel=0&modestbranding=1&autoplay=1';
    }

    // Vimeo
    final vimeoMatch = RegExp(r'(?:vimeo\.com/)(\d+)').firstMatch(raw);
    if (vimeoMatch != null) {
      final id = vimeoMatch.group(1);
      return 'https://player.vimeo.com/video/$id?playsinline=1';
    }

    // Wistia
    final wistiaMatch = RegExp(r'wistia\.(?:com|net)/(?:medias|embed/medias)/([A-Za-z0-9]+)').firstMatch(raw);
    if (wistiaMatch != null) {
      final id = wistiaMatch.group(1);
      return 'https://fast.wistia.net/embed/medias/$id';
    }

    // Direct video URL (mp4, webm, ogg, m3u8)
    if (RegExp(r'\.(mp4|webm|ogg|m3u8)(\?|$)', caseSensitive: false).hasMatch(raw)) {
      return raw;
    }

    // Already an embed URL
    if (raw.startsWith('http') && (raw.contains('/embed/') || raw.contains('player.vimeo'))) {
      return raw;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 48),
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: WebViewWidget(controller: _webController),
      ),
    );
  }
}

// ─── Attachment Section ──────────────────────────────────────────────────────

class _AttachmentSection extends StatelessWidget {
  final List<LessonAttachment> attachments;

  const _AttachmentSection({required this.attachments});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_file,
                size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Attachments (${attachments.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...attachments.map((att) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: _getFileIcon(att.type),
                title: Text(att.name, style: const TextStyle(fontSize: 14)),
                subtitle: att.fileSize != null ? Text(att.fileSize!) : null,
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _downloadAttachment(context, att),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              ),
            )),
      ],
    );
  }

  Widget _getFileIcon(String? type) {
    IconData iconData;
    Color color;

    switch (type?.toLowerCase()) {
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case 'doc':
      case 'docx':
        iconData = Icons.description;
        color = Colors.blue;
        break;
      case 'xls':
      case 'xlsx':
        iconData = Icons.table_chart;
        color = Colors.green;
        break;
      case 'ppt':
      case 'pptx':
        iconData = Icons.slideshow;
        color = Colors.orange;
        break;
      case 'zip':
        iconData = Icons.folder_zip;
        color = Colors.amber;
        break;
      default:
        iconData = Icons.insert_drive_file;
        color = Colors.grey;
    }

    return Icon(iconData, color: color, size: 32);
  }

  Future<void> _downloadAttachment(
      BuildContext context, LessonAttachment attachment) async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission required')),
          );
        }
        return;
      }

      // TODO: Implement actual download
      // final dir = await getDownloadsDirectory();
      // final file = File('${dir!.path}/${attachment.name}');
      // final response = await http.get(Uri.parse(attachment.url));
      // await file.writeAsBytes(response.bodyBytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloading ${attachment.name}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }
}

// ─── Notes Section ───────────────────────────────────────────────────────────

class _NotesSection extends StatelessWidget {
  final TextEditingController controller;
  final bool isEditing;
  final VoidCallback onEditToggle;
  final ValueChanged<String> onChanged;

  const _NotesSection({
    required this.controller,
    required this.isEditing,
    required this.onEditToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.note_alt_outlined,
                size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'My Notes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onEditToggle,
              icon: Icon(isEditing ? Icons.check : Icons.edit, size: 18),
              label: Text(isEditing ? 'Save' : 'Edit'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        isEditing
            ? TextField(
                controller: controller,
                maxLines: 5,
                minLines: 3,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: 'Add your notes here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  controller.text.isEmpty
                      ? 'No notes yet. Tap Edit to add notes.'
                      : controller.text,
                  style: TextStyle(
                    color: controller.text.isEmpty
                        ? theme.colorScheme.onSurfaceVariant
                        : null,
                    fontStyle: controller.text.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),
      ],
    );
  }
}
