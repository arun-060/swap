import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() => _isLoading = true);
      final supabaseClient = supabase.Supabase.instance.client;
      final user = supabaseClient.auth.currentUser;
      if (user == null) return;

      final response = await supabaseClient
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      setState(() {
        _userProfile = response;
        _notificationsEnabled = response['notifications_enabled'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateNotificationSettings(bool enabled) async {
    try {
      final supabaseClient = supabase.Supabase.instance.client;
      final user = supabaseClient.auth.currentUser;
      if (user == null) return;

      await supabaseClient.from('profiles').update({
        'notifications_enabled': enabled,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      setState(() => _notificationsEnabled = enabled);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating notification settings: $e')),
        );
      }
    }
  }

  Future<void> _reportIssue() async {
    const email = 'support@yourapp.com'; // Replace with your support email
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Issue Report - SWAP App',
    );
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email client')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await supabase.Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
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

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(languageProvider.getTranslatedText('settings')),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getTranslatedText('settings')),
      ),
      body: ListView(
        children: [
          // Profile Section
          if (_userProfile != null)
            ListTile(
              leading: CircleAvatar(
                backgroundImage: _userProfile!['avatar_url'] != null
                    ? NetworkImage(_userProfile!['avatar_url'])
                    : null,
                child: _userProfile!['avatar_url'] == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(_userProfile!['full_name'] ?? 'User'),
              subtitle: Text(_userProfile!['email'] ?? ''),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
          const Divider(),

          // Language Section
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(languageProvider.getTranslatedText('language')),
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

          // Notifications Section
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(languageProvider.getTranslatedText('notifications')),
            subtitle: Text(
              languageProvider.getTranslatedText('notification_settings'),
            ),
            value: _notificationsEnabled,
            onChanged: _updateNotificationSettings,
          ),
          const Divider(),

          // Location Settings
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(languageProvider.getTranslatedText('location')),
            subtitle: Text(
              languageProvider.getTranslatedText('location_settings'),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/location'),
          ),
          const Divider(),

          // Help Center
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(languageProvider.getTranslatedText('help_center')),
            subtitle: Text(languageProvider.getTranslatedText('get_help')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/help'),
          ),
          const Divider(),

          // Report Issue
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: Text(languageProvider.getTranslatedText('report_issue')),
            subtitle: Text(
              languageProvider.getTranslatedText('report_issue_desc'),
            ),
            onTap: _reportIssue,
          ),
          const Divider(),

          // About
          ListTile(
            leading: const Icon(Icons.info_outline),
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

          // Sign Out
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
                      _signOut();
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