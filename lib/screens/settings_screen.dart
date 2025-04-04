import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getTranslatedText('settings')),
      ),
      body: ListView(
        children: [
          // Profile Section
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(languageProvider.getTranslatedText('profile')),
            subtitle: Text(languageProvider.getTranslatedText('manage_profile')),
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          const Divider(),

          // Notifications Section
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(languageProvider.getTranslatedText('notifications')),
            subtitle: Text(
              languageProvider.getTranslatedText('notification_settings'),
            ),
            onTap: () => Navigator.pushNamed(context, '/notifications'),
          ),
          const Divider(),

          // Location Section
          ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(languageProvider.getTranslatedText('location')),
            subtitle: Text(languageProvider.getTranslatedText('location_settings')),
            onTap: () => Navigator.pushNamed(context, '/location'),
          ),
          const Divider(),

          // Language Section
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(languageProvider.getTranslatedText('language')),
            subtitle: Text(languageProvider.getTranslatedText('change_language')),
            trailing: DropdownButton<String>(
              value: languageProvider.currentLocale.languageCode,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  languageProvider.setLanguage(newValue);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: 'en',
                  child: Text('English'),
                ),
                DropdownMenuItem(
                  value: 'es',
                  child: Text('Español'),
                ),
                DropdownMenuItem(
                  value: 'hi',
                  child: Text('हिंदी'),
                ),
              ],
            ),
          ),
          const Divider(),

          // Theme Section
          ListTile(
            leading: const Icon(Icons.palette),
            title: Text(languageProvider.getTranslatedText('theme')),
            subtitle: Text(languageProvider.getTranslatedText('change_theme')),
            trailing: Switch(
              value: themeProvider.isDark,
              onChanged: (bool value) {
                themeProvider.toggleTheme();
              },
            ),
          ),
          const Divider(),

          // Help Center Section
          ListTile(
            leading: const Icon(Icons.help),
            title: Text(languageProvider.getTranslatedText('help_center')),
            subtitle: Text(languageProvider.getTranslatedText('get_help')),
            onTap: () => Navigator.pushNamed(context, '/help'),
          ),
          const Divider(),

          // About Section
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(languageProvider.getTranslatedText('about')),
            subtitle: Text(languageProvider.getTranslatedText('about_app')),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'SWAP',
              applicationVersion: '1.0.0',
              applicationIcon: Image.asset(
                'assets/images/swap_logo.png',
                height: 50,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.shopping_bag, size: 50);
                },
              ),
              children: [
                Text(languageProvider.getTranslatedText('app_description')),
              ],
            ),
          ),
          const Divider(),

          // Sign Out Section
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              languageProvider.getTranslatedText('logout'),
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(languageProvider.getTranslatedText('logout_confirm')),
                content: Text(
                  languageProvider.getTranslatedText('logout_message'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(languageProvider.getTranslatedText('cancel')),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _signOut(context);
                    },
                    child: Text(
                      languageProvider.getTranslatedText('logout'),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 