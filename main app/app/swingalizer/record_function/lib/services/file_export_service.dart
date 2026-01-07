import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'movesense_service.dart';

/// Service to handle CSV export and file management
class FileExportService {
  /// Export gyro data to CSV file
  Future<File> exportGyroDataToCSV(List<GyroData> data) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'gyro_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${directory.path}/$fileName');

    final csvData = <List<String>>[
      ['Timestamp', 'Gyro X', 'Gyro Y', 'Gyro Z'],
      ...data.map((d) => d.toCSVRow()),
    ];

    final csv = const ListToCsvConverter().convert(csvData);
    await file.writeAsString(csv);

    return file;
  }

  /// Export accel data to CSV file
  Future<File> exportAccelDataToCSV(List<AccelData> data) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'accel_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${directory.path}/$fileName');

    final csvData = <List<String>>[
      ['Timestamp', 'Accel X', 'Accel Y', 'Accel Z'],
      ...data.map((d) => d.toCSVRow()),
    ];

    final csv = const ListToCsvConverter().convert(csvData);
    await file.writeAsString(csv);

    return file;
  }

  /// Export both gyro and accel data as CSV files and share them
  Future<void> exportAndShareData(
    List<GyroData> gyroData,
    List<AccelData> accelData,
  ) async {
    try {
      final gyroFile = await exportGyroDataToCSV(gyroData);
      final accelFile = await exportAccelDataToCSV(accelData);

      // Share both files
      await Share.shareXFiles([
        XFile(gyroFile.path),
        XFile(accelFile.path),
      ], text: 'Movesense IMU Recording');
    } catch (e) {
      print('Error exporting and sharing data: $e');
      rethrow;
    }
  }

  /// Get the list of recorded CSV files
  Future<List<File>> getRecordedFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final dir = Directory(directory.path);
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.csv'))
        .toList();
    return files;
  }

  /// Delete a CSV file
  Future<void> deleteFile(File file) async {
    await file.delete();
  }
}
