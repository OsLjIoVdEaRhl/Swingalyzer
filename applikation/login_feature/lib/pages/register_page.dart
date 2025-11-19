import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback showLoginPage;
  const RegisterPage({super.key, required this.showLoginPage});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  String _dominantHand = 'Right';
  String _ballFlight = 'Straight';
  final TextEditingController _otherFlightController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _yearController.dispose();
    _otherFlightController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final name =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
    final typicalFlight = _ballFlight == 'Other'
        ? _otherFlightController.text.trim()
        : _ballFlight;

    try {
      final user = await auth.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        name,
        phone: _phoneController.text.trim(),
        dominantHand: _dominantHand,
        typicalBallFlight: typicalFlight,
      );
      setState(() => _isLoading = false);

      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Registration failed')));
      }
      // On success, AuthWrapper stream will show HomePage
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First name'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter first name' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last name'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter last name' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter phone number' : null,
                ),

                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _dominantHand,
                  items: const [
                    DropdownMenuItem(value: 'Right', child: Text('Right')),
                    DropdownMenuItem(value: 'Left', child: Text('Left')),
                  ],
                  onChanged: (v) =>
                      setState(() => _dominantHand = v ?? 'Right'),
                  decoration: const InputDecoration(labelText: 'Dominant hand'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _ballFlight,
                  items: const [
                    DropdownMenuItem(
                      value: 'Straight',
                      child: Text('Straight'),
                    ),
                    DropdownMenuItem(value: 'Draw', child: Text('Draw')),
                    DropdownMenuItem(value: 'Fade', child: Text('Fade')),
                    DropdownMenuItem(value: 'Slice', child: Text('Slice')),
                    DropdownMenuItem(value: 'Hook', child: Text('Hook')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) =>
                      setState(() => _ballFlight = v ?? 'Straight'),
                  decoration: const InputDecoration(
                    labelText: 'Typical ball flight',
                  ),
                ),
                if (_ballFlight == 'Other') ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _otherFlightController,
                    decoration: const InputDecoration(
                      labelText: 'Describe ball flight',
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Describe your ball flight'
                        : null,
                  ),
                ],
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter email' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Password min 6 chars'
                      : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Create account'),
                ),
                TextButton(
                  onPressed: widget.showLoginPage,
                  child: const Text('Back to sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
