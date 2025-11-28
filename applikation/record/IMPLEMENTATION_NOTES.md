# Implementation Notes - Movesense Integration

This document provides technical details for developers who need to customize or extend the Movesense recording functionality.

## Architecture Overview

### State Management with Provider

The app uses the `provider` package for state management:

```dart
// In main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => MovesenseService()),
  ],
  child: MaterialApp(...),
)
```

The `MovesenseService` extends `ChangeNotifier`, allowing UI widgets to rebuild automatically when:

- Connection status changes
- Recording starts/stops
- New IMU data arrives

### Data Flow

```
User Action (Tap Button)
         ↓
HomeScreen/RecordingScreen (UI)
         ↓
MovesenseService (Business Logic)
         ↓
FlutterBluePlus (Bluetooth Communication)
         ↓
Movesense Sensor (Hardware)
```

## Bluetooth Implementation Details

### Connection Lifecycle

```dart
1. Scan for devices
   ├─ FlutterBluePlus.startScan()
   ├─ Listen to scanResults stream
   └─ FlutterBluePlus.stopScan()

2. Connect to device
   ├─ device.connect()
   ├─ device.discoverServices()
   └─ Find IMU characteristic

3. Subscribe to data
   ├─ characteristic.setNotifyValue(true)
   └─ characteristic.onValueReceived.listen()

4. Disconnect
   ├─ characteristic.setNotifyValue(false)
   └─ device.disconnect()
```

### Bluetooth UUIDs

**Current Configuration** (must match your sensor):

```dart
Service UUID:        34ab0000-f02f-4e5f-9f46-8aae5d6d0415
Characteristic UUID: 34ab0001-f02f-4e5f-9f46-8aae5d6d0415
```

**To find your sensor's UUIDs:**

1. Use a Bluetooth scanner app (Android: BLE Scanner, iOS: LightBlue)
2. Connect to your Movesense sensor
3. Note the UUID of the IMU data characteristic
4. Update `movesense_service.dart` with the correct UUIDs

### Data Parsing

The `_parseIMUData()` method converts raw bytes to IMU values:

```dart
// Expected format:
// Bytes 0-3:    Accel X (float32, little-endian)
// Bytes 4-7:    Accel Y (float32, little-endian)
// Bytes 8-11:   Accel Z (float32, little-endian)
// Bytes 12-15:  Gyro X  (float32, little-endian)
// Bytes 16-19:  Gyro Y  (float32, little-endian)
// Bytes 20-23:  Gyro Z  (float32, little-endian)
// Bytes 24-25:  Reserved/Timestamp info
```

**If your sensor uses a different format:**

1. Check the Movesense API documentation
2. Update byte offsets in `_parseIMUData()`
3. Adjust the minimum data length check (currently 26 bytes)

Example for different byte order:

```dart
// Big-endian instead of little-endian
final accelX = byteData.getFloat32(0, Endian.big);
```

## Customization Guide

### 1. Change Sensor UUIDs

**File:** `lib/services/movesense_service.dart`

```dart
// Replace these values with your sensor's UUIDs
static const String movesenseServiceUUID = 'YOUR_SERVICE_UUID';
static const String imuDataCharacteristicUUID = 'YOUR_CHARACTERISTIC_UUID';
```

### 2. Adjust Data Parsing

**File:** `lib/services/movesense_service.dart`

Modify the `_parseIMUData()` method:

```dart
IMUData? _parseIMUData(List<int> rawData) {
  try {
    if (rawData.length < 26) {
      return null; // Adjust minimum length if needed
    }

    final byteData = ByteData.sublistView(Uint8List.fromList(rawData));

    // Update these offsets for your sensor's data format
    final accelX = byteData.getFloat32(0, Endian.little);
    final accelY = byteData.getFloat32(4, Endian.little);
    // ... etc
  } catch (e) {
    print('Error parsing IMU data: $e');
    return null;
  }
}
```

### 3. Implement Data Export

**File:** `lib/screens/recording_screen.dart`

Replace the `_exportData()` method:

```dart
void _exportData(BuildContext context, MovesenseService service) async {
  try {
    // Generate CSV content
    final csv = [IMUData.getCSVHeader()];
    csv.addAll(service.recordedData.map((data) => data.toCSV()));
    final csvContent = csv.join('\n');

    // Save to file
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'imu_data_$timestamp.csv';

    // Use path_provider or another file saving mechanism
    // Save csvContent to fileName

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data exported to $fileName')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export failed: $e')),
    );
  }
}
```

### 4. Add Sampling/Filtering

**File:** `lib/services/movesense_service.dart`

In `_setupValueChangedListener()`:

```dart
int sampleCounter = 0;
const int SAMPLE_EVERY_N = 10; // Keep every 10th sample

_valueChangedSubscription = _imuCharacteristic?.onValueReceived
    .listen((List<int> value) {
  if (_isRecording) {
    sampleCounter++;
    if (sampleCounter % SAMPLE_EVERY_N == 0) {
      final imuData = _parseIMUData(value);
      if (imuData != null) {
        _recordedData.add(imuData);
        notifyListeners();
      }
    }
  }
});
```

### 5. Add Real-time Signal Processing

**File:** `lib/services/movesense_service.dart`

Add a new class for signal processing:

```dart
class SignalProcessor {
  final List<double> _accelMagnitudes = [];
  static const int WINDOW_SIZE = 10;

  void addReading(IMUData data) {
    final magnitude = _calculateMagnitude(
      data.accelX,
      data.accelY,
      data.accelZ,
    );
    _accelMagnitudes.add(magnitude);

    if (_accelMagnitudes.length > WINDOW_SIZE) {
      _accelMagnitudes.removeAt(0);
    }
  }

  double _calculateMagnitude(double x, double y, double z) {
    return sqrt(x * x + y * y + z * z);
  }

  double getAverageMagnitude() {
    if (_accelMagnitudes.isEmpty) return 0.0;
    return _accelMagnitudes.reduce((a, b) => a + b) / _accelMagnitudes.length;
  }
}
```

## Testing

### Unit Tests

Create `test/services/movesense_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:record/services/movesense_service.dart';
import 'package:record/models/imu_data.dart';

void main() {
  group('MovesenseService', () {
    late MovesenseService service;

    setUp(() {
      service = MovesenseService();
    });

    tearDown(() {
      service.dispose();
    });

    test('creates IMUData from raw bytes', () {
      // Test data parsing
    });

    test('maintains recording state', () {
      service.startRecording();
      expect(service.isRecording, isTrue);

      service.stopRecording();
      expect(service.isRecording, isFalse);
    });
  });
}
```

### Manual Testing Checklist

- [ ] Device scanning works
- [ ] Connection/disconnection works
- [ ] Recording starts and stops correctly
- [ ] Data points are captured
- [ ] Timestamps are accurate
- [ ] UI updates in real-time
- [ ] Data display is readable
- [ ] No memory leaks during long recording
- [ ] App handles sensor disconnection gracefully
- [ ] Export produces valid CSV (when implemented)

## Performance Considerations

### Memory Usage

```dart
// Each IMUData object: ~120 bytes
// 1000 readings: ~120 KB
// 10000 readings: ~1.2 MB
```

**Recommendation**: Implement data export or cleanup after 10,000+ readings on low-memory devices.

### Battery Usage

- Bluetooth scanning: High power drain
- Active recording: Moderate power drain
- Suggest limiting recording sessions to 30+ minutes

### Network Bandwidth

No network usage - all communication is local Bluetooth (within 10 meters).

## Debugging

### Enable Debug Logging

Add to `movesense_service.dart`:

```dart
const bool DEBUG = true;

void _log(String message) {
  if (DEBUG) {
    print('[MovesenseService] $message');
  }
}
```

### Common Error Messages

| Error              | Cause                     | Solution                          |
| ------------------ | ------------------------- | --------------------------------- |
| "UUID not found"   | Wrong characteristic UUID | Verify sensor's actual UUID       |
| "Connect timeout"  | Sensor out of range       | Move closer, restart sensor       |
| "Null check error" | Device disconnected       | Check connection state before use |
| "Parse error"      | Data format mismatch      | Check sensor data format          |

## Additional Resources

- [Flutter Blue Plus Documentation](https://pub.dev/packages/flutter_blue_plus)
- [Movesense API Documentation](https://www.movesense.com)
- [Bluetooth LE Specification](https://www.bluetooth.com/specifications/specs/)
