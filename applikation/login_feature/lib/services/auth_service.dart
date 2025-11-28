// services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  firebase_auth.User? get currentUser => _auth.currentUser;

  // Stream of user authentication state
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<firebase_auth.User?> signIn(String email, String password) async {
    try {
      final firebase_auth.UserCredential result = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  // Register with email and password
  // Accepts additional profile fields to store in Firestore
  // Throws on Firestore error so caller sees detailed error message
  Future<firebase_auth.User?> register(
    String email,
    String password,
    String name, {
    String? phone,
    String? dominantHand,
    String? typicalBallFlight,
  }) async {
    try {
      print('[AuthService] Starting registration for email: $email');
      firebase_auth.UserCredential result = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      print('[AuthService] Auth user created. UID: ${result.user?.uid}');

      // Save user data to Firestore
      if (result.user != null) {
        final uid = result.user!.uid;
        final docRef = _firestore.collection('users').doc(uid);
        final data = <String, dynamic>{
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        };

        if (phone != null && phone.isNotEmpty) data['phone'] = phone;

        if (dominantHand != null && dominantHand.isNotEmpty) {
          data['dominantHand'] = dominantHand;
        }
        if (typicalBallFlight != null && typicalBallFlight.isNotEmpty) {
          data['typicalBallFlight'] = typicalBallFlight;
        }

        print(
          '[AuthService] Writing to Firestore: users/$uid with data: $data',
        );
        await docRef.set(data);
        print('[AuthService] Successfully wrote user document to Firestore');
      }

      return result.user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('[AuthService] Auth error (${e.code}): ${e.message}');
      rethrow;
    } catch (e) {
      print('[AuthService] Firestore/other error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user document from Firestore (returns null if not found)
  Future<Map<String, dynamic>?> getUserDoc(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  // Create or overwrite a user document for given uid with supplied data.
  // Useful for debugging when the document wasn't created during registration.
  Future<void> createUserDoc(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).set(data);
  }
}
