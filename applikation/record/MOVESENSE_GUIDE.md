# Movesense IMU Recording System

A Flutter application that enables simple and intuitive recording of IMU (Inertial Measurement Unit) sensor data from Movesense wireless sensors.

## Features

- **Easy Device Connection**: Simple Bluetooth scanning and connection to Movesense sensors
- **Real-time IMU Data Recording**: Captures acceleration and gyroscopic data in real-time
- **Live Data Display**: View recorded data points with timestamps and sensor values
- **Data Statistics**: Track number of data points, recording status, and session duration
- **Data Export**: Export recorded data in CSV format for further analysis
- **User-Friendly UI**: Intuitive interface with clear instructions for device connection

## Architecture

### Project Structure

```
lib/
├── main.dart                 # App entry point with Provider setup
├── models/
│   └── imu_data.dart        # IMU data model and CSV formatting
├── services/
│   └── movesense_service.dart # Bluetooth communication and data recording service
└── screens/
    ├── home_screen.dart      # Main connection and navigation screen
    ├── device_list_screen.dart # Bluetooth device scanning and selection
    └── recording_screen.dart  # Live data recording and display screen
```

### Key Components

#### 1. **IMUData Model** (`models/imu_data.dart`)

Data structure representing a single IMU sensor reading:

- **Acceleration**: X, Y, Z values (m/s²)
- **Rotation**: X, Y, Z values (°/s)
- **Timestamp**: When the reading was captured
- CSV export support for data analysis

#### 2. **MovesenseService** (`services/movesense_service.dart`)

Core service handling all Movesense sensor operations:

- Bluetooth device scanning and discovery
- Sensor connection management
- Real-time data reception and parsing
- Recording start/stop control
- Data storage and management
- State notifications via ChangeNotifier

#### 3. **Home Screen** (`screens/home_screen.dart`)

Initial user interface:

- Connection status display
- Device scanning control
- Setup instructions for users
- Navigation to recording screen when connected

#### 4. **Device List Screen** (`screens/device_list_screen.dart`)

Bluetooth device discovery interface:

- Scans for available Movesense sensors
- Lists discovered devices with details
- Handles device connection
- Error handling and retry functionality

#### 5. **Recording Screen** (`screens/recording_screen.dart`)

Live data recording and monitoring:

- Start/stop recording controls
- Real-time data visualization
- Statistics display (data points, status, duration)
- Data export functionality
- Device disconnection option

## Usage

### Basic Setup

1. **Add Dependencies** (already included in pubspec.yaml):

   - `flutter_blue_plus`: Bluetooth communication
   - `provider`: State management
   - `intl`: Date/time formatting
   - `csv`: Data export

2. **Run the Application**:
   ```bash
   flutter pub get
   flutter run
   ```

### User Workflow

1. **Connect to Sensor**:

   - Tap "Scan for Devices"
   - Select your Movesense sensor from the list
   - Wait for connection confirmation

2. **Record Data**:

   - Tap "Start Recording" on the recording screen
   - Sensor data will be captured in real-time
   - View live data points as they arrive

3. **Stop and Export**:
   - Tap "Stop Recording" to end the session
   - Tap "Export" to save data as CSV (coming soon)
   - Tap "Disconnect" to disconnect from the sensor

## Bluetooth Configuration

### Movesense Service UUIDs

The service uses standard Movesense BLE characteristics:

```dart
// Service UUID (may vary by sensor model)
static const String movesenseServiceUUID = '34ab0000-f02f-4e5f-9f46-8aae5d6d0415';

// IMU Data Characteristic UUID
static const String imuDataCharacteristicUUID = '34ab0001-f02f-4e5f-9f46-8aae5d6d0415';
```

**Note**: These UUIDs may differ depending on your specific Movesense sensor model. Verify with your sensor's documentation and update accordingly.

## Data Format

### Raw IMU Data Structure

The sensor sends 26 bytes of data containing:

- Acceleration X, Y, Z: 3 × float32 (12 bytes)
- Gyroscopic X, Y, Z: 3 × float32 (12 bytes)
- Timestamp and additional data: remaining bytes

### CSV Export Format

```csv
Timestamp,AccelX,AccelY,AccelZ,GyroX,GyroY,GyroZ
2024-11-20T10:30:45.123,0.123,0.456,9.812,0.001,0.002,-0.003
```

## Customization

### Modify Sensor UUIDs

Edit `lib/services/movesense_service.dart`:

```dart
static const String movesenseServiceUUID = 'YOUR_SERVICE_UUID';
static const String imuDataCharacteristicUUID = 'YOUR_CHARACTERISTIC_UUID';
```

### Adjust Data Parsing

Modify the `_parseIMUData()` method if your sensor uses a different data format or byte order.

### Change Sampling Rate

The current implementation records all data points received from the sensor. To implement sampling:

```dart
void _setupValueChangedListener() {
  int sampleCount = 0;
  const int sampleRate = 10; // Keep every 10th sample

  _valueChangedSubscription = _imuCharacteristic?.onValueReceived
      .listen((List<int> value) {
    if (_isRecording && sampleCount++ % sampleRate == 0) {
      final imuData = _parseIMUData(value);
      if (imuData != null) {
        _recordedData.add(imuData);
        notifyListeners();
      }
    }
  });
}
```

## Troubleshooting

### Connection Issues

- Ensure Bluetooth is enabled on the device
- Confirm the Movesense sensor is powered on and in pairing mode
- Check that the correct UUIDs are configured for your sensor model
- Verify Bluetooth permissions are granted in app settings

### Data Not Appearing

- Check that the characteristic UUID matches your sensor's configuration
- Verify that notifications are enabled for the characteristic
- Ensure the sensor is actively broadcasting data

### Export Issues

- CSV export functionality is marked as "coming soon" in the current version
- Implement the `_exportData()` method in recording_screen.dart to enable export

## Future Enhancements

- [ ] CSV data export implementation
- [ ] Data visualization with charts
- [ ] Multiple sensor simultaneous recording
- [ ] Data filtering and processing
- [ ] Recording session history
- [ ] Real-time data analysis and statistics
- [ ] Cloud data synchronization
- [ ] Custom recording profiles

## Dependencies

- **Flutter**: ^3.9.2
- **flutter_blue_plus**: ^1.31.15 - Bluetooth Low Energy communication
- **provider**: ^6.0.0 - State management
- **intl**: ^0.19.0 - Internationalization and date formatting
- **csv**: ^6.0.0 - CSV file generation

## License

This project is part of the Swingalyzer application.

## Support

For issues or feature requests, please refer to the main Swingalyzer project documentation.
