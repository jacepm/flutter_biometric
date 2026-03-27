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
  String error = '';
  String biometricStatus = '';

  String _formatPluginError(BiometricError? code, String? message) {
    final parts = <String>[
      if (code != null) 'Code: $code',
      if (message != null && message.isNotEmpty) 'Message: $message',
    ];
    return parts.isEmpty ? 'Unknown biometric error' : parts.join('\n');
  }

  Future<void> generateKeys() async {
    setState(() {
      error = '';
    });
    try {
      final result = await biometric.createKeys(
        keyFormat: KeyFormat.pem,
        promptMessage: 'Authenticate to generate your biometric keys',
      );
      setState(() {
        if (result.code == BiometricError.success && result.publicKey != null) {
          publicKey = result.publicKey!;
        } else {
          error = _formatPluginError(result.code, result.error);
        }
      });
    } catch (e) {
      setState(() {
        error = 'Error generating keys: $e';
      });
      debugPrint('Error generating keys: $e');
    }
  }

  Future<void> signChallenge() async {
    setState(() {
      error = '';
    });
    try {
      final sig = await biometric.createSignature(
        payload: challenge,
        promptMessage: 'Authenticate to sign the challenge',
      );
      setState(() {
        if (sig.code == BiometricError.success && sig.signature != null) {
          signature = sig.signature!;
        } else {
          error = _formatPluginError(sig.code, sig.error);
        }
      });
    } catch (e) {
      setState(() {
        error = 'Error signing: $e';
      });
      debugPrint('Error signing: $e');
    }
  }

  Future<void> deleteKeys() async {
    setState(() {
      error = '';
    });
    try {
      final deleted = await biometric.deleteKeys();
      setState(() {
        publicKey = '';
        signature = '';
        error = deleted ? 'Keys deleted.' : 'No keys to delete.';
      });
    } catch (e) {
      setState(() {
        error = 'Error deleting keys: $e';
      });
    }
  }

  Future<void> checkBiometricAvailable() async {
    setState(() {
      biometricStatus = 'Checking...';
    });
    try {
      final result = await biometric.biometricAuthAvailable();
      setState(() {
        biometricStatus = [
          'Can Authenticate: ${result.canAuthenticate}',
          'Has Enrolled Biometrics: ${result.hasEnrolledBiometrics}',
          'Available Biometrics: ${result.availableBiometrics}',
          if (result.reason != null && result.reason!.isNotEmpty)
            'Reason: ${result.reason}',
        ].join('\n');
      });
    } catch (e) {
      setState(() {
        biometricStatus = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biometric R&D')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: generateKeys,
                  child: const Text('Generate Keys'),
                ),
                ElevatedButton(
                  onPressed: deleteKeys,
                  child: const Text('Delete Keys'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: checkBiometricAvailable,
              child: const Text('Check Biometric Availability'),
            ),
            if (biometricStatus.isNotEmpty) ...[
              const SizedBox(height: 10),
              SelectableText('Biometric Status:\n$biometricStatus'),
            ],
            const SizedBox(height: 10),
            SelectableText('Public Key:\n$publicKey'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: signChallenge,
              child: const Text('Sign Challenge'),
            ),
            const SizedBox(height: 10),
            SelectableText('Challenge: $challenge'),
            SelectableText('Signature:\n$signature'),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 10),
              SelectableText(
                'Error: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
