import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class WishlistCourse {
  final String id;
  final String title;
  final String? thumbnailUrl;
  final String? instructorName;
  final double? rating;
  final int? ratingCount;
  final double? price;
  final double? originalPrice;
  final String? category;
  final int? totalLessons;
  final String? level;

  const WishlistCourse({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    this.instructorName,
    this.rating,
    this.ratingCount,
    this.price,
    this.originalPrice,
    this.category,
    this.totalLessons,
    this.level,
  });

  factory WishlistCourse.fromJson(Map<String, dynamic> json) {
    return WishlistCourse(
      id: json['id'] as String,
      title: json['title'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      instructorName: json['instructorName'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: json['ratingCount'] as int?,
      price: (json['price'] as num?)?.toDouble(),
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      category: json['category'] as String?,
      totalLessons: json['totalLessons'] as int?,
      level: json['level'] as String?,
    );
  }
}

// ─── Wishlist Provider ───────────────────────────────────────────────────────

class WishlistProvider extends ChangeNotifier {
  List<WishlistCourse> _courses = [];
  bool _isLoading = false;
  String? _error;

  List<WishlistCourse> get courses => _courses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadWishlist() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Replace with actual API call
      // final response = await http.get(Uri.parse('$apiBase/user/wishlist'));
      // _courses = (jsonDecode(response.body) as List)
      //     .map((e) => WishlistCourse.fromJson(e)).toList();

      _courses = _getDemoCourses();
    } catch (e) {
      _error = 'Failed to load wishlist';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFromWishlist(String courseId) async {
    try {
      // TODO: API call to remove
      // await http.delete(Uri.parse('$apiBase/user/wishlist/$courseId'));

      _courses.removeWhere((c) => c.id == courseId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove course';
      notifyListeners();
    }
  }

  Future<void> refresh() async => loadWishlist();

  static List<WishlistCourse> _getDemoCourses() {
    return const [
      WishlistCourse(
        id: 'w1',
        title: 'Machine Learning with Python',
        instructorName: 'Dr. David Lee',
        rating: 4.8,
        ratingCount: 1240,
        price: 49.99,
        originalPrice: 99.99,
        category: 'Data Science',
        totalLessons: 45,
        level: 'Intermediate',
      ),
      WishlistCourse(
        id: 'w2',
        title: 'React Native Masterclass',
        instructorName: 'Chris Anderson',
        rating: 4.6,
        ratingCount: 890,
        price: 59.99,
        originalPrice: 129.99,
        category: 'Mobile Development',
        totalLessons: 52,
        level: 'Advanced',
      ),
      WishlistCourse(
        id: 'w3',
        title: 'AWS Cloud Practitioner',
        instructorName: 'Maria Garcia',
        rating: 4.7,
        ratingCount: 2100,
        price: 39.99,
        originalPrice: 89.99,
        category: 'Cloud',
        totalLessons: 30,
        level: 'Beginner',
      ),
      WishlistCourse(
        id: 'w4',
        title: 'Cybersecurity Fundamentals',
        instructorName: 'Alex Turner',
        rating: 4.5,
        ratingCount: 670,
        price: 44.99,
        originalPrice: 94.99,
        category: 'Security',
        totalLessons: 28,
        level: 'Beginner',
      ),
      WishlistCourse(
        id: 'w5',
        title: 'DevOps & CI/CD Pipeline',
        instructorName: 'Karen White',
        rating: 4.9,
        ratingCount: 450,
        price: 69.99,
        originalPrice: 149.99,
        category: 'DevOps',
        totalLessons: 38,
        level: 'Advanced',
      ),
    ];
  }
}

// ─── Wishlist Screen ─────────────────────────────────────────────────────────

class WishlistScreen extends StatefulWidget {
  static const route = '/wishlist';
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  late final WishlistProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = WishlistProvider();
    _provider.addListener(_onProviderUpdate);
    _provider.loadWishlist();
  }

  void _onProviderUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderUpdate);
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
          title: const Text('Wishlist'),
          actions: [
            if (_provider.courses.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '${_provider.courses.length} courses',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: _provider.isLoading
            ? _buildSkeleton()
            : _provider.error != null
                ? _buildError(theme)
                : RefreshIndicator(
                    onRefresh: _provider.refresh,
                    child: _provider.courses.isEmpty
                        ? _buildEmptyState(theme)
                        : _buildGrid(theme),
                  ),
      ),
    );
  }

  Widget _buildGrid(ThemeData theme) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _provider.courses.length,
      itemBuilder: (context, index) {
        final course = _provider.courses[index];
        return _WishlistCourseCard(
          course: course,
          onTap: () => Navigator.pushNamed(
            context,
            '/course-detail',
            arguments: course.id,
          ),
          onRemove: () => _showRemoveDialog(context, course),
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
              Icons.favorite_border,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Your wishlist is empty',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save courses you love for later',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, '/home'),
              child: const Text('Explore Courses'),
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
            onPressed: _provider.loadWishlist,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const _WishlistSkeleton(),
    );
  }

  void _showRemoveDialog(BuildContext context, WishlistCourse course) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from Wishlist?'),
        content: Text(
          'Are you sure you want to remove "${course.title}" from your wishlist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _provider.removeFromWishlist(course.id);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// ─── Course Card ─────────────────────────────────────────────────────────────

class _WishlistCourseCard extends StatelessWidget {
  final WishlistCourse course;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _WishlistCourseCard({
    required this.course,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color:
                        theme.colorScheme.primaryContainer.withOpacity(0.3),
                    child: course.thumbnailUrl != null
                        ? Image.network(
                            course.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildPlaceholder(theme),
                          )
                        : _buildPlaceholder(theme),
                  ),
                  // Remove button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          size: 18,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                  // Level badge
                  if (course.level != null)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          course.level!,
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (course.instructorName != null)
                      Text(
                        course.instructorName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    // Rating
                    if (course.rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            '${course.rating}',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          if (course.ratingCount != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${course.ratingCount})',
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    const SizedBox(height: 4),
                    // Price
                    Row(
                      children: [
                        if (course.price != null)
                          Text(
                            '\$${course.price!.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        if (course.originalPrice != null &&
                            course.originalPrice! > (course.price ?? 0)) ...[
                          const SizedBox(width: 4),
                          Text(
                            '\$${course.originalPrice!.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                              color:
                                  theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
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
        size: 40,
        color: theme.colorScheme.primary.withOpacity(0.5),
      ),
    );
  }
}

// ─── Skeleton Loader ─────────────────────────────────────────────────────────

class _WishlistSkeleton extends StatelessWidget {
  const _WishlistSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.surfaceContainerHighest.withOpacity(0.5);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail skeleton
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: color,
            ),
          ),
          // Details skeleton
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 80,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 30,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
