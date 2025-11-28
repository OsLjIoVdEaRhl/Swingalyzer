import 'package:flutter/material.dart';
import '../widgets/settings_tile.dart';
import '../widgets/section_title.dart';

class ConnectDevicePage extends StatelessWidget {
  const ConnectDevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF093823),
      appBar: AppBar(
        title: const Text('Connect Device'),
        backgroundColor: const Color(0xFF0D2F22),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: 'Connected Devices'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2F22),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.bluetooth_connected,
                        color: Color(0xFF7BE39A), size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Swingalyzer Pro X',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Connected • Battery: 85%',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle,
                        color: Color(0xFF7BE39A), size: 24),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionTitle(title: 'Available Devices'),
              const SizedBox(height: 8),
              SettingsTile(
                title: 'Scan for Devices',
                subtitle: 'Find new sensors nearby',
                icon: Icons.search,
                panelColor: const Color(0xFF0D2F22),
                onTap: () {
                  // Scan for devices
                },
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2F22),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.bluetooth, color: Colors.white54, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Swingalyzer Pro Y',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Not connected',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7BE39A),
                        foregroundColor: Colors.black,
                        minimumSize: const Size(70, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text('Connect'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionTitle(title: 'Device Settings'),
              const SizedBox(height: 8),
              SettingsTile(
                title: 'Device Name',
                subtitle: 'Swingalyzer Pro X',
                icon: Icons.edit,
                panelColor: const Color(0xFF0D2F22),
                onTap: () {},
              ),
              const SizedBox(height: 8),
              SettingsTile(
                title: 'Firmware Update',
                subtitle: 'v2.1.0 • Up to date',
                icon: Icons.system_update,
                panelColor: const Color(0xFF0D2F22),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}