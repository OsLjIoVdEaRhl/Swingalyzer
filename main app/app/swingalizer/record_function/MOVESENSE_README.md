# Movesense Recorder App

A Flutter application for recording gyroscope and accelerometer data from Movesense HR2 sensors via Bluetooth Low Energy (BLE), and exporting the data as CSV files.

## Features

- **Bluetooth Device Scanning**: Scan for available Movesense devices
- **Real-time Data Streaming**: Live display of gyroscope and accelerometer data
- **Recording**: Start and stop recording sensor data
- **CSV Export**: Automatically save recordings to two CSV files (one for gyro, one for accelerometer)
- **File Sharing**: Share exported CSV files via your device's file sharing mechanisms
- **Real-time Statistics**: See live data sample counts during recording

## Prerequisites

- Flutter SDK (version 3.9.2+)
- Movesense HR2 sensor
- Android 6.0+ or iOS 11.0+
- Bluetooth capability on your device

## Installation

1. Clone or download this repository
2. Navigate to the project directory:

   ```bash
   cd record_function
   ```

3. Get the dependencies:

   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Permissions

The app requires the following permissions:

### Android

- Bluetooth scan and connect
- Location (required for BLE scanning)
- External storage (for file access)

### iOS

- Bluetooth peripheral and central usage
- Location (for BLE scanning)
- Local network access

These permissions are requested at runtime when needed.

## Usage

1. **Start the App**: Launch the application
2. **Check Bluetooth Status**: The home screen displays your device's Bluetooth status
3. **Scan for Devices**: Tap "Scan for Devices" to find available Movesense sensors
4. **Connect to Device**: Select your Movesense HR2 from the list
5. **View Live Data**: Once connected, you'll see real-time sensor data
6. **Start Recording**: Tap "Start Recording" to begin capturing data
7. **Monitor Recording**: Watch the live sensor data and sample count
8. **Stop Recording**: Tap "Stop Recording" when finished
9. **Export Data**: Tap "Export & Download" to save and share the CSV files

## Data Format

### Gyroscope CSV

- Columns: `Timestamp, Gyro X, Gyro Y, Gyro Z`
- Units: Degrees per second (°/s)
- Format: ISO 8601 timestamp with millisecond precision

### Accelerometer CSV

- Columns: `Timestamp, Accel X, Accel Y, Accel Z`
- Units: Meters per second squared (m/s²)
- Format: ISO 8601 timestamp with millisecond precision

Example gyro row:

```
2024-12-17T10:30:45.123456,1.234,-0.567,2.891
```

## File Storage

- CSV files are saved to the device's documents directory
- Files are automatically timestamped with their creation time
- You can access and manage them through the file sharing interface

## Troubleshooting

### App won't scan for devices

- Ensure Bluetooth is enabled on your device
- Check that all permissions have been granted
- Try turning Bluetooth off and on again
- Ensure your Movesense device is powered on and in pairing mode

### Connection fails

- Verify the device name contains "Movesense"
- Try scanning again for the device
- Ensure the device isn't connected to another application
- Restart both the app and the sensor

### No data appearing

- Ensure the sensor is properly connected (green indicator in app)
- The sensor may need a moment to start streaming
- Try disconnecting and reconnecting

### Export/Download fails

- Ensure you have granted storage permissions
- Check that you have sufficient storage space
- Try exporting again with a smaller dataset

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── screens/
│   ├── home_screen.dart         # Initial screen with Bluetooth status
│   ├── device_list_screen.dart  # Device scanning and selection
│   └── recording_screen.dart    # Recording and data visualization
└── services/
    ├── movesense_service.dart   # BLE device management and data parsing
    ├── file_export_service.dart # CSV export functionality
    └── permission_service.dart  # Runtime permission handling
```

## Dependencies

- `flutter_blue_plus`: Bluetooth Low Energy communication
- `permission_handler`: Runtime permission management
- `path_provider`: File system access
- `csv`: CSV data generation
- `share_plus`: File sharing functionality
- `intl`: Internationalization support

## Technical Details

### Bluetooth Connection

The app connects to Movesense devices using standard BLE protocols. It discovers the Movesense IMU service and subscribes to characteristic notifications for real-time data streaming.

### Data Parsing

IMU data is parsed as a sequence of floating-point values (3 gyro axes + 3 accel axes, 24 bytes total). The parser handles little-endian byte order conversion.

### Recording Buffer

Sensor data is buffered in memory during recording. For long recording sessions, be mindful of available RAM.

## Limitations

- One device connection at a time
- Data is buffered in RAM (consider stopping periodically for long sessions)
- CSV format uses millisecond timestamp precision

## Future Enhancements

- Multiple simultaneous device connections
- Real-time data visualization/plotting
- Direct data upload to cloud services
- Configurable sensor sampling rates
- Magnetometer data recording

## Support & Issues

For issues or questions, please check:

1. Movesense official documentation
2. Flutter documentation
3. flutter_blue_plus package documentation

## License

This project is provided as-is for educational and research purposes.
