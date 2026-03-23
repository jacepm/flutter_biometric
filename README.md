# flutter_biometric

Biometric R&D Demo using `biometric_signature`

This Flutter app demonstrates how to use the `biometric_signature` package for secure, hardware-backed biometric authentication and digital signatures.

## Features

- Generate a biometric-protected public/private key pair on the device
- Sign a backend-provided challenge using biometrics (fingerprint/face)
- Display the public key and signature in the UI

## How it works

1. **Generate Keys**: Tapping "Generate Keys" creates a new key pair protected by the device's biometrics. The public key is shown in the app and should be sent to your backend for registration.
2. **Sign Challenge**: Tapping "Sign Challenge" signs a challenge string (e.g., from your backend) using the private key. The user must authenticate with biometrics. The resulting signature is shown and should be sent to your backend for verification.

## Backend Integration

Your backend should:

- Store the user's public key when first generated.
- Issue a random challenge string for authentication attempts.
- Verify the signature using the stored public key and the challenge.

**Never store the private key or biometric data on the backend.**

## Setup

1. Add the dependency in `pubspec.yaml`:
   ```yaml
   biometric_signature: ^10.2.0
   ```
2. For Android, ensure you have the following permission in `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
   ```
3. Run `flutter pub get` to install dependencies.

## Example Usage

See `lib/main.dart` for a simple UI and usage example:

```dart
final biometric = BiometricSignature();
final result = await biometric.createKeys();
final sig = await biometric.createSignature(payload: challenge);
```

## Notes

- This app is for research and development purposes.
- The `biometric_signature` package handles all biometric prompts and key management securely on the device.
- No need for the `local_auth` package unless you require its specific APIs.

## Resources

- [biometric_signature pub.dev](https://pub.dev/packages/biometric_signature)
- [Flutter documentation](https://docs.flutter.dev/)

## Building the APK (Android)

To build a release APK for Android:

1. Make sure you have Flutter installed and set up for Android development.
2. Run the following command in your project directory:

   ```sh
   flutter build apk --release
   ```

3. The generated APK will be located at:

   `build/app/outputs/flutter-apk/app-release.apk`

You can then install this APK on your device for testing or distribution.
