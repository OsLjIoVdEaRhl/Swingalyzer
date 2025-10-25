import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class MainTempPage extends StatefulWidget {
  const MainTempPage({super.key});

  @override
  State<MainTempPage> createState() => _MainTempPageState();
}

class _MainTempPageState extends State<MainTempPage> {
  String? _accelFilePath;
  String? _gyroFilePath;
  final List<String> _allowedExtensions = ['csv'];
  String _responseText = '';

  // ===== File picker =====
  Future<String?> _pickCSVFile() async {
    try {
      const channel = MethodChannel('file_picker_channel');
      final String? path = await channel.invokeMethod('pickFile', {
        'allowedExtensions': _allowedExtensions,
      });
      if (path != null) {
        final file = File(path);
        if (await file.exists()) return path;
      }
    } on PlatformException catch (e) {
      debugPrint('Failed to pick file: ${e.message}');
    }
    return null;
  }

  Future<void> _pickAccelFile() async {
    final path = await _pickCSVFile();
    if (path != null) setState(() => _accelFilePath = path);
  }

  Future<void> _pickGyroFile() async {
    final path = await _pickCSVFile();
    if (path != null) setState(() => _gyroFilePath = path);
  }

  // ===== Upload CSV files to FastAPI =====
  Future<void> _uploadCSVFiles() async {
    if (_accelFilePath == null || _gyroFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick both files first')),
      );
      return;
    }

    var uri = Uri.parse('http://10.22.2.155:8000/analyze_swing');
    var request = http.MultipartRequest('POST', uri)
      ..files.add(
        await http.MultipartFile.fromPath('acc_file', _accelFilePath!),
      )
      ..files.add(
        await http.MultipartFile.fromPath('gyro_file', _gyroFilePath!),
      );

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var respStr = await response.stream.bytesToString();
        setState(() {
          _responseText = respStr;
        });
      } else {
        setState(() {
          _responseText = 'Upload failed with status: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _responseText = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CSV File Picker & Analyzer')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _pickAccelFile,
                icon: const Icon(Icons.sensors),
                label: const Text('Choose Accelerometer File'),
              ),
              if (_accelFilePath != null)
                Text('Accelerometer: $_accelFilePath'),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickGyroFile,
                icon: const Icon(Icons.threesixty),
                label: const Text('Choose Gyroscope File'),
              ),
              if (_gyroFilePath != null) Text('Gyroscope: $_gyroFilePath'),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _uploadCSVFiles,
                icon: const Icon(Icons.upload),
                label: const Text('Analyze Swing'),
              ),
              const SizedBox(height: 20),
              if (_responseText.isNotEmpty)
                SelectableText(
                  _responseText,
                  style: const TextStyle(fontSize: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
