// analyze_page.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class AnalyzePage extends StatefulWidget {
  const AnalyzePage({super.key});

  @override
  State<AnalyzePage> createState() => _AnalyzePageState();
}

class _AnalyzePageState extends State<AnalyzePage> {
  static const Color _background = Color(0xFF093823);
  static const Color _panel = Color(0xFF0D2F22);
  static const Color _accent = Color(0xFF7BE39A);

  PlatformFile? file1Web;
  PlatformFile? file2Web;
  String? file1Path;
  String? file2Path;

  bool isLoading = false;
  String feedback = '';

  // Summary values to display in the three boxes
  String impactOrientationLabel = '—';
  String clubSpeedLabel = '—';
  String tempoRatioLabel = '—';

  final String backendUrl = "http://127.0.0.1:8000/analyze_swing";

  Future<void> pickBothFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: true,
      withData: kIsWeb,
    );

    if (result != null && result.files.length >= 2) {
      if (kIsWeb) {
        setState(() {
          file1Web = result.files[0];
          file2Web = result.files[1];
        });
      } else {
        setState(() {
          file1Path = result.files[0].path;
          file2Path = result.files[1].path;
        });
      }
      await _autoAnalyze();
    } else if (result != null && result.files.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select 2 CSV files')),
      );
    }
  }

  Future<String> _readFileAsString(dynamic fileSource) async {
    if (fileSource is PlatformFile) {
      return String.fromCharCodes(fileSource.bytes!);
    } else if (fileSource is String) {
      return await File(fileSource).readAsString();
    }
    return '';
  }

  Future<String> _detectSensorType(List<String> csvLines) async {
    try {
      if (csvLines.length < 2) return "unknown";
      final headers =
          csvLines[0].split(',').map((h) => h.trim().toLowerCase()).toList();
      if (!headers.contains('x') ||
          !headers.contains('y') ||
          !headers.contains('z')) {
        return "unknown";
      }
      final xIdx = headers.indexOf('x');
      final yIdx = headers.indexOf('y');
      final zIdx = headers.indexOf('z');

      List<double> allValues = [];
      for (int i = 1; i < csvLines.length && allValues.length < 100; i++) {
        try {
          final parts = csvLines[i].split(',');
          if (parts.length > zIdx) {
            final x = double.parse(parts[xIdx].trim());
            final y = double.parse(parts[yIdx].trim());
            final z = double.parse(parts[zIdx].trim());
            allValues.addAll([x.abs(), y.abs(), z.abs()]);
          }
        } catch (_) {}
      }
      if (allValues.isEmpty) return "unknown";
      allValues.sort();
      final median = allValues[allValues.length ~/ 2];
      final maxVal = allValues.last;
      double mean = allValues.reduce((a, b) => a + b) / allValues.length;
      double variance = allValues
              .map((v) => (v - mean) * (v - mean))
              .reduce((a, b) => a + b) /
          allValues.length;

      if (maxVal < 25 && median < 2) return "gyro";
      if (maxVal >= 25 || variance > 5) return "accel";
      return "gyro";
    } catch (_) {
      return "unknown";
    }
  }

  // reduce two ints by gcd
  int _gcd(int a, int b) {
    a = a.abs();
    b = b.abs();
    if (a == 0) return b;
    if (b == 0) return a;
    while (b != 0) {
      int t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

  // Format backswing_time and downswing_time into simplified integer ratio "A:B"
  String _formatRatio(dynamic backswingTime, dynamic downswingTime) {
    if (backswingTime == null || downswingTime == null) return '—';
    double bs;
    double ds;
    try {
      bs = (backswingTime is num)
          ? backswingTime.toDouble()
          : double.parse(backswingTime.toString());
      ds = (downswingTime is num)
          ? downswingTime.toDouble()
          : double.parse(downswingTime.toString());
    } catch (_) {
      return '—';
    }
    if (bs <= 0 || ds <= 0) return '—';
    // Convert to milliseconds ints to preserve precision, then reduce by gcd
    int ai = (bs * 1000).round();
    int bi = (ds * 1000).round();
    if (ai == 0 || bi == 0) return '—';
    int g = _gcd(ai, bi);
    int a_s = (ai / g).round();
    int b_s = (bi / g).round();
    // If numbers are large, scale down by dividing by 10 while still integers
    if (a_s > 50 || b_s > 50) {
      int scale = (max(a_s, b_s) / 10).ceil();
      a_s = (a_s / scale).round();
      b_s = (b_s / scale).round();
      if (a_s == 0) a_s = 1;
      if (b_s == 0) b_s = 1;
    }
    return '$a_s:$b_s';
  }

  Future<void> _autoAnalyze() async {
    if (isLoading) return;
    if ((kIsWeb && (file1Web == null || file2Web == null)) ||
        (!kIsWeb && (file1Path == null || file2Path == null))) {
      setState(() {
        feedback = 'Please select both CSV files.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      feedback = 'Detecting sensor types...';
    });

    try {
      final content1 = await _readFileAsString(kIsWeb ? file1Web : file1Path);
      final content2 = await _readFileAsString(kIsWeb ? file2Web : file2Path);
      final lines1 = content1.split('\n');
      final lines2 = content2.split('\n');

      final type1 = await _detectSensorType(lines1);
      final type2 = await _detectSensorType(lines2);

      dynamic accelFile;
      dynamic gyroFile;

      if (type1 == 'accel' && type2 == 'gyro') {
        accelFile = kIsWeb ? file1Web : file1Path;
        gyroFile = kIsWeb ? file2Web : file2Path;
      } else if (type1 == 'gyro' && type2 == 'accel') {
        accelFile = kIsWeb ? file2Web : file2Path;
        gyroFile = kIsWeb ? file1Web : file1Path;
      } else {
        setState(() {
          feedback =
              'Could not reliably detect types.\nFile1: $type1  File2: $type2';
          isLoading = false;
        });
        return;
      }

      setState(() {
        feedback =
            'Detected: accel -> ${type1 == 'accel' ? 'file1' : 'file2'} , uploading...';
      });

      var uri = Uri.parse(backendUrl);
      var request = http.MultipartRequest('POST', uri);

      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
            'acc_file', (accelFile as PlatformFile).bytes!,
            filename: accelFile.name));
        request.files.add(http.MultipartFile.fromBytes(
            'gyro_file', (gyroFile as PlatformFile).bytes!,
            filename: gyroFile.name));
      } else {
        request.files.add(
            await http.MultipartFile.fromPath('acc_file', accelFile as String));
        request.files.add(
            await http.MultipartFile.fromPath('gyro_file', gyroFile as String));
      }

      var response = await request.send();
      var body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        try {
          final data = json.decode(body);
          final summary = data['summary'] ?? {};
          setState(() {
            // Feedback text from GPT
            feedback = data['feedback'] ?? '';

            // Fill UI boxes from summary
            final tempo = summary['tempo_ratio'];
            final clubSpeed = summary['club_speed'];
            final impact = summary['impact_orientation'];
            final backswingTime = summary['backswing_time'];
            final downswingTime = summary['downswing_time'];

            // Format tempo as A:B using backswing_time and downswing_time if available
            tempoRatioLabel = _formatRatio(backswingTime, downswingTime);

            // Club speed: prefer numeric clubSpeed (server returns m/s) else placeholder
            clubSpeedLabel =
                clubSpeed != null ? '${clubSpeed.toString()} m/s' : '—';

            // Impact orientation: show uppercase user-friendly label
            impactOrientationLabel =
                impact != null ? impact.toString().toUpperCase() : '—';
          });

          // Persist summary to Firestore under current user
          try {
            final user = firebase_auth.FirebaseAuth.instance.currentUser;
            if (user != null) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .set({'sessionSummary': summary}, SetOptions(merge: true));
            }
          } catch (e) {
            // Non-fatal: log but do not interrupt UI
            debugPrint('Failed to save sessionSummary: $e');
          }
        } catch (e) {
          setState(() {
            feedback = 'Server returned invalid JSON: $e';
          });
        }
      } else {
        setState(() {
          feedback = 'Upload failed: ${response.statusCode}\n$body';
        });
      }
    } catch (e) {
      setState(() {
        feedback = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _displayName() {
    if (kIsWeb) {
      final f1 = file1Web?.name ?? 'No file 1';
      final f2 = file2Web?.name ?? 'No file 2';
      return 'File 1: $f1\nFile 2: $f2';
    } else {
      final f1 = file1Path != null
          ? file1Path!.split(RegExp(r'[\\/]+')).last
          : 'No file 1';
      final f2 = file2Path != null
          ? file2Path!.split(RegExp(r'[\\/]+')).last
          : 'No file 2';
      return 'File 1: $f1\nFile 2: $f2';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _background,
      child: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Current Swing',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Live metrics — select CSVs to analyze a recorded swing',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: _StatPanel(
                              panelColor: _panel,
                              title: 'Impact angle',
                              value: impactOrientationLabel,
                              valueStyle: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: _StatPanel(
                              panelColor: _panel,
                              title: 'Club speed',
                              value: clubSpeedLabel,
                              valueStyle: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 130,
                      child: _StatPanel(
                        panelColor: _panel,
                        title: 'Backswing : Swing ratio',
                        value: tempoRatioLabel,
                        isLarge: true,
                        titleStyle: const TextStyle(fontSize: 16),
                        valueStyle: const TextStyle(
                            fontSize: 44, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: pickBothFiles,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Select Both CSV Files'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(_displayName(),
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    if (isLoading)
                      const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 12),

                    // ===== Feedback Box =====
                    Container(
                      decoration: BoxDecoration(
                        color: _panel,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4))
                        ],
                        border: Border.all(
                            color: _accent.withOpacity(0.6), width: 1.5),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  color: _accent, size: 28),
                              SizedBox(width: 10),
                              Text('Swing Analysis',
                                  style: TextStyle(
                                      color: _accent,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: feedback
                                  .split('\n')
                                  .where((line) => line.trim().isNotEmpty)
                                  .map((line) {
                                final trimmed = line.trim();
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: Icon(
                                          Icons.circle,
                                          size: 8,
                                          color: _accent,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          trimmed.replaceFirst(
                                              RegExp(r'^[-•]\s*'), ''),
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                              height: 1.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      decoration: BoxDecoration(
                        color: _panel,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3))
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      child: const Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Session Summary',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                                SizedBox(height: 8),
                                Text(
                                    'Recent swings, speed over time and areas to improve.',
                                    style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),
                          Icon(Icons.insert_chart, color: _accent, size: 28),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StatPanel extends StatelessWidget {
  final Color panelColor;
  final String title;
  final String value;
  final bool isLarge;
  final TextStyle? titleStyle;
  final TextStyle? valueStyle;

  const _StatPanel({
    required this.panelColor,
    required this.title,
    required this.value,
    this.isLarge = false,
    this.titleStyle,
    this.valueStyle,
    Key? key,
  }) : super(key: key);

  static const Color _defaultValueGreen = Color(0xFF7BE39A);

  @override
  Widget build(BuildContext context) {
    final defaultTitle = TextStyle(
      color: Colors.white70,
      fontSize: isLarge ? 16 : 14,
      fontWeight: FontWeight.w600,
    );
    final defaultValue = TextStyle(
      color: _defaultValueGreen,
      fontSize: isLarge ? 40 : 30,
      fontWeight: FontWeight.w800,
    );

    final tStyle = (titleStyle ?? defaultTitle).copyWith(
      color: titleStyle?.color ?? defaultTitle.color,
      fontSize: titleStyle?.fontSize ?? defaultTitle.fontSize,
      fontWeight: titleStyle?.fontWeight ?? defaultTitle.fontWeight,
    );

    final vStyle = (valueStyle ?? defaultValue).copyWith(
      color: valueStyle?.color ?? defaultValue.color,
      fontSize: valueStyle?.fontSize ?? defaultValue.fontSize,
      fontWeight: valueStyle?.fontWeight ?? defaultValue.fontWeight,
    );

    return Container(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.20),
              blurRadius: 6,
              offset: const Offset(0, 3))
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: tStyle, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(value, style: vStyle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
