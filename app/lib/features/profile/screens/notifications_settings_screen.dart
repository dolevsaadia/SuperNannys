import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _booking = true;
  bool _chat = true;
  bool _session = true;
  bool _promo = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _booking = prefs.getBool('pref_notif_booking') ?? true;
      _chat = prefs.getBool('pref_notif_chat') ?? true;
      _session = prefs.getBool('pref_notif_session') ?? true;
      _promo = prefs.getBool('pref_notif_promo') ?? false;
      _loaded = true;
    });
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: _loaded
          ? ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildToggle(
                  icon: Icons.calendar_today_rounded,
                  title: 'Booking Reminders',
                  subtitle: 'Get notified before upcoming bookings',
                  value: _booking,
                  onChanged: (v) {
                    setState(() => _booking = v);
                    _save('pref_notif_booking', v);
                  },
                ),
                _buildToggle(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Chat Messages',
                  subtitle: 'New messages from parents and nannies',
                  value: _chat,
                  onChanged: (v) {
                    setState(() => _chat = v);
                    _save('pref_notif_chat', v);
                  },
                ),
                _buildToggle(
                  icon: Icons.timer_outlined,
                  title: 'Session Alerts',
                  subtitle: 'Live session start, end, and overtime alerts',
                  value: _session,
                  onChanged: (v) {
                    setState(() => _session = v);
                    _save('pref_notif_session', v);
                  },
                ),
                _buildToggle(
                  icon: Icons.local_offer_outlined,
                  title: 'Promotional',
                  subtitle: 'Deals, discounts, and feature updates',
                  value: _promo,
                  onChanged: (v) {
                    setState(() => _promo = v);
                    _save('pref_notif_promo', v);
                  },
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      value: value,
      activeColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}
