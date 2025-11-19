import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _displayName;
  String? _phone;
  String? _yearJoined;
  String? _dominantHand;
  String? _typicalBallFlight;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    if (user != null) {
      // Try to read displayName from Firestore user doc if available
      try {
        final doc = await auth.getUserDoc(user.uid);
        setState(() {
          _displayName = doc?['name'] as String? ?? user.email;
          _phone = doc?['phone'] as String?;
          _yearJoined = doc?['yearJoined'] as String?;
          _dominantHand = doc?['dominantHand'] as String?;
          _typicalBallFlight = doc?['typicalBallFlight'] as String?;
        });
      } catch (_) {
        setState(() {
          _displayName = user.email;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, ${_displayName ?? user?.email ?? 'User'}'),
            const SizedBox(height: 12),
            Text('Email: ${user?.email ?? ''}'),
            const SizedBox(height: 8),
            if (_phone != null) Text('Phone: ${_phone!}'),
            if (_yearJoined != null) Text('Year joined: ${_yearJoined!}'),
            if (_dominantHand != null) Text('Dominant hand: ${_dominantHand!}'),
            if (_typicalBallFlight != null)
              Text('Typical ball flight: ${_typicalBallFlight!}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (user == null) return;
                final doc = await auth.getUserDoc(user.uid);
                if (doc != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User document already exists'),
                    ),
                  );
                  return;
                }

                final data = {
                  'name': _displayName ?? user.email,
                  'email': user.email,
                  'createdAt': FieldValue.serverTimestamp(),
                };

                try {
                  await auth.createUserDoc(user.uid, data);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User document created')),
                  );
                  // reload profile to show created fields
                  await _loadProfile();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating doc: $e')),
                  );
                }
              },
              child: const Text('Ensure profile in Firestore'),
            ),
          ],
        ),
      ),
    );
  }
}
