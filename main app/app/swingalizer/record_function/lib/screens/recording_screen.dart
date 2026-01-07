import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/movesense_service.dart';
import '../services/file_export_service.dart';

class RecordingScreen extends StatefulWidget {
  final MovesenseService movesenseService;
  final BluetoothDevice device;

  const RecordingScreen({
    super.key,
    required this.movesenseService,
    required this.device,
  });

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final FileExportService _fileExportService = FileExportService();
  bool _isRecording = false;
  int _gyroDataCount = 0;
  int _accelDataCount = 0;
  late GyroData _lastGyroData;
  late AccelData _lastAccelData;
  bool _hasData = false;

  @override
  void initState() {
    super.initState();
    _subscribeToData();
  }

  void _subscribeToData() {
    // Subscribe to gyro data
    widget.movesenseService.gyroDataStream.listen((data) {
      if (mounted) {
        setState(() {
          _lastGyroData = data;
          if (!_hasData) _hasData = true;
          if (_isRecording) _gyroDataCount++;
        });
      }
    });

    // Subscribe to accel data
    widget.movesenseService.accelDataStream.listen((data) {
      if (mounted) {
        setState(() {
          _lastAccelData = data;
          if (_isRecording) _accelDataCount++;
        });
      }
    });
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (_isRecording) {
        _gyroDataCount = 0;
        _accelDataCount = 0;
        widget.movesenseService.startRecording();
      } else {
        widget.movesenseService.stopRecording();
      }
    });
  }

  Future<void> _saveAndExportData() async {
    try {
      if (!_isRecording) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        await _fileExportService.exportAndShareData(
          widget.movesenseService.getGyroData(),
          widget.movesenseService.getAccelData(),
        );

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data exported successfully')),
          );
          // Clear recorded data
          widget.movesenseService.clearRecordedData();
          setState(() {
            _gyroDataCount = 0;
            _accelDataCount = 0;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting data: $e')));
      }
    }
  }

  Future<void> _disconnect() async {
    await widget.movesenseService.disconnect();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _disconnect();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recording'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _disconnect,
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Device Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connected Device',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.device.name.isEmpty
                              ? 'Unknown Device'
                              : widget.device.name,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          widget.device.id.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Connection Status
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: StreamBuilder<bool>(
                      stream: widget.movesenseService.connectionStateStream,
                      builder: (context, snapshot) {
                        final isConnected = snapshot.data ?? false;
                        return Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: isConnected ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isConnected
                                  ? 'Connected & Streaming'
                                  : 'Not Connected',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Live Data Display
                if (_hasData)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Sensor Data',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Gyroscope:',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            'X: ${_lastGyroData.x.toStringAsFixed(2)} °/s',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Y: ${_lastGyroData.y.toStringAsFixed(2)} °/s',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Z: ${_lastGyroData.z.toStringAsFixed(2)} °/s',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Accelerometer:',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            'X: ${_lastAccelData.x.toStringAsFixed(2)} m/s²',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Y: ${_lastAccelData.y.toStringAsFixed(2)} m/s²',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Z: ${_lastAccelData.z.toStringAsFixed(2)} m/s²',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // Recording Stats
                if (_isRecording)
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recording Statistics',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Gyro Samples: $_gyroDataCount',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                'Accel Samples: $_accelDataCount',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 40),

                // Recording Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _toggleRecording,
                      icon: Icon(_isRecording ? Icons.stop : Icons.circle),
                      label: Text(
                        _isRecording ? 'Stop Recording' : 'Start Recording',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRecording
                            ? Colors.red
                            : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    if (!_isRecording && _gyroDataCount > 0)
                      ElevatedButton.icon(
                        onPressed: _saveAndExportData,
                        icon: const Icon(Icons.download),
                        label: const Text('Export & Download'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                if (!_isRecording && _gyroDataCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextButton(
                      onPressed: () {
                        widget.movesenseService.clearRecordedData();
                        setState(() {
                          _gyroDataCount = 0;
                          _accelDataCount = 0;
                        });
                      },
                      child: const Text('Clear Data'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
