import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/movesense_service.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  late Future<List<BluetoothDevice>> _devicesFuture;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    setState(() {
      _devicesFuture = context.read<MovesenseService>().getAvailableDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Available Devices',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              FutureBuilder<List<BluetoothDevice>>(
                future: _devicesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Scanning for devices...',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          FilledButton.tonal(
                            onPressed: () async {
                              await context.read<MovesenseService>().stopScan();
                              if (mounted) {
                                Navigator.pop(context);
                              }
                            },
                            child: const Text('Stop Scan'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    final errorMessage = snapshot.error.toString();
                    final isPermissionError = errorMessage.contains(
                      'permission',
                    );

                    return Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            isPermissionError
                                ? Icons.lock_outline
                                : Icons.error_outline,
                            size: 48,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isPermissionError
                                ? 'Bluetooth Permissions Required'
                                : 'Error scanning devices',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if (isPermissionError)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Text(
                                'Please enable Bluetooth permissions in your device settings under:\n\nSettings > Apps > Record > Permissions > Bluetooth',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _startScan,
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    );
                  }

                  final devices = snapshot.data ?? [];

                  if (devices.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.bluetooth_disabled,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No devices found',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _startScan,
                            child: const Text('Scan Again'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return _DeviceListItem(device: device);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DeviceListItem extends StatefulWidget {
  final BluetoothDevice device;

  const _DeviceListItem({required this.device});

  @override
  State<_DeviceListItem> createState() => _DeviceListItemState();
}

class _DeviceListItemState extends State<_DeviceListItem> {
  bool _isConnecting = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.devices),
          title: Text(
            widget.device.platformName.isNotEmpty
                ? widget.device.platformName
                : 'Unknown Device',
          ),
          subtitle: Text(widget.device.remoteId.str),
          trailing: _isConnecting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: _isConnecting ? null : () => _connectToDevice(context),
        ),
      ),
    );
  }

  Future<void> _connectToDevice(BuildContext context) async {
    setState(() => _isConnecting = true);

    try {
      final service = context.read<MovesenseService>();
      await service.connectToDevice(widget.device);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${widget.device.platformName}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() => _isConnecting = false);
      }
    }
  }
}
