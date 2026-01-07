import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/movesense_service.dart';
import 'recording_screen.dart';

class DeviceListScreen extends StatefulWidget {
  final MovesenseService movesenseService;

  const DeviceListScreen({super.key, required this.movesenseService});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  List<BluetoothDevice> _devicesList = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _devicesList.clear();
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

    // Listen to scan results
    FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _devicesList = results.map((r) => r.device).toList();
          // Filter to show unique devices
          _devicesList = _devicesList.toSet().toList();
        });
      }
    });

    // Stop scanning after 15 seconds
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Connecting...'),
            ],
          ),
        ),
      );

      await widget.movesenseService.connect(device);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RecordingScreen(
              movesenseService: widget.movesenseService,
              device: device,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _connectToDevice(device),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Devices')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isScanning ? 'Scanning...' : 'Scan Complete',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_isScanning)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  ElevatedButton(
                    onPressed: _startScan,
                    child: const Text('Scan Again'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _devicesList.isEmpty
                ? Center(
                    child: Text(
                      _isScanning
                          ? 'Scanning for devices...'
                          : 'No devices found',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    itemCount: _devicesList.length,
                    itemBuilder: (context, index) {
                      final device = _devicesList[index];
                      return ListTile(
                        title: Text(
                          device.name.isEmpty ? 'Unknown Device' : device.name,
                        ),
                        subtitle: Text(device.id.toString()),
                        trailing: Icon(
                          Icons.arrow_forward,
                          color: device.name.contains('Movesense')
                              ? Colors.green
                              : null,
                        ),
                        onTap: () => _connectToDevice(device),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
