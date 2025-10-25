import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Remove these imports temporarily to test if they're causing issues
// import 'register_page.dart';
// import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final auth = FirebaseAuth.instance;
  bool isLoading = false;

  void login() async {
    setState(() {
      isLoading = true;
    });

    try {
      await auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      // Comment out navigation temporarily for testing
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (_) => const HomePage()),
      // );
      
      // Show success message instead
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful!')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController, 
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController, 
              decoration: const InputDecoration(
                labelText: 'Password', 
                border: OutlineInputBorder(),
              ), 
              obscureText: true
            ),
            const SizedBox(height: 20),
            isLoading 
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: login, 
                    child: const Text('Login')
                  ),
            TextButton(
              onPressed: () {
                // Comment out temporarily
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (_) => const RegisterPage()),
                // );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Register button pressed')),
                );
              },
              child: const Text('Create an account'),
            ),
          ],
        ),
      ),
    );
  }
}