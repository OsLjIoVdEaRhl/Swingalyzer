import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/movesense_service.dart';
import '../services/permission_service.dart';
import 'device_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MovesenseService _movesenseService = MovesenseService();
  bool _isInitialized = false;
  String _bluetoothStatus = 'Checking...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Request permissions
      final permissionGranted = await PermissionService.requestAllPermissions();

      if (!permissionGranted) {
        setState(() {
          _bluetoothStatus = 'Permissions denied';
        });
        return;
      }

      // Check Bluetooth availability
      if (await FlutterBluePlus.isAvailable == false) {
        setState(() {
          _bluetoothStatus = 'Bluetooth not available';
          _isInitialized = true;
        });
        return;
      }

      setState(() {
        _bluetoothStatus = 'Ready';
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _bluetoothStatus = 'Error: $e';
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _movesenseService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movesense Recorder'),
        centerTitle: true,
      ),
      body: Center(
        child: _isInitialized
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _bluetoothStatus == 'Ready'
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_disabled,
                    size: 80,
                    color: _bluetoothStatus == 'Ready'
                        ? Colors.blue
                        : Colors.red,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Bluetooth Status',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _bluetoothStatus,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 40),
                  if (_bluetoothStatus == 'Ready')
                    ElevatedButton.icon(
                      icon: const Icon(Icons.search),
                      label: const Text('Scan for Devices'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DeviceListScreen(
                              movesenseService: _movesenseService,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                      ),
                    ),
                ],
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
