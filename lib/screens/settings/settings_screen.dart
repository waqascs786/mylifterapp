import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class AppSettings {
  final bool darkMode;
  final int themeColorValue;
  final bool pushNotifications;
  final String languageCode;

  const AppSettings({
    this.darkMode = false,
    this.themeColorValue = 0xFF6750A4,
    this.pushNotifications = true,
    this.languageCode = 'en',
  });

  AppSettings copyWith({
    bool? darkMode,
    int? themeColorValue,
    bool? pushNotifications,
    String? languageCode,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      themeColorValue: themeColorValue ?? this.themeColorValue,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  Map<String, dynamic> toJson() => {
        'darkMode': darkMode,
        'themeColorValue': themeColorValue,
        'pushNotifications': pushNotifications,
        'languageCode': languageCode,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      darkMode: json['darkMode'] as bool? ?? false,
      themeColorValue: json['themeColorValue'] as int? ?? 0xFF6750A4,
      pushNotifications: json['pushNotifications'] as bool? ?? true,
      languageCode: json['languageCode'] as String? ?? 'en',
    );
  }
}

class LanguageOption {
  final String code;
  final String name;
  final String nativeName;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
  });
}

// ─── Settings Provider ───────────────────────────────────────────────────────

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = const AppSettings();
  bool _isLoading = false;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  static const List<LanguageOption> availableLanguages = [
    LanguageOption(code: 'en', name: 'English', nativeName: 'English'),
    LanguageOption(code: 'es', name: 'Spanish', nativeName: 'Español'),
    LanguageOption(code: 'fr', name: 'French', nativeName: 'Français'),
    LanguageOption(code: 'de', name: 'German', nativeName: 'Deutsch'),
    LanguageOption(code: 'ar', name: 'Arabic', nativeName: 'العربية'),
    LanguageOption(code: 'zh', name: 'Chinese', nativeName: '中文'),
    LanguageOption(code: 'ja', name: 'Japanese', nativeName: '日本語'),
    LanguageOption(code: 'ko', name: 'Korean', nativeName: '한국어'),
    LanguageOption(code: 'pt', name: 'Portuguese', nativeName: 'Português'),
    LanguageOption(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
  ];

  static const List<Color> themeColors = [
    Colors.purple,
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
    Colors.brown,
  ];

  String get currentLanguageName {
    final option = availableLanguages.firstWhere(
      (l) => l.code == _settings.languageCode,
      orElse: () => availableLanguages.first,
    );
    return option.name;
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('app_settings');
      if (json != null) {
        _settings = AppSettings.fromJson(
          jsonDecode(json) as Map<String, dynamic>,
        );
      }
    } catch (_) {}
    finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_settings', jsonEncode(_settings.toJson()));
    } catch (_) {}
  }

  Future<void> toggleDarkMode(bool value) async {
    _settings = _settings.copyWith(darkMode: value);
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setThemeColor(Color color) async {
    _settings = _settings.copyWith(themeColorValue: color.value);
    notifyListeners();
    await _saveSettings();
  }

  Future<void> togglePushNotifications(bool value) async {
    _settings = _settings.copyWith(pushNotifications: value);
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setLanguage(String code) async {
    _settings = _settings.copyWith(languageCode: code);
    notifyListeners();
    await _saveSettings();
  }
}

// ─── Settings Screen ─────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  static const route = '/settings';
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = SettingsProvider();
    _provider.addListener(_onProviderUpdate);
    _provider.loadSettings();
  }

  void _onProviderUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderUpdate);
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = _provider.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Appearance Section ──
          _SectionHeader(title: 'Appearance', theme: theme),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: 'Use dark theme',
            trailing: Switch(
              value: settings.darkMode,
              onChanged: _provider.toggleDarkMode,
            ),
          ),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: 'Theme Color',
            subtitle: _getThemeColorName(settings.themeColorValue),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Color(settings.themeColorValue),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
            ),
            onTap: () => _showColorPicker(context),
          ),

          const Divider(height: 1, indent: 56),

          // ── Notifications Section ──
          _SectionHeader(title: 'Notifications', theme: theme),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            subtitle: settings.pushNotifications ? 'Enabled' : 'Disabled',
            trailing: Switch(
              value: settings.pushNotifications,
              onChanged: _provider.togglePushNotifications,
            ),
          ),

          const Divider(height: 1, indent: 56),

          // ── Language Section ──
          _SectionHeader(title: 'Language', theme: theme),
          _SettingsTile(
            icon: Icons.language,
            title: 'App Language',
            subtitle: _provider.currentLanguageName,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguagePicker(context),
          ),

          const Divider(height: 1, indent: 56),

          // ── Account Section ──
          _SectionHeader(title: 'Account', theme: theme),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Update your password',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChangePasswordDialog(context),
          ),
          _SettingsTile(
            icon: Icons.delete_outline,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account',
            titleColor: Colors.red,
            onTap: () => _showDeleteAccountDialog(context),
          ),

          const Divider(height: 1, indent: 56),

          // ── About Section ──
          _SectionHeader(title: 'About', theme: theme),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: '1.0.0 (Build 42)',
          ),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Developer',
            subtitle: 'LifterMobileApp Team',
          ),
          _SettingsTile(
            icon: Icons.code,
            title: 'Open Source Licenses',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'LifterMobileApp',
              applicationVersion: '1.0.0',
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _getThemeColorName(int colorValue) {
    final color = Color(colorValue);
    for (final c in SettingsProvider.themeColors) {
      if (c.value == color.value) {
        return _colorName(c);
      }
    }
    return 'Custom';
  }

  String _colorName(Color color) {
    if (color == Colors.purple) return 'Purple';
    if (color == Colors.blue) return 'Blue';
    if (color == Colors.teal) return 'Teal';
    if (color == Colors.green) return 'Green';
    if (color == Colors.orange) return 'Orange';
    if (color == Colors.red) return 'Red';
    if (color == Colors.pink) return 'Pink';
    if (color == Colors.indigo) return 'Indigo';
    if (color == Colors.cyan) return 'Cyan';
    if (color == Colors.brown) return 'Brown';
    return 'Custom';
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme Color',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: SettingsProvider.themeColors.map((color) {
                final isSelected =
                    _provider.settings.themeColorValue == color.value;
                return GestureDetector(
                  onTap: () {
                    _provider.setThemeColor(color);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.onSurface,
                              width: 3,
                            )
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 24)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Language',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: SettingsProvider.availableLanguages.length,
                itemBuilder: (context, index) {
                  final lang = SettingsProvider.availableLanguages[index];
                  final isSelected =
                      _provider.settings.languageCode == lang.code;
                  return ListTile(
                    title: Text(lang.name),
                    subtitle: Text(lang.nativeName),
                    trailing: isSelected
                        ? Icon(
                            Icons.check,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    selected: isSelected,
                    onTap: () {
                      _provider.setLanguage(lang.code);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Implement password change API
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password updated successfully')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();
    bool confirmed = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded,
              size: 48, color: Colors.red),
          title: const Text('Delete Account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This action cannot be undone. All your data will be permanently deleted.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Enter your password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: confirmed,
                onChanged: (value) {
                  setDialogState(() => confirmed = value ?? false);
                },
                title: const Text(
                  'I understand this action is irreversible',
                  style: TextStyle(fontSize: 12),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: confirmed && passwordController.text.isNotEmpty
                  ? () {
                      // TODO: Implement account deletion API
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account deletion request submitted'),
                        ),
                      );
                    }
                  : null,
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const _SectionHeader({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ─── Settings Tile ───────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(
        title,
        style: TextStyle(color: titleColor),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
