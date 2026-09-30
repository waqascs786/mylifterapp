import '../config/app_config.dart';

class ApiConfig {
  ApiConfig._();

  static String get baseUrl => AppConfig.instance.apiBaseUrl;

  static const Map<String, String> endpoints = {
    'auth': '/pagepilot/v1/app/auth/login',
    'forgotPassword': '/pagepilot/v1/app/auth/forgot-password',
    'profile': '/pagepilot/v1/app/student/profile',
    'enrolledCourses': '/pagepilot/v1/app/student/enrolled-courses',
    'courses': '/pagepilot/v1/app/courses',
    'courseDetail': '/pagepilot/v1/app/courses/{id}',
    'courseCurriculum': '/pagepilot/v1/app/courses/{id}/curriculum',
    'courseReviews': '/pagepilot/v1/app/courses/{id}/reviews',
    'courseEnroll': '/pagepilot/v1/app/courses/{id}/enroll',
    'courseProgress': '/pagepilot/v1/app/courses/{id}/progress',
    'lesson': '/pagepilot/v1/app/lessons/{id}',
    'lessonComplete': '/pagepilot/v1/app/lessons/{id}/complete',
    'quiz': '/pagepilot/v1/app/quizzes/{id}',
    'quizSubmit': '/pagepilot/v1/app/quizzes/{id}/submit',
    'certificates': '/pagepilot/v1/app/certificates',
    'wishlist': '/pagepilot/v1/app/wishlist',
    'wishlistItem': '/pagepilot/v1/app/wishlist/{id}',
    'categories': '/pagepilot/v1/app/categories',
    'search': '/pagepilot/v1/app/search',
    'instructors': '/pagepilot/v1/app/instructors',
  };

  static String buildUrl(String endpointKey, {Map<String, String>? pathParams}) {
    String? endpoint = endpoints[endpointKey];
    if (endpoint == null) {
      throw ArgumentError('Unknown endpoint key: $endpointKey');
    }

    if (pathParams != null) {
      pathParams.forEach((key, value) {
        endpoint = endpoint!.replaceAll('{$key}', value);
      });
    }

    return '$baseUrl$endpoint';
  }

  static Map<String, String> authHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Map<String, String> buildHeaders({String? token, Map<String, String>? extra}) {
    final headers = authHeaders(token: token);
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  static Duration get timeout => const Duration(seconds: 30);

  static int get maxRetries => 3;

  static Duration retryDelay(int attempt) {
    return Duration(seconds: (1 << attempt));
  }
}
