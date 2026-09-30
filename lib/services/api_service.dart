import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/course.dart';
import 'storage_service.dart';

class CourseListResult {
  final List<Course> courses;
  final bool hasMore;

  const CourseListResult({required this.courses, required this.hasMore});
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message (statusCode: $statusCode)';
}

class ApiService {
  static ApiService? _staticInstance;

  static ApiService get instance {
    if (_staticInstance == null) {
      throw StateError('ApiService not initialized. Call setInstance() first.');
    }
    return _staticInstance!;
  }

  static void setInstance(ApiService svc) {
    _staticInstance = svc;
  }

  final StorageService _storageService;
  int _maxRetries;

  ApiService({
    required StorageService storageService,
    int maxRetries = 3,
  })  : _storageService = storageService,
        _maxRetries = maxRetries;

  String? get _token => _storageService.getString('auth_token');
  String? get _userId => _storageService.getString('user_id');
  String? get _username => _storageService.getString('username');

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['X-PagePilot-User'] = _username ?? '';
      headers['X-PagePilot-Token'] = _token!;
    }
    return headers;
  }

  Future<Map<String, dynamic>> get(
    String endpointKey, {
    Map<String, String>? pathParams,
    Map<String, String>? queryParams,
  }) async {
    return _request(
      method: 'GET',
      url: ApiConfig.buildUrl(endpointKey, pathParams: pathParams),
      queryParams: queryParams,
    );
  }

  Future<Map<String, dynamic>> post(
    String endpointKey, {
    Map<String, String>? pathParams,
    Map<String, dynamic>? body,
  }) async {
    return _request(
      method: 'POST',
      url: ApiConfig.buildUrl(endpointKey, pathParams: pathParams),
      body: body,
    );
  }

  Future<Map<String, dynamic>> put(
    String endpointKey, {
    Map<String, String>? pathParams,
    Map<String, dynamic>? body,
  }) async {
    return _request(
      method: 'PUT',
      url: ApiConfig.buildUrl(endpointKey, pathParams: pathParams),
      body: body,
    );
  }

  Future<Map<String, dynamic>> delete(
    String endpointKey, {
    Map<String, String>? pathParams,
  }) async {
    return _request(
      method: 'DELETE',
      url: ApiConfig.buildUrl(endpointKey, pathParams: pathParams),
    );
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String url,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    if (url.isEmpty || !url.startsWith('http')) {
      throw ApiException('API URL not configured. Please check app settings.', statusCode: 0);
    }

    Uri uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
      throw ApiException('Invalid API URL: $url', statusCode: 0);
    }
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    http.Response? response;
    Exception? lastException;

    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          final delay = ApiConfig.retryDelay(attempt - 1);
          _log('Retrying in ${delay.inSeconds}s (attempt $attempt/$_maxRetries)');
          await Future.delayed(delay);
        }

        final requestHeaders = Map<String, String>.from(_headers);
        if (method == 'GET') {
          requestHeaders.remove('Content-Type');
        }

        final request = http.Request(method, uri);
        request.headers.addAll(requestHeaders);

        if (body != null) {
          request.body = jsonEncode(body);
        }

        _log('$method $uri');
        if (body != null) {
          _log('Body: ${jsonEncode(body)}');
        }

        final streamedResponse = await request.send().timeout(
          ApiConfig.timeout,
          onTimeout: () => throw TimeoutException(
            'Request to $url timed out after ${ApiConfig.timeout.inSeconds}s',
          ),
        );

        response = await http.Response.fromStream(streamedResponse);

        _log('Response [${response.statusCode}]: ${response.body}');

        lastException = null;
        break;
      } on TimeoutException catch (e) {
        lastException = e;
        _log('Timeout on attempt ${attempt + 1}: $e');
        if (attempt == _maxRetries) break;
      } catch (e) {
        lastException = e as Exception;
        _log('Error on attempt ${attempt + 1}: $e');
        if (attempt == _maxRetries) break;
      }
    }

    if (lastException != null) {
      throw lastException;
    }

    return _handleResponse(response!);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return {'data': response.body};
      }
    }

    String message;
    dynamic data;

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['message'] as String? ?? body['error'] as String? ?? 'Unknown error';
      data = body;
    } catch (_) {
      message = response.body.isNotEmpty ? response.body : 'Unknown error';
    }

    throw ApiException(message, statusCode: response.statusCode, data: data);
  }

  void _log(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'ApiService');
    }
  }

  // ── Course endpoints ──

  Future<CourseListResult> getCourses({
    int page = 1,
    int perPage = 20,
    String? category,
    String? search,
    Map<String, String>? params,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (category != null) queryParams['category'] = category;
    if (search != null) queryParams['search'] = search;
    if (params != null) queryParams.addAll(params);

    final result = await get('courses', queryParams: queryParams);
    final list = result['data'] as List<dynamic>? ?? [];
    final courses = list
        .map((e) => Course.fromJson(e as Map<String, dynamic>))
        .toList();
    final hasMore = result['hasMore'] as bool? ?? result['has_more'] as bool? ?? false;
    return CourseListResult(courses: courses, hasMore: hasMore);
  }

  Future<List<Course>> getFeaturedCourses() async {
    final result = await getCourses();
    return result.courses;
  }

  Future<List<Course>> getPopularCourses() async {
    final result = await getCourses();
    return result.courses;
  }

  Future<List<Course>> getEnrolledCourses() async {
    final result = await get('enrolledCourses');
    final list = result['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => Course.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    return post('forgotPassword', body: {'email': email});
  }

  Future<Map<String, dynamic>> getCourseDetail(int courseId) async {
    return get('courseDetail', pathParams: {'id': courseId.toString()});
  }

  Future<List<dynamic>> getCourseReviews(int courseId) async {
    final result = await get('courseReviews', pathParams: {'id': courseId.toString()});
    return result['data'] as List<dynamic>? ?? [];
  }

  Future<void> enrollCourse(int courseId) async {
    await post('courseEnroll', pathParams: {'id': courseId.toString()});
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final result = await get('categories');
    final list = result['data'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getCourse(String id) async {
    return get('courseDetail', pathParams: {'id': id});
  }

  Future<List<dynamic>> getLessons(String courseId) async {
    final result = await get('courseCurriculum', pathParams: {'id': courseId});
    return result['data'] as List<dynamic>? ?? [];
  }

  Future<List<dynamic>> getQuizzes(String courseId) async {
    final result = await get('courseCurriculum', pathParams: {'id': courseId});
    return result['data'] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> getCourseProgress(String courseId) async {
    return get('courseProgress', pathParams: {'id': courseId});
  }

  Future<Map<String, dynamic>> updateProgress(
    String courseId,
    Map<String, dynamic> progressData,
  ) async {
    return post(
      'courseProgress',
      pathParams: {'id': courseId},
      body: progressData,
    );
  }

  // ── Auth endpoints ──

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final result = await post('auth', body: {
      'username': email,
      'password': password,
    });

    if (result['success'] == true && result['data'] != null) {
      final data = result['data'] as Map<String, dynamic>;
      final token = data['token'] as String?;
      final userId = data['id']?.toString();
      final username = data['username'] as String?;
      if (token != null) {
        await _storageService.saveString('auth_token', token);
      }
      if (userId != null) {
        await _storageService.saveString('user_id', userId);
      }
      if (username != null) {
        await _storageService.saveString('username', username);
      }
    }

    return result;
  }


  Future<void> logout() async {
    await _storageService.remove('auth_token');
    await _storageService.remove('user_data');
  }

  // ── Profile endpoints ──

  Future<Map<String, dynamic>> getProfile() async {
    final result = await get('profile');
    if (result['success'] == true && result['data'] != null) {
      return result['data'] as Map<String, dynamic>;
    }
    return result;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    return put('updateProfile', body: data);
  }

  // ── Wishlist endpoints ──

  Future<List<dynamic>> getWishlist() async {
    final result = await get('wishlist');
    return result['data'] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> addToWishlist(String courseId) async {
    return post('wishlistItem', pathParams: {'id': courseId});
  }

  Future<Map<String, dynamic>> removeFromWishlist(String courseId) async {
    return delete('wishlistItem', pathParams: {'id': courseId});
  }

  // ── Quiz endpoints ──

  Future<Map<String, dynamic>> getQuiz(String quizId) async {
    final result = await get('quiz', pathParams: {'id': quizId});
    final data = result['data'];
    if (result['success'] == true && data is Map<String, dynamic>) {
      return data;
    }
    throw ApiException(
      result['message'] as String? ?? 'Failed to load quiz.',
      statusCode: 0,
    );
  }

  Future<Map<String, dynamic>> submitQuizAnswers(
    String quizId,
    Map<String, dynamic> answers,
  ) async {
    final result = await post(
      'quizSubmit',
      pathParams: {'id': quizId},
      body: {'answers': answers},
    );
    final data = result['data'];
    if (result['success'] == true && data is Map<String, dynamic>) {
      return data;
    }
    throw ApiException(
      result['message'] as String? ?? 'Failed to submit quiz.',
      statusCode: 0,
    );
  }
}
