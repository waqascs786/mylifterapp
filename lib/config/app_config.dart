import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Category {
  final String name;
  final String icon;
  final int? id;

  const Category({required this.name, this.icon = '', this.id});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      id: json['id'] as int?,
    );
  }
}

class AppConfig {
  AppConfig._({
    required this.appName,
    required this.packageName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.bgColor,
    required this.textColor,
    required this.primaryColorDark,
    this.logoAsset = '',
    this.appTagline = '',
    required this.siteUrl,
    required this.apiBaseUrl,
    this.wpBaseUrl = '',
    this.categories = const [],
    this.screens = const {},
    this.features = const {},
    this.enableGoogleLogin = true,
    this.enableFacebookLogin = true,
    this.showProfileTab = true,
    this.showSettingsTab = true,
  });

  static AppConfig? _instance;

  static AppConfig get instance {
    if (_instance == null) {
      throw StateError('AppConfig not initialized. Call AppConfig.load() first.');
    }
    return _instance!;
  }

  static AppConfig of(BuildContext context) {
    try {
      return Provider.of<AppConfig>(context, listen: false);
    } catch (_) {
      return instance;
    }
  }

  static Future<void> load() async {
    _instance = AppConfig._(
      appName: 'My Lifter App',
      packageName: 'com.lftlms.app',
      primaryColor: Color(0xFF0073AA),
      secondaryColor: Color(0xFF005177),
      accentColor: Color(0xFF00AADC),
      bgColor: Color(0xFFFFFFFF),
      textColor: Color(0xFF333333),
      primaryColorDark: Color(0xFF0073AA).withOpacity(0.8),
      siteUrl: 'https://the-tvpp.com',
      apiBaseUrl: 'https://the-tvpp.com/wp-json',
      wpBaseUrl: 'https://the-tvpp.com',
      logoAsset: 'assets/images/app_icon.png',
      appTagline: 'My Lifter App',
      categories: [],
      screens: {
        'home': true,
        'courses': true,
        'wishlist': true,
        'profile': true,
        'quiz': true,
        'search': true,
        'settings': true,
      },
      features: {
        'darkMode': true,
        'googleLogin': false,
        'facebookLogin': false,
      },
    );
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig._(
      appName: json['appName'] as String? ?? 'LifterMobileApp',
      packageName: json['packageName'] as String? ?? 'com.pagepilot.app',
      primaryColor: _parseColor(json['primaryColor'] as String? ?? '#6C63FF'),
      secondaryColor: _parseColor(json['secondaryColor'] as String? ?? '#FF6584'),
      accentColor: _parseColor(json['accentColor'] as String? ?? '#00C9A7'),
      bgColor: _parseColor(json['bgColor'] as String? ?? '#FFFFFF'),
      textColor: _parseColor(json['textColor'] as String? ?? '#1E1E2D'),
      primaryColorDark: _parseColor(json['primaryColor'] as String? ?? '#6C63FF').withOpacity(0.8),
      siteUrl: json['siteUrl'] as String? ?? '',
      apiBaseUrl: json['apiBaseUrl'] as String? ?? '',
      wpBaseUrl: json['wpBaseUrl'] as String? ?? '',
      logoAsset: json['logoAsset'] as String? ?? '',
      appTagline: json['appTagline'] as String? ?? 'Learn anytime, anywhere',
      categories: (json['categories'] as List<dynamic>?)?.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      screens: json['screens'] != null ? Map<String, bool>.from(json['screens'] as Map) : {},
      features: json['features'] != null ? Map<String, bool>.from(json['features'] as Map) : {},
      enableGoogleLogin: json['enableGoogleLogin'] as bool? ?? true,
      enableFacebookLogin: json['enableFacebookLogin'] as bool? ?? true,
      showProfileTab: json['showProfileTab'] as bool? ?? true,
      showSettingsTab: json['showSettingsTab'] as bool? ?? true,
    );
  }

  final String appName;
  final String packageName;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color bgColor;
  final Color textColor;
  final Color primaryColorDark;
  final String logoAsset;
  final String appTagline;
  final String siteUrl;
  final String apiBaseUrl;
  final String wpBaseUrl;
  final List<Category> categories;
  final Map<String, bool> screens;
  final Map<String, bool> features;
  final bool enableGoogleLogin;
  final bool enableFacebookLogin;
  final bool showProfileTab;
  final bool showSettingsTab;

  bool isScreenEnabled(String screenName) => screens[screenName] ?? false;
  bool isFeatureEnabled(String featureName) => features[featureName] ?? false;

  static Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF';
    return Color(int.parse(hex, radix: 16));
  }
}