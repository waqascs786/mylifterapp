import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchResult {
  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String? instructorName;
  final double? rating;
  final int? ratingCount;
  final double? price;
  final String? category;
  final int? totalLessons;

  const SearchResult({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.instructorName,
    this.rating,
    this.ratingCount,
    this.price,
    this.category,
    this.totalLessons,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      instructorName: json['instructorName'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: json['ratingCount'] as int?,
      price: (json['price'] as num?)?.toDouble(),
      category: json['category'] as String?,
      totalLessons: json['totalLessons'] as int?,
    );
  }
}

class SearchProvider extends ChangeNotifier {
  final List<String> _recentSearches = [];
  List<SearchResult> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _error;
  Timer? _debounceTimer;

  List<String> get recentSearches => List.unmodifiable(_recentSearches);
  List<SearchResult> get results => _results;
  bool get isSearching => _isSearching;
  bool get hasSearched => _hasSearched;
  String? get error => _error;

  Future<void> loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getStringList('recent_searches') ?? [];
      _recentSearches
        ..clear()
        ..addAll(data);
      notifyListeners();
    } catch (_) {}
  }

  void searchDebounced(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      _results = [];
      _hasSearched = false;
      _isSearching = false;
      _error = null;
      notifyListeners();
      return;
    }
    _isSearching = true;
    notifyListeners();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query.trim());
    });
  }

  void searchImmediate(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) return;
    _performSearch(query.trim());
  }

  Future<void> _performSearch(String query) async {
    _isSearching = true;
    _error = null;
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _results = _getDemoResults(query);
      _hasSearched = true;
      _addToRecentSearches(query);
    } catch (e) {
      _error = 'Search failed. Please try again.';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> _addToRecentSearches(String query) async {
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 20) _recentSearches.removeLast();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recent_searches', _recentSearches);
    } catch (_) {}
  }

  Future<void> removeRecentSearch(String query) async {
    _recentSearches.remove(query);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recent_searches', _recentSearches);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> clearAllSearches() async {
    _recentSearches.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('recent_searches');
    } catch (_) {}
    notifyListeners();
  }

  void clearResults() {
    _results = [];
    _hasSearched = false;
    _error = null;
    _debounceTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  static List<SearchResult> _getDemoResults(String query) {
    final allCourses = [
      const SearchResult(
        id: 'c1',
        title: 'Flutter Complete Development Course',
        description: 'Build iOS and Android apps with a single codebase',
        instructorName: 'Sarah Johnson',
        rating: 4.8,
        ratingCount: 1240,
        price: 49.99,
        category: 'Mobile Development',
        totalLessons: 42,
      ),
      const SearchResult(
        id: 'c2',
        title: 'Dart Programming Fundamentals',
        description: 'Master the Dart programming language from scratch',
        instructorName: 'Mike Chen',
        rating: 4.6,
        ratingCount: 890,
        price: 39.99,
        category: 'Programming',
        totalLessons: 28,
      ),
      const SearchResult(
        id: 'c3',
        title: 'Advanced State Management',
        description: 'Provider, BLoC, Riverpod, and more',
        instructorName: 'Emily Davis',
        rating: 4.7,
        ratingCount: 560,
        price: 59.99,
        category: 'Mobile Development',
        totalLessons: 35,
      ),
      const SearchResult(
        id: 'c4',
        title: 'UI/UX Design Principles',
        description: 'Create beautiful, user-friendly interfaces',
        instructorName: 'Alex Kim',
        rating: 4.5,
        ratingCount: 720,
        price: 44.99,
        category: 'Design',
        totalLessons: 20,
      ),
      const SearchResult(
        id: 'c5',
        title: 'RESTful API Development',
        description: 'Build scalable backend services',
        instructorName: 'James Wilson',
        rating: 4.4,
        ratingCount: 430,
        price: 54.99,
        category: 'Backend',
        totalLessons: 30,
      ),
      const SearchResult(
        id: 'c6',
        title: 'Machine Learning with Python',
        description: 'Introduction to ML algorithms and TensorFlow',
        instructorName: 'Dr. David Lee',
        rating: 4.8,
        ratingCount: 1560,
        price: 69.99,
        category: 'Data Science',
        totalLessons: 45,
      ),
      const SearchResult(
        id: 'c7',
        title: 'iOS Development with Swift',
        description: 'Build native iOS applications',
        instructorName: 'Lisa Park',
        rating: 4.9,
        ratingCount: 980,
        price: 64.99,
        category: 'Mobile Development',
        totalLessons: 50,
      ),
      const SearchResult(
        id: 'c8',
        title: 'Firebase for Mobile Apps',
        description: 'Authentication, Firestore, and Cloud Functions',
        instructorName: 'Nina Lee',
        rating: 4.7,
        ratingCount: 670,
        price: 49.99,
        category: 'Backend',
        totalLessons: 25,
      ),
    ];
    final lowerQuery = query.toLowerCase();
    return allCourses.where((c) {
      return c.title.toLowerCase().contains(lowerQuery) ||
          (c.description?.toLowerCase().contains(lowerQuery) ?? false) ||
          (c.category?.toLowerCase().contains(lowerQuery) ?? false) ||
          (c.instructorName?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final SearchProvider _provider;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _provider = SearchProvider();
    _provider.addListener(_onProviderUpdate);
    _provider.loadRecentSearches();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onProviderUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderUpdate);
    _searchController.dispose();
    _focusNode.dispose();
    _provider.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _provider.searchDebounced(value);
  }

  void _onSearchSubmitted(String value) {
    _provider.searchImmediate(value);
  }

  void _selectRecentSearch(String query) {
    _searchController.text = query;
    _provider.searchImmediate(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          onSubmitted: _onSearchSubmitted,
          decoration: InputDecoration(
            hintText: 'Search courses...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          textInputAction: TextInputAction.search,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _provider.clearResults();
                _focusNode.requestFocus();
              },
            ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_provider.isSearching && _searchController.text.isNotEmpty) {
      return _buildLoading(theme);
    }
    if (_provider.error != null) {
      return _buildError(theme);
    }
    if (_provider.hasSearched && _provider.results.isEmpty) {
      return _buildNoResults(theme);
    }
    if (_provider.hasSearched && _provider.results.isNotEmpty) {
      return _buildResults(theme);
    }
    return _buildRecentSearches(theme);
  }

  Widget _buildRecentSearches(ThemeData theme) {
    if (_provider.recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 80, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('Search for courses', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('Find courses by title, category, or instructor',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7))),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text('Recent Searches', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clear Search History?'),
                      content: const Text('This will remove all your recent searches.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _provider.clearAllSearches();
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _provider.recentSearches.length,
            itemBuilder: (context, index) {
              final query = _provider.recentSearches[index];
              return Dismissible(
                key: ValueKey(query),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _provider.removeRecentSearch(query),
                child: ListTile(
                  leading: const Icon(Icons.history, size: 20),
                  title: Text(query),
                  trailing: IconButton(
                    icon: const Icon(Icons.north_west, size: 16),
                    onPressed: () => _selectRecentSearch(query),
                  ),
                  onTap: () => _selectRecentSearch(query),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResults(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _provider.results.length,
      itemBuilder: (context, index) {
        final result = _provider.results[index];
        return _SearchResultCard(
          result: result,
          onTap: () => Navigator.pushNamed(context, '/course-detail', arguments: result.id),
        );
      },
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Searching...'),
        ],
      ),
    );
  }

  Widget _buildNoResults(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 80, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('No results found', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('Try different keywords', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7))),
        ],
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
          FilledButton(onPressed: () => _provider.searchImmediate(_searchController.text), child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;

  const _SearchResultCard({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 100,
              height: 80,
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              child: result.thumbnailUrl != null
                  ? Image.network(result.thumbnailUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(theme))
                  : _placeholder(theme),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.title,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    if (result.instructorName != null)
                      Text(result.instructorName!,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (result.rating != null) ...[
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text('${result.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                        ],
                        if (result.price != null)
                          Text('\$${result.price!.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
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

  Widget _placeholder(ThemeData theme) {
    return Center(child: Icon(Icons.play_circle_outline, size: 32, color: theme.colorScheme.primary.withOpacity(0.5)));
  }
}
