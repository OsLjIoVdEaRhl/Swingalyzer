import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Represents a sensor data point for gyroscope
class GyroData {
  final DateTime timestamp;
  final double x;
  final double y;
  final double z;

  GyroData({
    required this.timestamp,
    required this.x,
    required this.y,
    required this.z,
  });

  List<String> toCSVRow() {
    return [
      timestamp.toIso8601String(),
      x.toString(),
      y.toString(),
      z.toString(),
    ];
  }
}

/// Represents a sensor data point for accelerometer
class AccelData {
  final DateTime timestamp;
  final double x;
  final double y;
  final double z;

  AccelData({
    required this.timestamp,
    required this.x,
    required this.y,
    required this.z,
  });

  List<String> toCSVRow() {
    return [
      timestamp.toIso8601String(),
      x.toString(),
      y.toString(),
      z.toString(),
    ];
  }
}

/// Service to handle Movesense BLE device connection and data streaming
class MovesenseService {
  // Movesense UUIDs for IMU data
  static const String movesenseServiceUUID =
      '34AB0001-85B1-1B9F-4151-D703E3AF8BC0';
  static const String imuCharacteristicUUID =
      '34AB0003-85B1-1B9F-4151-D703E3AF8BC0';
  static const String notifyCharacteristicUUID =
      '34AB0101-85B1-1B9F-4151-D703E3AF8BC0';

  BluetoothDevice? _device;
  BluetoothCharacteristic? _notifyCharacteristic;
  StreamSubscription? _dataSubscription;

  List<GyroData> gyroDataBuffer = [];
  List<AccelData> accelDataBuffer = [];

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  final _connectionStateController = StreamController<bool>.broadcast();
  final _gyroDataController = StreamController<GyroData>.broadcast();
  final _accelDataController = StreamController<AccelData>.broadcast();

  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  Stream<GyroData> get gyroDataStream => _gyroDataController.stream;
  Stream<AccelData> get accelDataStream => _accelDataController.stream;

  /// Connect to a Movesense device
  Future<void> connect(BluetoothDevice device) async {
    try {
      _device = device;

      // Add a small delay to ensure device is ready
      await Future.delayed(const Duration(milliseconds: 500));

      print('Attempting to connect to ${device.name} (${device.id})...');
      await device.connect(timeout: const Duration(seconds: 30));
      print('✓ Device connected');

      // Add delay before discovering services
      await Future.delayed(const Duration(milliseconds: 500));

      // Discover services
      print('Discovering services...');
      List<BluetoothService> services = await device.discoverServices();

      print('=== Discovered Services ===');
      bool foundIMUService = false;

      for (BluetoothService service in services) {
        final serviceUUID = service.uuid.toString().toUpperCase();
        print('Service: $serviceUUID');

        for (BluetoothCharacteristic char in service.characteristics) {
          final charUUID = char.uuid.toString().toUpperCase();
          print(
            '  └─ Characteristic: $charUUID (notify: ${char.properties.notify})',
          );

          // Look for any characteristic that supports notifications
          if (char.properties.notify) {
            // Try to subscribe to any notify characteristic
            if (_notifyCharacteristic == null) {
              _notifyCharacteristic = char;
              print('     ✓ Selected for subscription');
              await char.setNotifyValue(true);
              foundIMUService = true;
            }
          }
        }
      }

      if (foundIMUService && _notifyCharacteristic != null) {
        _subscribeToData();
        _isConnected = true;
        _connectionStateController.add(true);
        print('✓ Connected and subscribed to IMU data');
      } else {
        _isConnected = false;
        _connectionStateController.add(false);
        print('✗ No IMU characteristic found');
      }
    } catch (e) {
      print('Error connecting: $e');
      _isConnected = false;
      _connectionStateController.add(false);
      rethrow;
    }
  }

  /// Subscribe to incoming IMU data
  void _subscribeToData() {
    _dataSubscription = _notifyCharacteristic?.onValueReceived.listen((value) {
      _parseIMUData(value);
    });
  }

  /// Parse IMU data from Movesense sensor
  void _parseIMUData(List<int> data) {
    try {
      // Movesense IMU data format: contains both gyro and accel data
      // Format varies, but typically includes 6 axes of data (3 gyro + 3 accel)
      // This is a generic parser that handles common Movesense formats

      if (data.length >= 24) {
        // Parse 6 float values (24 bytes)
        final byteData = data.sublist(0, 24);

        // Convert bytes to floats (assuming little-endian)
        final gyroX = _bytesToFloat(byteData.sublist(0, 4));
        final gyroY = _bytesToFloat(byteData.sublist(4, 8));
        final gyroZ = _bytesToFloat(byteData.sublist(8, 12));

        final accelX = _bytesToFloat(byteData.sublist(12, 16));
        final accelY = _bytesToFloat(byteData.sublist(16, 20));
        final accelZ = _bytesToFloat(byteData.sublist(20, 24));

        final now = DateTime.now();

        if (_isRecording) {
          gyroDataBuffer.add(
            GyroData(timestamp: now, x: gyroX, y: gyroY, z: gyroZ),
          );

          accelDataBuffer.add(
            AccelData(timestamp: now, x: accelX, y: accelY, z: accelZ),
          );
        }

        // Stream the data
        _gyroDataController.add(
          GyroData(timestamp: now, x: gyroX, y: gyroY, z: gyroZ),
        );

        _accelDataController.add(
          AccelData(timestamp: now, x: accelX, y: accelY, z: accelZ),
        );
      }
    } catch (e) {
      print('Error parsing IMU data: $e');
    }
  }

  /// Convert 4 bytes to float (little-endian)
  double _bytesToFloat(List<int> bytes) {
    if (bytes.length != 4) throw ArgumentError('Float requires 4 bytes');
    final byteData = ByteData(4);
    for (int i = 0; i < 4; i++) {
      byteData.setUint8(i, bytes[i]);
    }
    return byteData.getFloat32(0, Endian.little);
  }

  /// Start recording sensor data
  void startRecording() {
    _isRecording = true;
    gyroDataBuffer.clear();
    accelDataBuffer.clear();
  }

  /// Stop recording sensor data
  void stopRecording() {
    _isRecording = false;
  }

  /// Get recorded gyro data
  List<GyroData> getGyroData() => List.from(gyroDataBuffer);

  /// Get recorded accel data
  List<AccelData> getAccelData() => List.from(accelDataBuffer);

  /// Clear recorded data
  void clearRecordedData() {
    gyroDataBuffer.clear();
    accelDataBuffer.clear();
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    await _dataSubscription?.cancel();
    if (_device != null) {
      await _device!.disconnect();
    }
    _isConnected = false;
    _connectionStateController.add(false);
  }

  /// Dispose resources
  void dispose() {
    _dataSubscription?.cancel();
    _connectionStateController.close();
    _gyroDataController.close();
    _accelDataController.close();
  }
}
