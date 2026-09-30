import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  AppConfig.load();

  final storageService = StorageService();
  try {
    await storageService.init();
  } catch (_) {}

  final apiService = ApiService(storageService: storageService);
  ApiService.setInstance(apiService);

  final authService = AuthService(
    apiService: apiService,
    storageService: storageService,
  );
  AuthService.setInstance(authService);

  try {
    await authService.autoLogin();
  } catch (_) {}

  runZonedGuarded(() {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authService),
          Provider<ApiService>.value(value: apiService),
          Provider<StorageService>.value(value: storageService),
          Provider<NotificationService>.value(value: NotificationService()),
          Provider<AppConfig>.value(value: AppConfig.instance),
        ],
        child: const PagePilotApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('Uncaught error: $error');
  });
}
