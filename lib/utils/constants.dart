import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  static const Duration cacheExpiry = Duration(hours: 1);

  static const String imagePlaceholderUrl =
      'https://via.placeholder.com/400x300.png?text=No+Image';
  static const String defaultAvatarUrl =
      'https://via.placeholder.com/100.png?text=U';

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String settingsKey = 'app_settings';
  static const String cacheKey = 'app_cache';

  static const String homeRoute = '/home';
  static const String coursesRoute = '/courses';
  static const String courseDetailRoute = '/course-detail';
  static const String lessonRoute = '/lesson';
  static const String quizRoute = '/quiz';
  static const String profileRoute = '/profile';
  static const String settingsRoute = '/settings';
  static const String searchRoute = '/search';
  static const String wishlistRoute = '/wishlist';
  static const String certificatesRoute = '/certificates';
  static const String progressRoute = '/progress';
  static const String loginRoute = '/login';
  static const String splashRoute = '/';

  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double mediumPadding = 12.0;
  static const double largePadding = 24.0;

  static const double borderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;

  static const double defaultFontSize = 16.0;
  static const double smallFontSize = 12.0;
  static const double mediumFontSize = 14.0;
  static const double largeFontSize = 20.0;
  static const double extraLargeFontSize = 24.0;

  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB00020);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);

  static const int maxRecentSearches = 10;
  static const int defaultPageSize = 20;
  static const double maxRating = 5.0;
  static const int maxQuizAttempts = 3;
  static const int passingGrade = 70;
}
