import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/courses/course_detail_screen.dart';
import 'screens/lessons/lesson_screen.dart';
import 'screens/quiz/quiz_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/my_courses_screen.dart';
import 'screens/wishlist/wishlist_screen.dart';
import 'screens/settings/settings_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class PagePilotApp extends StatelessWidget {
  const PagePilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        return MaterialApp(
          title: AppConfig.instance.appName,
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: ThemeMode.system,
          initialRoute: SplashScreen.route,
          routes: {
            SplashScreen.route: (_) => const SplashScreen(),
            HomeScreen.route: (_) => const HomeScreen(),
            LoginScreen.route: (_) => const LoginScreen(),
            ProfileScreen.route: (_) => const ProfileScreen(),
            WishlistScreen.route: (_) => const WishlistScreen(),
            SettingsScreen.route: (_) => const SettingsScreen(),
          },
          onGenerateRoute: (settings) {
            final args = settings.arguments;
            switch (settings.name) {
              case '/course-detail':
                final courseId = args is String ? args : args?.toString() ?? '0';
                return MaterialPageRoute(
                  builder: (_) => CourseDetailScreen(courseId: courseId),
                );
              case '/lesson':
                if (args is Map<String, dynamic>) {
                  return MaterialPageRoute(
                    builder: (_) => LessonScreen(
                      courseId: args['courseId']?.toString() ?? '0',
                      courseTitle: args['courseTitle']?.toString() ?? '',
                      lessonId: args['lessonId']?.toString(),
                    ),
                  );
                }
                return MaterialPageRoute(
                  builder: (_) => const LessonScreen(courseId: '0', courseTitle: ''),
                );
              case '/my-courses':
                return MaterialPageRoute(
                  builder: (_) => const MyCoursesScreen(),
                );
              case '/quiz':
                if (args is Map<String, dynamic>) {
                  return MaterialPageRoute(
                    builder: (_) => QuizScreen(
                      quizId: args['quizId']?.toString() ?? '0',
                      courseTitle: args['courseTitle']?.toString() ?? '',
                    ),
                  );
                }
                return MaterialPageRoute(
                  builder: (_) => const QuizScreen(quizId: '0', courseTitle: ''),
                );
              default:
                return null;
            }
          },
        );
      },
    );
  }
}
