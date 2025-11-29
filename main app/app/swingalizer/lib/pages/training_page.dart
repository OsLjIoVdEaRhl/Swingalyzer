import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  int? expandedIndex;
  String feedback = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalysisFeedback();
  }

  Future<void> _loadAnalysisFeedback() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data()?.containsKey('sessionSummary') == true) {
          final sessionData = doc['sessionSummary'];
          setState(() {
            feedback = sessionData['feedback'] ?? '';
            isLoading = false;
          });
        } else {
          setState(() {
            feedback =
                'No analysis data available. Please analyze a swing first.';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        feedback = 'Error loading analysis: $e';
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _generateDrillsFromFeedback() {
    if (feedback.isEmpty || feedback.contains('No analysis')) {
      return [
        {
          'title': 'Start by Analyzing',
          'description': 'Analyze a swing to get personalized drills',
          'icon': Icons.info_outline,
          'color': Color(0xFF7BE39A),
          'steps': [
            'Go to the Analyze page',
            'Select your accelerometer and gyro CSV files',
            'Receive personalized training recommendations'
          ],
        }
      ];
    }

    final List<Map<String, dynamic>> generatedDrills = [];
    final lowerFeedback = feedback.toLowerCase();

    // Parse feedback and create relevant drills
    if (lowerFeedback.contains('tempo') ||
        lowerFeedback.contains('rhythm') ||
        lowerFeedback.contains('timing')) {
      generatedDrills.add({
        'title': 'Tempo Drill',
        'description': 'Master consistent swing rhythm',
        'icon': Icons.timer,
        'color': Color(0xFF7BE39A),
        'steps': [
          'Practice slow swings with metronome at 80 BPM',
          'Record and analyze swing tempo consistency',
          'Gradually increase speed while keeping rhythm smooth'
        ],
      });
    }

    if (lowerFeedback.contains('distance') ||
        lowerFeedback.contains('power') ||
        lowerFeedback.contains('speed')) {
      generatedDrills.add({
        'title': 'Distance Control',
        'description': 'Improve accuracy and distance',
        'icon': Icons.straighten,
        'color': Color(0xFF42C18C),
        'steps': [
          'Focus on consistent contact point on clubface',
          'Use markers at 20, 40, 60 yard intervals',
          'Adjust swing strength progressively for target accuracy'
        ],
      });
    }

    if (lowerFeedback.contains('backswing') ||
        lowerFeedback.contains('takeaway') ||
        lowerFeedback.contains('path')) {
      generatedDrills.add({
        'title': 'Backswing Path',
        'description': 'Refine your backswing mechanics',
        'icon': Icons.trending_up,
        'color': Color(0xFF00BFA6),
        'steps': [
          'Check alignment with target line consistently',
          'Practice smooth, controlled takeaway motion',
          'Film your swing to monitor over-rotation'
        ],
      });
    }

    if (lowerFeedback.contains('impact') ||
        lowerFeedback.contains('contact') ||
        lowerFeedback.contains('clubface')) {
      generatedDrills.add({
        'title': 'Impact Position',
        'description': 'Optimize your impact point',
        'icon': Icons.gps_fixed,
        'color': Color(0xFF00D9B8),
        'steps': [
          'Focus on keeping clubface square at impact',
          'Keep wrists firm and stable through impact zone',
          'Practice hitting the sweet spot consistently'
        ],
      });
    }

    if (lowerFeedback.contains('alignment') ||
        lowerFeedback.contains('stance') ||
        lowerFeedback.contains('posture')) {
      generatedDrills.add({
        'title': 'Alignment Drill',
        'description': 'Improve body alignment and posture',
        'icon': Icons.straighten,
        'color': Color(0xFF76E4A1),
        'steps': [
          'Set alignment sticks parallel to target line',
          'Practice address position with proper alignment',
          'Check shoulder and hip alignment at setup'
        ],
      });
    }

    if (lowerFeedback.contains('rotation') ||
        lowerFeedback.contains('hip') ||
        lowerFeedback.contains('shoulder')) {
      generatedDrills.add({
        'title': 'Rotation Drill',
        'description': 'Improve body rotation and sequencing',
        'icon': Icons.rotate_90_degrees_ccw,
        'color': Color(0xFF6DD897),
        'steps': [
          'Practice hip rotation independently of shoulders',
          'Use resistance band for controlled rotation',
          'Focus on proper downswing sequence'
        ],
      });
    }

    // If no specific drills matched, provide general recommendations
    if (generatedDrills.isEmpty) {
      generatedDrills.add({
        'title': 'Overall Practice',
        'description': 'Based on your analysis',
        'icon': Icons.golf_course,
        'color': Color(0xFF7BE39A),
        'steps': [
          feedback.split('\n').isNotEmpty
              ? feedback.split('\n').first
              : 'Continue practicing your swing',
          'Focus on one improvement at a time',
          'Record your swings to track progress'
        ],
      });
    }

    return generatedDrills;
  }

  @override
  Widget build(BuildContext context) {
    final drills = _generateDrillsFromFeedback();

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF093823),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF093823),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Training Drills',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Improve your swing with targeted drills',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 18),
              for (int i = 0; i < drills.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: _DrillCard(
                    drill: drills[i],
                    isExpanded: expandedIndex == i,
                    onTap: () {
                      setState(() {
                        expandedIndex = expandedIndex == i ? null : i;
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrillCard extends StatelessWidget {
  final Map<String, dynamic> drill;
  final bool isExpanded;
  final VoidCallback onTap;

  const _DrillCard({
    required this.drill,
    required this.isExpanded,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color baseColor = drill['color'] as Color;
    final List<String> steps = List<String>.from(drill['steps'] ?? []);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExpanded
              ? [baseColor.withOpacity(0.3), baseColor.withOpacity(0.6)]
              : [baseColor.withOpacity(0.15), baseColor.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isExpanded ? 0.4 : 0.2),
            blurRadius: isExpanded ? 12 : 6,
            offset: Offset(0, isExpanded ? 6 : 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [baseColor, baseColor.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: baseColor.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Icon(
                        drill['icon'] as IconData,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            drill['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            drill['description'] as String,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.white70, size: 20),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: steps
                          .map(
                            (step) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• ',
                                    style: TextStyle(
                                        color: baseColor.withOpacity(0.9),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  Expanded(
                                    child: Text(
                                      step,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
