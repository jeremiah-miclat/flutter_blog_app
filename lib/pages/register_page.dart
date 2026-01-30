import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _displayName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    if (_displayName.text == '' || _email.text == '' || _password.text == '') {
      _toast("Please fill out all inputs");
      return;
    }

    setState(() => _loading = true);

    try {
      await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        data: {"display_name": _displayName},
      );
    } on AuthException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Something went wrong. Please try again');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _displayName.dispose();
    _password.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 30.0,
          children: [
            TextField(
              controller: _displayName,
              decoration: const InputDecoration(labelText: 'Display Name'),
              maxLength: 20,
            ),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              maxLength: 20,
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _register,
                child: Text(_loading ? 'Please wait...' : 'Create Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
