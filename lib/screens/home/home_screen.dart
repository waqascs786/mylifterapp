import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/auth_service.dart';
import '../profile/my_courses_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  static const route = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await AuthService.instance.currentUser;
      if (mounted) setState(() => _user = user);
    } catch (_) {}
  }

  void _onTabTapped(int index) {
    setState(() => _currentTabIndex = index);
  }

  /// Tab bodies in the same order as [_buildNavItems].
  List<Widget> _buildTabs() {
    final config = AppConfig.of(context);
    final tabs = <Widget>[
      const MyCoursesScreen(),
    ];
    if (config.showProfileTab) {
      tabs.add(const ProfileScreen());
    }
    if (config.showSettingsTab) {
      tabs.add(const SettingsScreen());
    }
    return tabs;
  }

  List<BottomNavigationBarItem> _buildNavItems(AppConfig config) {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.menu_book_outlined),
        activeIcon: Icon(Icons.menu_book),
        label: 'My Courses',
      ),
    ];

    if (config.showProfileTab) {
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'));
    }
    if (config.showSettingsTab) {
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.of(context);
    final tabs = _buildTabs();
    final index = _currentTabIndex < tabs.length ? _currentTabIndex : 0;
    final isInstructor = _user?['role'] == 'instructor';

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: index,
          children: tabs,
        ),
      ),
      floatingActionButton: isInstructor
          ? FloatingActionButton(
              onPressed: () {},
              backgroundColor: config.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: config.primaryColor,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity( 0.4),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 8,
        items: _buildNavItems(config),
      ),
    );
  }
}
