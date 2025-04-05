import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../providers/language_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _notifications = [];
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _smsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadNotificationSettings();
  }

  Future<void> _loadNotifications() async {
    final supabaseClient = supabase.Supabase.instance.client;
    final user = supabaseClient.auth.currentUser;
    if (user == null) return;

    try {
      setState(() => _isLoading = true);
      final response = await supabaseClient
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _notifications = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notifications: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadNotificationSettings() async {
    final supabaseClient = supabase.Supabase.instance.client;
    final user = supabaseClient.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabaseClient
          .from('notification_settings')
          .select()
          .eq('user_id', user.id)
          .single();

      setState(() {
        _pushEnabled = response['push_enabled'] ?? true;
        _emailEnabled = response['email_enabled'] ?? true;
        _smsEnabled = response['sms_enabled'] ?? false;
      });
    } catch (e) {
      print('Error loading notification settings: $e');
    }
  }

  Future<void> _updateNotificationSettings() async {
    final supabaseClient = supabase.Supabase.instance.client;
    final user = supabaseClient.auth.currentUser;
    if (user == null) return;

    try {
      await supabaseClient.from('notification_settings').upsert({
        'user_id': user.id,
        'push_enabled': _pushEnabled,
        'email_enabled': _emailEnabled,
        'sms_enabled': _smsEnabled,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification settings updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating settings: $e')),
        );
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    final supabaseClient = supabase.Supabase.instance.client;
    final user = supabaseClient.auth.currentUser;
    if (user == null) return;

    try {
      await supabaseClient
          .from('notifications')
          .delete()
          .eq('user_id', user.id);

      setState(() {
        _notifications.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications cleared')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing notifications: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getTranslatedText('notifications')),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearAllNotifications,
              tooltip: languageProvider.getTranslatedText('clear_all'),
            ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: languageProvider.getTranslatedText('notifications')),
                Tab(text: languageProvider.getTranslatedText('settings')),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Notifications Tab
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _notifications.isEmpty
                          ? Center(
                              child: Text(
                                languageProvider
                                    .getTranslatedText('no_notifications'),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _notifications.length,
                              itemBuilder: (context, index) {
                                final notification = _notifications[index];
                                return ListTile(
                                  leading: Icon(
                                    _getNotificationIcon(notification['type']),
                                  ),
                                  title: Text(notification['title']),
                                  subtitle: Text(notification['message']),
                                  trailing: Text(
                                    _formatDate(notification['created_at']),
                                  ),
                                );
                              },
                            ),

                  // Settings Tab
                  ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      SwitchListTile(
                        title: Text(
                          languageProvider.getTranslatedText('push_notifications'),
                        ),
                        subtitle: Text(
                          languageProvider
                              .getTranslatedText('push_notifications_desc'),
                        ),
                        value: _pushEnabled,
                        onChanged: (value) {
                          setState(() => _pushEnabled = value);
                          _updateNotificationSettings();
                        },
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: Text(
                          languageProvider.getTranslatedText('email_notifications'),
                        ),
                        subtitle: Text(
                          languageProvider
                              .getTranslatedText('email_notifications_desc'),
                        ),
                        value: _emailEnabled,
                        onChanged: (value) {
                          setState(() => _emailEnabled = value);
                          _updateNotificationSettings();
                        },
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: Text(
                          languageProvider.getTranslatedText('sms_notifications'),
                        ),
                        subtitle: Text(
                          languageProvider
                              .getTranslatedText('sms_notifications_desc'),
                        ),
                        value: _smsEnabled,
                        onChanged: (value) {
                          setState(() => _smsEnabled = value);
                          _updateNotificationSettings();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_bag;
      case 'promotion':
        return Icons.local_offer;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 