import 'package:daily/screens/home_screen/home_screen.dart';
import 'package:daily/utils/app_theme.dart';
import 'package:daily/utils/notification_service.dart';
import 'package:daily/utils/service_locator.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Service Locator (GetIt)
  await setupServiceLocator();

  // Initialize Local Notifications
  await getIt<NotificationService>().init();

  runApp(const DailyApp());
}

class DailyApp extends StatelessWidget {
  const DailyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}
