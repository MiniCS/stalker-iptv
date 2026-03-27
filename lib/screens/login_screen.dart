import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _portalCtrl = TextEditingController(text: 'http://');
  final _macCtrl = TextEditingController(text: '00:1A:79:');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _portalCtrl.dispose();
    _macCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    final ok = await context.read<AppState>().login(_portalCtrl.text, _macCtrl.text);
    if (!mounted) return;
    if (!ok) {
      setState(() { _loading = false; _error = 'Připojení selhalo. Zkontroluj URL a MAC adresu.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tv, size: 80, color: Colors.blue),
              const SizedBox(height: 16),
              const Text('IPTV Přehrávač', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextField(
                controller: _portalCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL portálu',
                  hintText: 'http://portal.example.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _macCtrl,
                decoration: const InputDecoration(
                  labelText: 'MAC adresa',
                  hintText: '00:1A:79:XX:XX:XX',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.devices),
                ),
                autocorrect: false,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Připojit', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
