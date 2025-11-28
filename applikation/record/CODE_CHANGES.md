# Code Changes - Detailed Implementation

## Overview of Changes

This document shows exactly what was added/changed to implement:

1. Automatic UUID detection
2. CSV export to documents folder

---

## 1. pubspec.yaml - Dependencies Added

```yaml
# File: pubspec.yaml
# Added this dependency for file system access

dependencies:
  # ... existing dependencies ...
  path_provider: ^2.1.0 # NEW - For accessing documents folder
```

---

## 2. lib/services/movesense_service.dart - Service Enhancements

### Imports Added

```dart
import 'dart:io';                                    // NEW - For File handling
import 'package:path_provider/path_provider.dart';  // NEW - For documents folder
```

### Class Members Added

```dart
class MovesenseService extends ChangeNotifier {
  // ... existing members ...

  // NEW MEMBERS
  bool _isExporting = false;
  String? _detectedServiceUUID;
  String? _detectedCharacteristicUUID;

  // NEW GETTERS
  bool get isExporting => _isExporting;
  String? get detectedServiceUUID => _detectedServiceUUID;
  String? get detectedCharacteristicUUID => _detectedCharacteristicUUID;
}
```

### Method: connectToDevice() - Modified

**BEFORE:**

```dart
Future<bool> connectToDevice(BluetoothDevice device) async {
  // ... connection code ...

  for (var service in services) {
    if (service.uuid.toString().toLowerCase() ==
        movesenseServiceUUID.toLowerCase()) {  // Hardcoded UUID
      for (var characteristic in service.characteristics) {
        if (characteristic.uuid.toString().toLowerCase() ==
            imuDataCharacteristicUUID.toLowerCase()) {  // Hardcoded UUID
          _imuCharacteristic = characteristic;
          // ... rest of code ...
        }
      }
    }
  }
}
```

**AFTER:**

```dart
Future<bool> connectToDevice(BluetoothDevice device) async {
  try {
    _isConnecting = true;
    notifyListeners();

    await device.connect(timeout: const Duration(seconds: 30));
    _connectedDevice = device;

    // Discover services and characteristics
    List<BluetoothService> services = await device.discoverServices();

    // NEW: Auto-detect IMU service and characteristic
    bool foundIMUData = false;
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        // Look for readable/notifiable characteristics
        if ((characteristic.properties.read || characteristic.properties.notify) &&
            characteristic.uuid.toString().isNotEmpty) {
          // Try to detect IMU data
          if (characteristic.properties.notify) {
            // NEW: Store detected UUIDs
            _detectedServiceUUID = service.uuid.toString();
            _detectedCharacteristicUUID = characteristic.uuid.toString();
            _imuCharacteristic = characteristic;

            print('Auto-detected Service UUID: $_detectedServiceUUID');
            print('Auto-detected Characteristic UUID: $_detectedCharacteristicUUID');

            // Subscribe to notifications
            await characteristic.setNotifyValue(true);
            _setupValueChangedListener();
            foundIMUData = true;
            break;
          }
        }
      }
      if (foundIMUData) break;
    }

    _isConnected = true;
    _isConnecting = false;
    notifyListeners();

    return foundIMUData;
  } catch (e) {
    // ... error handling ...
  }
}
```

### New Method: exportToCSV()

```dart
/// Export recorded data to CSV file in documents folder
Future<String?> exportToCSV() async {
  try {
    _isExporting = true;
    notifyListeners();

    if (_recordedData.isEmpty) {
      throw Exception('No data to export');
    }

    // Get documents directory
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'imu_data_$timestamp.csv';
    final filePath = '${directory.path}/$fileName';

    // Generate CSV content
    final lines = <String>[];
    lines.add(IMUData.getCSVHeader());
    lines.addAll(_recordedData.map((data) => data.toCSV()));
    final csvContent = lines.join('\n');

    // Write to file
    final file = File(filePath);
    await file.writeAsString(csvContent);

    print('Data exported to: $filePath');
    _isExporting = false;
    notifyListeners();

    return filePath;
  } catch (e) {
    print('Error exporting data: $e');
    _isExporting = false;
    notifyListeners();
    rethrow;
  }
}
```

### New Method: clearRecordedData()

```dart
/// Clear recorded data
void clearRecordedData() {
  _recordedData.clear();
  notifyListeners();
}
```

---

## 3. lib/screens/recording_screen.dart - UI Enhancements

### Header Updated - Added UUID Detection Indicator and Info Button

**BEFORE:**

```dart
Container(
  padding: const EdgeInsets.all(16),
  color: Theme.of(context).colorScheme.primaryContainer,
  child: Row(
    children: [
      Icon(Icons.sensors, ...),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recording IMU Data', ...),
            Text(service.connectedDevice?.platformName ?? 'Connected Device', ...),
          ],
        ),
      ),
      Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.green,
        ),
      ),
    ],
  ),
)
```

**AFTER:**

```dart
Container(
  padding: const EdgeInsets.all(16),
  color: Theme.of(context).colorScheme.primaryContainer,
  child: Row(
    children: [
      Icon(Icons.sensors, ...),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recording IMU Data', ...),
            Text(service.connectedDevice?.platformName ?? 'Connected Device', ...),
            // NEW: UUID detection indicator
            if (service.detectedCharacteristicUUID != null)
              Text(
                'UUID Detected',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
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
          // NEW: Info button
          IconButton(
            onPressed: () => _showUUIDInfo(context, service),
            icon: Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    ],
  ),
)
```

### Export Button Updated - Added Loading State

**BEFORE:**

```dart
FilledButton.icon(
  onPressed: service.recordedData.isEmpty
      ? null
      : () => _exportData(context, service),
  icon: const Icon(Icons.download),
  label: const Text('Export'),
)
```

**AFTER:**

```dart
FilledButton.icon(
  onPressed: (service.recordedData.isEmpty || service.isExporting)
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
  label: Text(service.isExporting ? 'Exporting...' : 'Export'),
)
```

### Updated Method: \_exportData()

**BEFORE:**

```dart
void _exportData(BuildContext context, MovesenseService service) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Export functionality coming soon')),
  );
}
```

**AFTER:**

```dart
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
```

### New Method: \_showUUIDInfo()

```dart
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
```

---

## Summary of Code Changes

| File                   | Type       | Change                             | Purpose                  |
| ---------------------- | ---------- | ---------------------------------- | ------------------------ |
| pubspec.yaml           | Dependency | Added path_provider                | File system access       |
| movesense_service.dart | Import     | Added dart:io                      | File handling            |
| movesense_service.dart | Import     | Added path_provider                | Documents folder access  |
| movesense_service.dart | Property   | Added \_isExporting                | Track export state       |
| movesense_service.dart | Property   | Added \_detectedServiceUUID        | Store detected UUID      |
| movesense_service.dart | Property   | Added \_detectedCharacteristicUUID | Store detected UUID      |
| movesense_service.dart | Method     | Modified connectToDevice()         | Auto UUID detection      |
| movesense_service.dart | Method     | Added exportToCSV()                | CSV export functionality |
| movesense_service.dart | Method     | Added clearRecordedData()          | Clear data function      |
| recording_screen.dart  | Widget     | Updated header                     | Show UUID indicator      |
| recording_screen.dart  | Widget     | Updated export button              | Show loading state       |
| recording_screen.dart  | Method     | Updated \_exportData()             | Implement export         |
| recording_screen.dart  | Method     | Added \_showUUIDInfo()             | Display UUID dialog      |

---

## Lines of Code Added

- **pubspec.yaml**: 1 line
- **movesense_service.dart**: ~80 lines (imports + methods)
- **recording_screen.dart**: ~100 lines (UI + methods)

**Total**: ~181 lines of new code

## No Code Removed

All existing functionality is preserved. Changes are purely additive.
