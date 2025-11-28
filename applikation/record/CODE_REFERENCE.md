# Code Reference - Key Implementations

This document provides quick reference to key code patterns used in the Movesense recording system.

## 1. Service Architecture Pattern

### Provider Setup (main.dart)

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => MovesenseService()),
  ],
  child: MaterialApp(...),
)
```

### State Changes (any screen)

```dart
// Read service
final service = context.read<MovesenseService>();
service.startRecording();

// Watch for changes
Consumer<MovesenseService>(
  builder: (context, service, _) {
    return Text('Status: ${service.isRecording ? "Recording" : "Stopped"}');
  },
)
```

## 2. Bluetooth Implementation

### Device Scanning

```dart
Future<List<BluetoothDevice>> getAvailableDevices() async {
  try {
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 5),
    );

    final devices = <BluetoothDevice>[];
    await for (final scanResults in FlutterBluePlus.scanResults) {
      for (final result in scanResults) {
        if (!devices.any((device) => device.remoteId == result.device.remoteId)) {
          devices.add(result.device);
        }
      }
    }
    return devices;
  } finally {
    await FlutterBluePlus.stopScan();
  }
}
```

### Device Connection

```dart
Future<bool> connectToDevice(BluetoothDevice device) async {
  try {
    _isConnecting = true;
    notifyListeners();

    await device.connect(timeout: const Duration(seconds: 30));
    _connectedDevice = device;

    // Discover services
    List<BluetoothService> services = await device.discoverServices();

    for (var service in services) {
      if (service.uuid.toString().toLowerCase() == movesenseServiceUUID.toLowerCase()) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toLowerCase() ==
              imuDataCharacteristicUUID.toLowerCase()) {
            _imuCharacteristic = characteristic;

            if (characteristic.properties.notify) {
              await characteristic.setNotifyValue(true);
              _setupValueChangedListener();
            }
            break;
          }
        }
      }
    }

    _isConnected = true;
    _isConnecting = false;
    notifyListeners();
    return true;
  } catch (e) {
    _isConnecting = false;
    _isConnected = false;
    notifyListeners();
    rethrow;
  }
}
```

### Data Listening

```dart
void _setupValueChangedListener() {
  _valueChangedSubscription = _imuCharacteristic?.onValueReceived
      .listen((List<int> value) {
    if (_isRecording) {
      final imuData = _parseIMUData(value);
      if (imuData != null) {
        _recordedData.add(imuData);
        notifyListeners();
      }
    }
  });
}
```

## 3. Data Model

### IMU Data Class

```dart
class IMUData {
  final DateTime timestamp;
  final double accelX, accelY, accelZ;
  final double gyroX, gyroY, gyroZ;

  IMUData({
    required this.timestamp,
    required this.accelX, required this.accelY, required this.accelZ,
    required this.gyroX, required this.gyroY, required this.gyroZ,
  });

  String toCSV() {
    return '$timestamp,$accelX,$accelY,$accelZ,$gyroX,$gyroY,$gyroZ';
  }

  static String getCSVHeader() {
    return 'Timestamp,AccelX,AccelY,AccelZ,GyroX,GyroY,GyroZ';
  }
}
```

## 4. Data Parsing

### Binary Data to IMU Values

```dart
IMUData? _parseIMUData(List<int> rawData) {
  try {
    if (rawData.length < 26) return null;

    final byteData = ByteData.sublistView(Uint8List.fromList(rawData));

    // Parse 6 float32 values (24 bytes total)
    return IMUData(
      timestamp: DateTime.now(),
      accelX: byteData.getFloat32(0, Endian.little),
      accelY: byteData.getFloat32(4, Endian.little),
      accelZ: byteData.getFloat32(8, Endian.little),
      gyroX: byteData.getFloat32(12, Endian.little),
      gyroY: byteData.getFloat32(16, Endian.little),
      gyroZ: byteData.getFloat32(20, Endian.little),
    );
  } catch (e) {
    print('Error parsing IMU data: $e');
    return null;
  }
}
```

## 5. UI Patterns

### Consumer Pattern

```dart
Consumer<MovesenseService>(
  builder: (context, service, child) {
    if (service.isConnected) {
      return const RecordingScreen();
    }
    return _buildConnectionUI(context);
  },
)
```

### Stats Display

```dart
_buildStatCard(
  context,
  'Data Points',
  '${service.recordedData.length}',
  Icons.data_usage,
)
```

### Data List

```dart
ListView.builder(
  itemCount: service.recordedData.length,
  itemBuilder: (context, index) {
    final data = service.recordedData[index];
    return Card(
      child: ListTile(
        title: Text('Reading #${index + 1}'),
        subtitle: Text(_formatTime(data.timestamp)),
      ),
    );
  },
)
```

## 6. Error Handling

### Try-Catch with Recovery

```dart
try {
  await service.connectToDevice(device);

  if (mounted) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connected to ${device.platformName}')),
    );
  }
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: $e')),
    );
  }
}
```

### Validation

```dart
if (_imuCharacteristic != null && _isConnected) {
  _isRecording = true;
  notifyListeners();
} else {
  print('Cannot start recording: not connected');
}
```

## 7. Resource Cleanup

### Proper Disposal

```dart
@override
void dispose() {
  _valueChangedSubscription?.cancel();

  if (_imuCharacteristic != null) {
    _imuCharacteristic!.setNotifyValue(false);
  }

  if (_connectedDevice != null) {
    _connectedDevice!.disconnect();
  }

  super.dispose();
}
```

## 8. State Management

### ChangeNotifier Pattern

```dart
class MovesenseService extends ChangeNotifier {
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  void _updateState() {
    _isConnected = true;
    notifyListeners(); // Rebuilds all Consumer widgets
  }
}
```

## 9. Async Operations

### Future with Error Handling

```dart
FutureBuilder<List<BluetoothDevice>>(
  future: _devicesFuture,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }

    if (snapshot.hasError) {
      return ErrorWidget(error: snapshot.error);
    }

    final devices = snapshot.data ?? [];
    return DeviceList(devices: devices);
  },
)
```

## 10. Formatting Utilities

### Time Formatting

```dart
String _formatTime(DateTime dateTime) {
  return DateFormat('HH:mm:ss.SSS').format(dateTime);
}
```

### Duration Calculation

```dart
String _formatDuration(List<IMUData> data) {
  if (data.isEmpty) return '0s';
  final duration = data.last.timestamp.difference(data.first.timestamp);
  return '${duration.inSeconds}s';
}
```

## 11. Custom Widgets

### Stat Card

```dart
Widget _buildStatCard(BuildContext context, String label, String value, IconData icon) {
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
```

### Device List Item

```dart
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
    return ListTile(
      leading: const Icon(Icons.devices),
      title: Text(widget.device.platformName),
      subtitle: Text(widget.device.remoteId.str),
      trailing: _isConnecting ? const CircularProgressIndicator() : null,
      onTap: _isConnecting ? null : () => _connectToDevice(context),
    );
  }
}
```

## 12. Dialog Patterns

### Confirmation Dialog

```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Disconnect Device?'),
    content: const Text('Are you sure?'),
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
)
```

## 13. Material Design 3

### Color Scheme

```dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
  useMaterial3: true,
)
```

### Button Styling

```dart
FilledButton.icon(
  onPressed: () {},
  icon: const Icon(Icons.record),
  label: const Text('Start Recording'),
)

OutlinedButton.icon(
  onPressed: () {},
  icon: const Icon(Icons.bluetooth_disabled),
  label: const Text('Disconnect'),
)
```

## 14. CSV Export Example (To Implement)

```dart
Future<void> exportToCSV(List<IMUData> data) async {
  try {
    // Generate CSV content
    final lines = [IMUData.getCSVHeader()];
    lines.addAll(data.map((d) => d.toCSV()));
    final csvContent = lines.join('\n');

    // Save file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'imu_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${directory.path}/$fileName');

    await file.writeAsString(csvContent);

    return file.path;
  } catch (e) {
    print('Export failed: $e');
    rethrow;
  }
}
```

## 15. Testing Example

```dart
void main() {
  group('MovesenseService', () {
    late MovesenseService service;

    setUp(() {
      service = MovesenseService();
    });

    tearDown(() {
      service.dispose();
    });

    test('recording state changes correctly', () {
      service.startRecording();
      expect(service.isRecording, isTrue);

      service.stopRecording();
      expect(service.isRecording, isFalse);
    });

    test('clears data properly', () {
      // Add mock data
      service.clearRecordedData();
      expect(service.recordedData, isEmpty);
    });
  });
}
```

---

## Quick Reference Table

| Pattern            | File                    | Purpose                  |
| ------------------ | ----------------------- | ------------------------ |
| ChangeNotifier     | movesense_service.dart  | State management         |
| Consumer           | home_screen.dart        | React to state changes   |
| FutureBuilder      | device_list_screen.dart | Handle async operations  |
| ListView.builder   | recording_screen.dart   | Display large data lists |
| StreamSubscription | movesense_service.dart  | Listen to Bluetooth data |
| ByteData           | movesense_service.dart  | Parse binary data        |
| Provider/read      | All screens             | Access services          |
| ScaffoldMessenger  | All screens             | Show notifications       |

---

Use these patterns as templates for implementing similar features or extending the system.
