import 'package:flutter/material.dart';
import 'package:biometric_signature/biometric_signature.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Biometric R&D', home: const HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final biometric = BiometricSignature();

  String publicKey = '';
  String signature = '';
  String challenge = 'sample_challenge_123';

  Future<void> generateKeys() async {
    try {
      final result = await biometric.createKeys();
      setState(() {
        publicKey = result.publicKey!;
      });
    } catch (e) {
      debugPrint('Error generating keys: $e');
    }
  }

  Future<void> signChallenge() async {
    try {
      final sig = await biometric.createSignature(payload: challenge);

      setState(() {
        signature = sig.signature!;
      });
    } catch (e) {
      debugPrint('Error signing: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biometric R&D')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: generateKeys,
              child: const Text('Generate Keys'),
            ),
            const SizedBox(height: 10),
            Text('Public Key:\n$publicKey'),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: signChallenge,
              child: const Text('Sign Challenge'),
            ),
            const SizedBox(height: 10),
            Text('Challenge: $challenge'),
            Text('Signature:\n$signature'),
          ],
        ),
      ),
    );
  }
}
