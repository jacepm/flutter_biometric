# flutter_biometric

Biometric R&D demo using `biometric_signature`.

This Flutter app is a small research project for testing hardware-backed biometric authentication and digital signatures across supported platforms. It focuses on local key generation, challenge signing, and visibility into biometric availability and plugin error states.

## What This R&D App Does

- Generates a biometric-protected key pair on-device
- Signs a sample challenge using biometric authentication
- Displays the generated public key in PEM format
- Displays the generated signature
- Checks whether biometrics are available and enrolled on the device
- Deletes stored biometric keys for repeatable testing
- Surfaces plugin result codes and error messages in the UI

## Current App Flow

The UI in [lib/main.dart](flutter_biometric/lib/main.dart) includes these actions:

1. `Check Biometric Availability`
   Verifies whether the current device can authenticate and whether biometrics are enrolled.
2. `Generate Keys`
   Creates a biometric-protected key pair and shows the public key.
3. `Sign Challenge`
   Signs the sample payload `sample_challenge_123` using the stored private key.
4. `Delete Keys`
   Clears generated biometric keys so the flow can be tested again from scratch.

If an operation fails, the app shows the plugin `code` and `error` returned by `biometric_signature`.

## Why This Matters

Unlike a simple biometric prompt that only returns `true` or `false`, `biometric_signature` uses device-protected keys and returns a cryptographic signature. That means a backend can verify that the request came from a device holding the registered private key, not just from a screen that was locally unlocked.

## Android Setup

This R&D app now matches the Android requirements of `biometric_signature`.

### 1. Dependency

Add this dependency in [pubspec.yaml](flutter_biometric/pubspec.yaml):

```yaml
dependencies:
  biometric_signature: ^10.2.0
```

### 2. Biometric Permission

Ensure [android/app/src/main/AndroidManifest.xml](flutter_biometric/android/app/src/main/AndroidManifest.xml) contains:

```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
```

### 3. Use `FlutterFragmentActivity`

`biometric_signature` requires a fragment-based activity on Android.

[android/app/src/main/kotlin/com/example/flutter_biometric/MainActivity.kt](flutter_biometric/android/app/src/main/kotlin/com/example/flutter_biometric/MainActivity.kt):

```kotlin
package com.example.flutter_biometric

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

### 4. Set `minSdk` to 24

The plugin requires Android SDK 24 or newer.

[android/app/build.gradle.kts](flutter_biometric/android/app/build.gradle.kts):

```kotlin
defaultConfig {
    applicationId = "com.example.flutter_biometric"
    minSdk = 24
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
}
```

### 5. Install Packages

Run:

```sh
flutter pub get
```

## iOS Setup

Face ID usage text is already defined in [ios/Runner/Info.plist](flutter_biometric/ios/Runner/Info.plist):

```xml
<key>NSFaceIDUsageDescription</key>
<string>We use biometrics for secure authentication</string>
```

## Example Usage

The current app uses the package like this:

```dart
final biometric = BiometricSignature();

final availability = await biometric.biometricAuthAvailable();

final keyResult = await biometric.createKeys(
  keyFormat: KeyFormat.pem,
  promptMessage: 'Authenticate to generate your biometric keys',
);

final signatureResult = await biometric.createSignature(
  payload: 'sample_challenge_123',
  promptMessage: 'Authenticate to sign the challenge',
);
```

Important: this plugin often returns failures in `result.code` and `result.error` instead of only throwing exceptions. For that reason, the app checks both success values and returned error metadata.

## Backend Integration Notes

For a real authentication flow, your backend should:

- Store the public key after registration
- Generate a fresh random challenge for every authentication attempt
- Verify the signature using the stored public key
- Reject replayed or reused challenges

Do not store biometric data or private keys on the backend.

## Testing Notes

For reliable testing:

- Use a real Android or iOS device when possible
- Make sure at least one biometric method is enrolled
- Start with `Check Biometric Availability` before generating keys
- If signing fails, read the displayed error code and reason from the app UI
- Use `Delete Keys` between test cycles if you want a clean reset

## iOS Testing

To test on iPhone:

- Open the iOS project in Xcode or run `flutter run` with an iOS device connected
- Make sure Face ID or Touch ID is enrolled on the device
- Launch the app and allow biometric access when prompted
- Tap `Check Biometric Availability`
- Tap `Generate Keys`
- Tap `Sign Challenge`

To test on the iOS simulator:

- Start an iPhone simulator
- In the simulator, enable biometric enrollment for the simulated device
- Run the app
- Use the simulator menu to trigger a matching or non-matching Face ID or Touch ID event during the prompt

Expected behavior:

- `Check Biometric Availability` should show that authentication is available
- `Generate Keys` should return a public key
- `Sign Challenge` should return a signature

If iOS fails:

- confirm the device has biometrics enrolled
- confirm [Info.plist](flutter_biometric/ios/Runner/Info.plist#L48) contains `NSFaceIDUsageDescription`
- check the error shown in the app UI
- retry on a real device if simulator behavior is inconsistent

## Troubleshooting

If `biometric_signature` is not working, these are the first things to verify:

- `MainActivity` extends `FlutterFragmentActivity`
- Android `minSdk` is `24` or higher
- `USE_BIOMETRIC` permission is present
- Biometrics are enrolled on the device
- You are testing on supported hardware or an emulator with biometric support
- The app shows `canAuthenticate: true` from the availability check

If the app still fails, capture the exact `Code:` and `Message:` shown in the UI. Those values are the fastest way to diagnose whether the issue is enrollment, device support, prompt cancellation, or key availability.

## Resources

- [biometric_signature pub.dev](https://pub.dev/packages/biometric_signature)
- [Flutter documentation](https://docs.flutter.dev/)

## Build APK

To build a release APK:

```sh
flutter build apk --release
```

The APK will be generated at:

`build/app/outputs/flutter-apk/app-release.apk`
