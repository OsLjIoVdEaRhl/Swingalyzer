import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/imu_data.dart';

/// Service to handle Movesense sensor communication and IMU data recording
class MovesenseService extends ChangeNotifier {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _imuCharacteristic;
  StreamSubscription? _valueChangedSubscription;

  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isRecording = false;
  bool _isExporting = false;
  List<IMUData> _recordedData = [];
  String? _detectedServiceUUID;
  String? _detectedCharacteristicUUID;

  // Getters
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  bool get isRecording => _isRecording;
  bool get isExporting => _isExporting;
  List<IMUData> get recordedData => _recordedData;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  String? get detectedServiceUUID => _detectedServiceUUID;
  String? get detectedCharacteristicUUID => _detectedCharacteristicUUID;

  /// Get available Bluetooth devices
  Future<List<BluetoothDevice>> getAvailableDevices() async {
    try {
      // Collect devices during scan
      final deviceMap = <String, BluetoothDevice>{};

      // Listen to scan results while scanning
      final subscription = FlutterBluePlus.scanResults.listen((scanResults) {
        for (final result in scanResults) {
          final key = result.device.remoteId.toString();
          deviceMap[key] = result.device;
        }
      });

      try {
        // Start scan - will continue until stopScan() is called
        await FlutterBluePlus.startScan();
      } finally {
        await subscription.cancel();
      }

      return deviceMap.values.toList();
    } on PlatformException catch (e) {
      if (e.code.contains('PERMISSION')) {
        print('Bluetooth permission denied: ${e.message}');
        throw Exception(
          'Bluetooth permissions are required. Please enable Bluetooth permissions in your device settings and try again.',
        );
      }
      print('Error scanning for devices: $e');
      rethrow;
    } catch (e) {
      print('Error scanning for devices: $e');
      rethrow;
    }
  }

  /// Stop the current Bluetooth scan
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print('Error stopping scan: $e');
    }
  }

  /// Connect to a Movesense device with automatic UUID detection
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _isConnecting = true;
      notifyListeners();

      await device.connect(timeout: const Duration(seconds: 30));
      _connectedDevice = device;

      // Discover services and characteristics
      List<BluetoothService> services = await device.discoverServices();

      // Auto-detect IMU service and characteristic
      bool foundIMUData = false;
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          // Look for readable/notifiable characteristics with multiple bytes
          if ((characteristic.properties.read ||
                  characteristic.properties.notify) &&
              characteristic.uuid.toString().isNotEmpty) {
            // Try to detect IMU data (typically has notify property and contains numeric data)
            if (characteristic.properties.notify) {
              _detectedServiceUUID = service.uuid.toString();
              _detectedCharacteristicUUID = characteristic.uuid.toString();
              _imuCharacteristic = characteristic;

              print('Auto-detected Service UUID: $_detectedServiceUUID');
              print(
                'Auto-detected Characteristic UUID: $_detectedCharacteristicUUID',
              );

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

      if (!foundIMUData) {
        print(
          'Warning: Could not auto-detect IMU characteristic. Please check sensor.',
        );
      }

      _isConnected = true;
      _isConnecting = false;
      notifyListeners();

      return foundIMUData;
    } catch (e) {
      print('Error connecting to device: $e');
      _isConnecting = false;
      _isConnected = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Setup listener for IMU data changes
  void _setupValueChangedListener() {
    _valueChangedSubscription = _imuCharacteristic?.onValueReceived.listen((
      List<int> value,
    ) {
      if (_isRecording) {
        final imuData = _parseIMUData(value);
        if (imuData != null) {
          _recordedData.add(imuData);
          notifyListeners();
        }
      }
    });
  }

  /// Parse raw IMU data from the sensor
  IMUData? _parseIMUData(List<int> rawData) {
    try {
      if (rawData.length < 26) {
        return null; // Not enough data
      }

      final byteData = ByteData.sublistView(Uint8List.fromList(rawData));

      // Movesense IMU data format (typically 3 floats for accel, 3 for gyro)
      // Adjust offsets based on your Movesense sensor's specific data format
      final accelX = byteData.getFloat32(0, Endian.little);
      final accelY = byteData.getFloat32(4, Endian.little);
      final accelZ = byteData.getFloat32(8, Endian.little);
      final gyroX = byteData.getFloat32(12, Endian.little);
      final gyroY = byteData.getFloat32(16, Endian.little);
      final gyroZ = byteData.getFloat32(20, Endian.little);

      return IMUData(
        timestamp: DateTime.now(),
        accelX: accelX,
        accelY: accelY,
        accelZ: accelZ,
        gyroX: gyroX,
        gyroY: gyroY,
        gyroZ: gyroZ,
      );
    } catch (e) {
      print('Error parsing IMU data: $e');
      return null;
    }
  }

  /// Start recording IMU data
  void startRecording() {
    if (_isConnected && _imuCharacteristic != null) {
      _isRecording = true;
      _recordedData.clear();
      notifyListeners();
      print('Recording started');
    } else {
      print('Cannot start recording: not connected to device');
    }
  }

  /// Stop recording IMU data
  void stopRecording() {
    _isRecording = false;
    notifyListeners();
    print('Recording stopped. Collected ${_recordedData.length} data points');
  }

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

  /// Clear recorded data
  void clearRecordedData() {
    _recordedData.clear();
    notifyListeners();
  }

  /// Disconnect from the device
  Future<void> disconnect() async {
    try {
      if (_imuCharacteristic != null) {
        await _imuCharacteristic!.setNotifyValue(false);
      }
      _valueChangedSubscription?.cancel();

      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }

      _connectedDevice = null;
      _imuCharacteristic = null;
      _isConnected = false;
      _isRecording = false;
      _recordedData.clear();

      notifyListeners();
      print('Disconnected from device');
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  @override
  void dispose() {
    _valueChangedSubscription?.cancel();
    super.dispose();
  }
}
