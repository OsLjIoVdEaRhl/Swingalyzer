import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/movesense_service.dart';
import 'device_list_screen.dart';
import 'recording_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swingalyzer - Movesense Recorder'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<MovesenseService>(
        builder: (context, movesenseService, child) {
          // If device is connected, show recording screen
          if (movesenseService.isConnected) {
            return const RecordingScreen();
          }

          // Otherwise, show device list and connection UI
          return _buildConnectionUI(context);
        },
      ),
    );
  }

  Widget _buildConnectionUI(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Icon(
                    Icons.bluetooth,
                    size: 48,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Connect to Movesense Sensor',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a sensor from the list below to begin recording IMU data',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Connect Button
          FilledButton.icon(
            onPressed: () async {
              _showDeviceListDialog(context);
            },
            icon: const Icon(Icons.search),
            label: const Text('Scan for Devices'),
          ),
          const SizedBox(height: 16),

          // Info section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Setup Instructions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionItem(
                    context,
                    '1',
                    'Ensure Bluetooth is enabled',
                  ),
                  _buildInstructionItem(
                    context,
                    '2',
                    'Make sure Movesense sensor is powered on',
                  ),
                  _buildInstructionItem(context, '3', 'Tap "Scan for Devices"'),
                  _buildInstructionItem(
                    context,
                    '4',
                    'Select your Movesense sensor',
                  ),
                  _buildInstructionItem(
                    context,
                    '5',
                    'Start recording when prompted',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(
    BuildContext context,
    String number,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _showDeviceListDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const DeviceListScreen(),
    );
  }
}
