/// Model for IMU (Inertial Measurement Unit) data from the Movesense sensor
class IMUData {
  final DateTime timestamp;
  final double accelX;
  final double accelY;
  final double accelZ;
  final double gyroX;
  final double gyroY;
  final double gyroZ;

  IMUData({
    required this.timestamp,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
  });

  /// Convert IMU data to CSV format
  String toCSV() {
    return '$timestamp,$accelX,$accelY,$accelZ,$gyroX,$gyroY,$gyroZ';
  }

  /// Get CSV header
  static String getCSVHeader() {
    return 'Timestamp,AccelX,AccelY,AccelZ,GyroX,GyroY,GyroZ';
  }

  @override
  String toString() {
    return 'IMUData(time: $timestamp, accel: [$accelX, $accelY, $accelZ], gyro: [$gyroX, $gyroY, $gyroZ])';
  }
}
