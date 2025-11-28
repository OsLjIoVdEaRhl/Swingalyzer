import 'package:flutter/material.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_switch_tile.dart';
import '../widgets/settings_dropdown_tile.dart';
import '../widgets/section_title.dart';
import 'connect_device_page.dart';
import 'profile_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const Color _background = Color(0xFF093823);
  static const Color _panel = Color(0xFF0D2F22);
  static const Color _accent = Color(0xFF7BE39A);

  bool _notifications = true;
  bool _isDark = true;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  color: _panel,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: _accent,
                      child: Icon(Icons.person, color: Colors.black, size: 34),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ethan Carter',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Handicap: 12 • Member since 2021',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Optional: navigate to profile edit page
                      },
                      icon: const Icon(Icons.edit, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Account section
              const SectionTitle(title: 'Account'),
              const SizedBox(height: 8),
              SettingsTile(
                title: 'Profile',
                subtitle: 'View & edit your profile',
                icon: Icons.person,
                panelColor: _panel,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                },
              ),
              const SizedBox(height: 8),
              SettingsTile(
                title: 'Subscription',
                subtitle: 'Manage subscription',
                icon: Icons.card_membership,
                panelColor: _panel,
                onTap: () {
                  // Add subscription page navigation here
                },
              ),
              const SizedBox(height: 18),

              // App settings
              const SectionTitle(title: 'App Settings'),
              const SizedBox(height: 8),
              SettingsSwitchTile(
                title: 'Notifications',
                value: _notifications,
                onChanged: (v) => setState(() => _notifications = v),
                icon: Icons.notifications,
                panelColor: _panel,
              ),
              const SizedBox(height: 8),
              SettingsDropdownTile<String>(
                title: 'Language',
                value: _language,
                options: const ['English', 'Spanish', 'Swedish'],
                onChanged: (v) => setState(() => _language = v ?? _language),
                icon: Icons.language,
                panelColor: _panel,
              ),
              const SizedBox(height: 8),
              SettingsSwitchTile(
                title: 'Theme',
                value: _isDark,
                onChanged: (v) => setState(() => _isDark = v),
                icon: Icons.color_lens,
                panelColor: _panel,
              ),
              const SizedBox(height: 18),

              // Device
              const SectionTitle(title: 'Device'),
              const SizedBox(height: 8),
              SettingsTile(
                title: 'Connected Devices',
                subtitle: 'Swingalyzer Pro X • Connected',
                icon: Icons.bluetooth_connected,
                panelColor: _panel,
                accent: _accent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ConnectDevicePage()),
                  );
                },
              ),
              const SizedBox(height: 18),

              // Support
              const SectionTitle(title: 'Support'),
              const SizedBox(height: 8),
              SettingsTile(
                title: 'Help Center',
                subtitle: '',
                icon: Icons.help_outline,
                panelColor: _panel,
                onTap: () {
                  // Navigate to Help Center page
                },
              ),
              const SizedBox(height: 8),
              SettingsTile(
                title: 'Terms of Service',
                subtitle: '',
                icon: Icons.description_outlined,
                panelColor: _panel,
                onTap: () {
                  // Navigate to Terms of Service page
                },
              ),
              const SizedBox(height: 8),
              SettingsTile(
                title: 'Privacy Policy',
                subtitle: '',
                icon: Icons.lock_outline,
                panelColor: _panel,
                onTap: () {
                  // Navigate to Privacy Policy page
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}