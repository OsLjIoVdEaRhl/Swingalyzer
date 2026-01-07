import 'package:permission_handler/permission_handler.dart';

/// Service to handle runtime permissions
class PermissionService {
  /// Request Bluetooth permissions
  static Future<bool> requestBluetoothPermissions() async {
    final status = await Permission.bluetooth.request();
    return status.isGranted;
  }

  /// Request location permissions (required for Bluetooth scanning on some Android versions)
  static Future<bool> requestLocationPermissions() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Request storage permissions
  static Future<bool> requestStoragePermissions() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Request all required permissions
  static Future<bool> requestAllPermissions() async {
    final bluetoothGranted = await requestBluetoothPermissions();
    final locationGranted = await requestLocationPermissions();
    final storageGranted = await requestStoragePermissions();

    return bluetoothGranted && locationGranted && storageGranted;
  }

  /// Check if all permissions are granted
  static Future<bool> areAllPermissionsGranted() async {
    final bluetooth = await Permission.bluetooth.isDenied;
    final location = await Permission.location.isDenied;
    final storage = await Permission.storage.isDenied;

    return !bluetooth && !location && !storage;
  }
}
