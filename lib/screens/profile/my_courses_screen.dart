import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../services/api_service.dart';
import '../courses/course_detail_screen.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class CourseItem {
  final String id;
  final String title;
  final String? thumbnailUrl;
  final String? instructorName;
  final double progress;
  final String status; // 'in_progress', 'completed', 'all'
  final String? category;
  final double? rating;
  final int? totalLessons;
  final String? lastAccessedAt;

  const CourseItem({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    this.instructorName,
    this.progress = 0.0,
    this.status = 'all',
    this.category,
    this.rating,
    this.totalLessons,
    this.lastAccessedAt,
  });

  factory CourseItem.fromJson(Map<String, dynamic> json) {
    return CourseItem(
      id: json['id'] as String,
      title: json['title'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      instructorName: json['instructorName'] as String?,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'all',
      category: json['category'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      totalLessons: json['totalLessons'] as int?,
      lastAccessedAt: json['lastAccessedAt'] as String?,
    );
  }
}

// ─── My Courses Provider ─────────────────────────────────────────────────────

class MyCoursesProvider extends ChangeNotifier {
  List<CourseItem> _allCourses = [];
  List<CourseItem> _filteredCourses = [];
  bool _isLoading = false;
  String? _error;
  String _selectedStatus = 'in_progress';
  String? _selectedCategory;
  String _sortBy = 'recent';

  List<CourseItem> get courses => _filteredCourses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedStatus => _selectedStatus;
  String? get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;

  List<String> get categories =>
      _allCourses.map((c) => c.category).whereType<String>().toSet().toList()..sort();

  int get inProgressCount =>
      _allCourses.where((c) => c.status == 'in_progress').length;
  int get completedCount =>
      _allCourses.where((c) => c.status == 'completed').length;

  Future<void> loadCourses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final courses = await ApiService.instance.getEnrolledCourses();
      _allCourses = courses
          .map((c) {
            final pct = c.progress; // API returns 0–100
            final norm = (pct / 100).clamp(0.0, 1.0);
            return CourseItem(
              id: c.id.toString(),
              title: c.title,
              thumbnailUrl: c.thumbnail.isNotEmpty ? c.thumbnail : null,
              instructorName:
                  c.instructor.name.isNotEmpty ? c.instructor.name : null,
              progress: norm,
              status: norm >= 1.0 ? 'completed' : 'in_progress',
              category: c.categories.isNotEmpty ? c.categories.first : null,
              totalLessons: c.lessonsCount,
              lastAccessedAt: null,
            );
          })
          .toList();
      _applyFilters();
    } catch (e) {
      _error = 'Failed to load courses';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setStatus(String status) {
    _selectedStatus = status;
    _applyFilters();
    notifyListeners();
  }

  void setCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredCourses = _allCourses.where((course) {
      final matchesStatus = _selectedStatus == 'all' ||
          course.status == _selectedStatus;
      final matchesCategory =
          _selectedCategory == null || course.category == _selectedCategory;
      return matchesStatus && matchesCategory;
    }).toList();

    switch (_sortBy) {
      case 'recent':
        _filteredCourses.sort((a, b) {
          final aDate = DateTime.tryParse(a.lastAccessedAt ?? '') ?? DateTime(2000);
          final bDate = DateTime.tryParse(b.lastAccessedAt ?? '') ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
        break;
      case 'alphabetical':
        _filteredCourses.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'progress':
        _filteredCourses.sort((a, b) => b.progress.compareTo(a.progress));
        break;
    }
  }

  Future<void> refresh() async => loadCourses();

}

// ─── My Courses Screen ───────────────────────────────────────────────────────

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen>
    with SingleTickerProviderStateMixin {
  late final MyCoursesProvider _provider;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _provider = MyCoursesProvider();
    _provider.addListener(_onProviderUpdate);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _provider.loadCourses();
  }

  void _onProviderUpdate() {
    if (mounted) setState(() {});
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    const statuses = ['in_progress', 'completed', 'all'];
    _provider.setStatus(statuses[_tabController.index]);
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderUpdate);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Courses'),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              tooltip: 'Sort by',
              onSelected: _provider.setSortBy,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'recent',
                  child: Text('Recent'),
                ),
                const PopupMenuItem(
                  value: 'alphabetical',
                  child: Text('Alphabetical'),
                ),
                const PopupMenuItem(
                  value: 'progress',
                  child: Text('Progress'),
                ),
              ],
            ),
            PopupMenuButton<String?>(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filter by category',
              onSelected: (value) => _provider.setCategory(
                value == 'all' ? null : value,
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'all',
                  child: Text('All Categories'),
                ),
                ..._provider.categories.map(
                  (cat) => PopupMenuItem(value: cat, child: Text(cat)),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'In Progress (${_provider.inProgressCount})'),
              Tab(text: 'Completed (${_provider.completedCount})'),
              Tab(text: 'All (${_provider.courses.length})'),
            ],
          ),
        ),
        body: _provider.isLoading
            ? _buildSkeleton()
            : _provider.error != null
                ? _buildError(theme)
                : RefreshIndicator(
                    onRefresh: _provider.refresh,
                    child: _provider.courses.isEmpty
                        ? _buildEmptyState(theme)
                        : _buildCourseList(theme),
                  ),
      ),
    );
  }

  Widget _buildCourseList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _provider.courses.length,
      itemBuilder: (context, index) {
        final course = _provider.courses[index];
        return _CourseCard(
          course: course,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CourseDetailScreen(courseId: course.id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school_outlined,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No courses found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Courses you enroll in will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_provider.error!),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _provider.loadCourses,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
      itemBuilder: (context, index) => const _CourseSkeleton(),
    );
  }
}

// ─── Course Card ─────────────────────────────────────────────────────────────

class _CourseCard extends StatelessWidget {
  final CourseItem course;
  final VoidCallback onTap;

  const _CourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            AspectRatio(
              aspectRatio: 16 / 7,
              child: Container(
                width: double.infinity,
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                child: course.thumbnailUrl != null
                    ? Image.network(
                        course.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
                      )
                    : _buildPlaceholder(theme),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    course.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Instructor
                  if (course.instructorName != null)
                    Text(
                      course.instructorName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Progress bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: course.progress,
                            minHeight: 6,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(course.progress * 100).toInt()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (course.progress >= 1.0) ...[
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.play_circle_outline,
        size: 48,
        color: theme.colorScheme.primary.withOpacity(0.5),
      ),
    );
  }
}

// ─── Skeleton Loader ─────────────────────────────────────────────────────────

class _CourseSkeleton extends StatelessWidget {
  const _CourseSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail skeleton
          AspectRatio(
            aspectRatio: 16 / 7,
            child: Container(
              width: double.infinity,
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                // Progress skeleton
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.5,
                    minHeight: 6,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
