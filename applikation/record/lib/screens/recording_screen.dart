import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/movesense_service.dart';
import '../models/imu_data.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<MovesenseService>(
        builder: (context, service, _) {
          return SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Row(
                    children: [
                      Icon(
                        Icons.sensors,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recording IMU Data',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                            ),
                            Text(
                              service.connectedDevice?.platformName ??
                                  'Connected Device',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                            ),
                            if (service.detectedCharacteristicUUID != null)
                              Text(
                                'UUID Detected',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          IconButton(
                            onPressed: () => _showUUIDInfo(context, service),
                            icon: Icon(
                              Icons.info_outline,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status and Stats
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        context,
                        'Data Points',
                        '${service.recordedData.length}',
                        Icons.data_usage,
                      ),
                      _buildStatCard(
                        context,
                        'Status',
                        service.isRecording ? 'Recording' : 'Stopped',
                        service.isRecording
                            ? Icons.radio_button_on
                            : Icons.radio_button_off,
                      ),
                      _buildStatCard(
                        context,
                        'Duration',
                        _formatDuration(service.recordedData),
                        Icons.timer,
                      ),
                    ],
                  ),
                ),

                // Data Display
                Expanded(
                  child: service.recordedData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.analytics_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No data recorded yet',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap "Start Recording" to begin',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: service.recordedData.length,
                          itemBuilder: (context, index) {
                            final data = service.recordedData[index];
                            return _buildDataTile(context, data, index);
                          },
                        ),
                ),

                // Control Buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: service.isRecording
                                  ? () => service.stopRecording()
                                  : () => service.startRecording(),
                              icon: Icon(
                                service.isRecording
                                    ? Icons.stop
                                    : Icons.radio_button_on,
                              ),
                              label: Text(
                                service.isRecording
                                    ? 'Stop Recording'
                                    : 'Start Recording',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: service.isRecording
                                    ? Colors.red
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed:
                                (service.recordedData.isEmpty ||
                                    service.isExporting)
                                ? null
                                : () => _exportData(context, service),
                            icon: service.isExporting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.download),
                            label: Text(
                              service.isExporting ? 'Exporting...' : 'Export',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: service.isRecording
                                  ? null
                                  : () =>
                                        _showDisconnectDialog(context, service),
                              icon: const Icon(Icons.bluetooth_disabled),
                              label: const Text('Disconnect'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: service.recordedData.isEmpty
                                  ? null
                                  : () => _showClearDialog(context, service),
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear Data'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  Widget _buildDataTile(BuildContext context, IMUData data, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reading #${index + 1}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(
                    _formatTime(data.timestamp),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDataColumn(context, 'Acceleration', [
                      'X: ${data.accelX.toStringAsFixed(3)} m/s²',
                      'Y: ${data.accelY.toStringAsFixed(3)} m/s²',
                      'Z: ${data.accelZ.toStringAsFixed(3)} m/s²',
                    ]),
                  ),
                  Expanded(
                    child: _buildDataColumn(context, 'Rotation', [
                      'X: ${data.gyroX.toStringAsFixed(3)} °/s',
                      'Y: ${data.gyroY.toStringAsFixed(3)} °/s',
                      'Z: ${data.gyroZ.toStringAsFixed(3)} °/s',
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataColumn(
    BuildContext context,
    String title,
    List<String> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        ...items.map(
          (item) => Text(item, style: Theme.of(context).textTheme.labelSmall),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss.SSS').format(dateTime);
  }

  String _formatDuration(List<IMUData> data) {
    if (data.isEmpty) return '0s';
    final duration = data.last.timestamp.difference(data.first.timestamp);
    return '${duration.inSeconds}s';
  }

  void _exportData(BuildContext context, MovesenseService service) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exporting data...'),
          duration: Duration(seconds: 2),
        ),
      );

      final filePath = await service.exportToCSV();

      if (context.mounted && filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported to:\n$filePath'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showDisconnectDialog(BuildContext context, MovesenseService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Device?'),
        content: const Text(
          'Are you sure you want to disconnect from the Movesense sensor?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              service.disconnect();
              Navigator.pop(context);
            },
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context, MovesenseService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Data?'),
        content: const Text(
          'Are you sure you want to clear all recorded data?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              service.clearRecordedData();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showUUIDInfo(BuildContext context, MovesenseService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detected Sensor UUIDs'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Service UUID:',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              SelectableText(
                service.detectedServiceUUID ?? 'Not detected',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Characteristic UUID:',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              SelectableText(
                service.detectedCharacteristicUUID ?? 'Not detected',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text(
                'You can use these UUIDs to configure other applications or for documentation purposes.',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
