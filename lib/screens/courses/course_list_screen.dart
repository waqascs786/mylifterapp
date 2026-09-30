import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/course.dart';
import '../../services/api_service.dart';
import '../../widgets/course_card.dart';
import 'course_detail_screen.dart';

class CourseListScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialFilter;

  const CourseListScreen({
    super.key,
    this.initialCategory,
    this.initialFilter,
  });

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchFocusNode = FocusNode();

  List<Course> _courses = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String _searchQuery = '';
  String _activeFilter = 'All';
  Category? _selectedCategory;
  bool _isGridView = true;

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter ?? 'All';
    _scrollController.addListener(_onScroll);
    _loadCategories();
    _loadCourses(refresh: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadCourses();
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      setState(() => _searchQuery = query);
      _loadCourses(refresh: true);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() => _searchQuery = '');
    _loadCourses(refresh: true);
  }

  void _onFilterChanged(String filter) {
    if (_activeFilter == filter) return;
    setState(() => _activeFilter = filter);
    _loadCourses(refresh: true);
  }

  void _onCategoryChanged(Category? category) {
    setState(() => _selectedCategory = category);
    _loadCourses(refresh: true);
  }

  void _toggleView() {
    setState(() => _isGridView = !_isGridView);
  }

  Future<void> _loadCategories() async {
    try {
      final result = await ApiService.instance.getCategories();
      final cats = result.map((e) => Category.fromJson(e)).toList();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {}
  }

  Future<void> _loadCourses({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _courses = [];
      });
    }

    if (refresh) setState(() => _isLoading = true);
    if (!refresh) setState(() => _isLoadingMore = true);

    try {
      final params = _buildQueryParams();
      final result = await ApiService.instance.getCourses(
        page: _currentPage,
        perPage: 12,
        params: params,
      );

      if (!mounted) return;

      setState(() {
        if (refresh) {
          _courses = result.courses;
        } else {
          _courses = [..._courses, ...result.courses];
        }
        _hasMore = result.hasMore;
        _currentPage++;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Map<String, String> _buildQueryParams() {
    final params = <String, String>{};

    if (_searchQuery.isNotEmpty) {
      params['search'] = _searchQuery;
    }

    switch (_activeFilter) {
      case 'Free':
        params['price'] = 'free';
        break;
      case 'Paid':
        params['price'] = 'paid';
        break;
      case 'Popular':
        params['orderby'] = 'popularity';
        break;
      case 'Recent':
        params['orderby'] = 'date';
        break;
      default:
        break;
    }

    if (_selectedCategory != null) {
      params['category'] = _selectedCategory!.id.toString();
    }

    return params;
  }

  Future<void> _onRefresh() async {
    await _loadCourses(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(config),
            _buildFilterSection(config),
            Expanded(child: _buildContent(config)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppConfig config) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search courses...',
          prefixIcon: const Icon(Icons.search, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: _clearSearch,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterSection(AppConfig config) {
    final filters = ['All', 'Free', 'Paid', 'Popular', 'Recent'];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = filters[index];
                      final isActive = filter == _activeFilter;
                      return GestureDetector(
                        onTap: () => _onFilterChanged(filter),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isActive
                                ? config.primaryColor
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive
                                  ? config.primaryColor
                                  : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              filter,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isActive
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildCategoryDropdown(config),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _toggleView,
                icon: Icon(
                  _isGridView ? Icons.view_list_outlined : Icons.grid_view_outlined,
                  color: config.primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCategoryDropdown(AppConfig config) {
    return GestureDetector(
      onTap: _showCategorySheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedCategory != null
              ? config.primaryColor.withOpacity(0.1)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedCategory != null
                ? config.primaryColor.withOpacity(0.3)
                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list,
              size: 18,
              color: _selectedCategory != null
                  ? config.primaryColor
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 4),
            Text(
              _selectedCategory?.name ?? 'Category',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _selectedCategory != null
                    ? config.primaryColor
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategorySheet() {
    final config = AppConfig.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select Category',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.all_inclusive, color: config.primaryColor),
                title: const Text('All Categories'),
                selected: _selectedCategory == null,
                selectedTileColor: config.primaryColor.withOpacity(0.1),
                onTap: () {
                  _onCategoryChanged(null);
                  Navigator.pop(context);
                },
              ),
              ..._categories.map((cat) => ListTile(
                    leading: Icon(_getCategoryIcon(cat.name), color: config.primaryColor),
                    title: Text(cat.name),
                    selected: _selectedCategory?.id == cat.id,
                    selectedTileColor: config.primaryColor.withOpacity(0.1),
                    onTap: () {
                      _onCategoryChanged(cat);
                      Navigator.pop(context);
                    },
                  )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('web') || lower.contains('frontend')) return Icons.language;
    if (lower.contains('mobile') || lower.contains('flutter')) return Icons.phone_iphone;
    if (lower.contains('design')) return Icons.palette;
    if (lower.contains('data') || lower.contains('ai')) return Icons.analytics;
    if (lower.contains('backend') || lower.contains('server')) return Icons.dns;
    if (lower.contains('business') || lower.contains('market')) return Icons.trending_up;
    return Icons.category;
  }

  Widget _buildContent(AppConfig config) {
    if (_isLoading) {
      return _isGridView ? _buildGridShimmer() : _buildListShimmer();
    }

    if (_courses.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: config.primaryColor,
      child: _isGridView ? _buildGridView(config) : _buildListView(config),
    );
  }

  Widget _buildGridView(AppConfig config) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final course = _courses[index];
                return CourseCard(
                  thumbnailUrl: course.thumbnail,
                  title: course.title,
                  instructorName: course.instructor.name,
                  rating: course.rating,
                  ratingCount: course.ratingCount,
                  price: course.price,
                  salePrice: course.salePrice,
                  isFree: course.isFree,
                  progress: course.isEnrolled
                      ? (course.progress / 100).clamp(0.0, 1.0)
                      : null,
                  isEnrolled: course.isEnrolled,
                  mode: CourseCardMode.grid,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CourseDetailScreen(courseId: course.id.toString()),
                    ),
                  ),
                );
              },
              childCount: _courses.length,
            ),
          ),
        ),
        if (_isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildListView(AppConfig config) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverList.separated(
            itemCount: _courses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final course = _courses[index];
              return CourseCard(
                thumbnailUrl: course.thumbnail,
                title: course.title,
                instructorName: course.instructor.name,
                rating: course.rating,
                ratingCount: course.ratingCount,
                price: course.price,
                salePrice: course.salePrice,
                isFree: course.isFree,
                progress: course.isEnrolled
                      ? (course.progress / 100).clamp(0.0, 1.0)
                      : null,
                isEnrolled: course.isEnrolled,
                mode: CourseCardMode.list,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CourseDetailScreen(courseId: course.id.toString()),
                  ),
                ),
              );
            },
          ),
        ),
        if (_isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildGridShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const CourseCardShimmer(mode: CourseCardMode.grid),
    );
  }

  Widget _buildListShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const CourseCardShimmer(mode: CourseCardMode.list),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
            ),
            const SizedBox(height: 16),
            Text(
              'No courses found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _activeFilter = 'All';
                  _selectedCategory = null;
                });
                _loadCourses(refresh: true);
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
