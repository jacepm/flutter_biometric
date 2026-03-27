# Backend Implementation Guide

This document explains how to implement backend support for the Flutter biometric R&D app in this repository.

The current app in [lib/main.dart](/d:/Work/jacepm/flutter_biometric/lib/main.dart) does two core things:

1. Generates a public/private key pair on the device using `biometric_signature`
2. Signs a challenge string using the device-protected private key

The backend is responsible for:

- Registering and storing the user's public key
- Generating a fresh challenge for authentication
- Verifying the returned signature
- Preventing replay attacks

## High-Level Flow

### Registration

1. The mobile app calls `createKeys()`
2. The app receives a public key
3. The app sends that public key to the backend
4. The backend stores the public key and associates it with the user and optionally the device

### Authentication

1. The app asks the backend for a challenge
2. The backend creates a random one-time challenge and stores it temporarily
3. The app signs that challenge using `createSignature(payload: challenge)`
4. The app sends the signature back to the backend
5. The backend verifies the signature against the stored public key
6. If valid, the backend marks the challenge as used and authenticates the user

## Recommended API Design

These endpoints are enough for a clean first implementation.

### 1. Register Public Key

`POST /api/biometric/register`

Request body:

```json
{
  "userId": "12345",
  "deviceId": "device-abc",
  "publicKeyPem": "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----"
}
```

Suggested response:

```json
{
  "success": true
}
```

### 2. Create Challenge

`POST /api/biometric/challenge`

Request body:

```json
{
  "userId": "12345",
  "deviceId": "device-abc"
}
```

Suggested response:

```json
{
  "challengeId": "8a7f2c57-4b77-4e4d-9e6e-442e1fbb5c9d",
  "challenge": "base64-or-random-string-from-server",
  "expiresAt": "2026-03-27T10:30:00Z"
}
```

### 3. Verify Signature

`POST /api/biometric/verify`

Request body:

```json
{
  "userId": "12345",
  "deviceId": "device-abc",
  "challengeId": "8a7f2c57-4b77-4e4d-9e6e-442e1fbb5c9d",
  "challenge": "base64-or-random-string-from-server",
  "signature": "base64-signature-from-app"
}
```

Suggested response:

```json
{
  "success": true,
  "accessToken": "your-session-or-jwt-token"
}
```

## Database Model

At minimum, you need two tables or collections.

### 1. Registered Biometric Keys

Suggested fields:

- `id`
- `userId`
- `deviceId`
- `publicKeyPem`
- `algorithm`
- `createdAt`
- `updatedAt`
- `isActive`

Notes:

- `deviceId` helps support multiple devices per user
- `isActive` helps rotate or revoke keys later
- if you store multiple keys, make only one active per device

### 2. Biometric Challenges

Suggested fields:

- `id`
- `userId`
- `deviceId`
- `challenge`
- `expiresAt`
- `usedAt`
- `createdAt`

Notes:

- A challenge should be one-time-use
- A challenge should expire quickly, for example in 1 to 5 minutes
- Reject any challenge that is expired or already used

## Important Security Rules

### Use a Fresh Challenge Every Time

Never verify a static challenge like `sample_challenge_123` in production.

That value is fine for local R&D, but a real backend must generate a fresh unpredictable challenge for each login attempt.

### Prevent Replay Attacks

After successful verification:

- mark the challenge as used
- reject the same `challengeId` if it is submitted again

### Never Trust the Client to Generate the Challenge

The backend must generate the challenge, store it, and verify the exact same value later.

### Store Only the Public Key

Do not store:

- private keys
- biometric templates
- raw biometric data

The private key remains on the device.

### Tie Key to User and Device

If possible, map each public key to:

- `userId`
- `deviceId`

This gives you better key lifecycle control when a device is lost, replaced, or re-enrolled.

## Signature Verification Logic

The Flutter app currently uses:

- `createKeys(keyFormat: KeyFormat.pem, ...)`
- `createSignature(payload: challenge, ...)`

That means the backend will typically receive:

- a PEM-encoded public key
- a Base64-encoded signature
- the original plaintext challenge string

The backend must verify the signature using:

- the stored public key
- the exact challenge string that was issued

## Node.js Example

This is a minimal verification example using Node.js and the built-in `crypto` module.

```js
const crypto = require('crypto');

function verifySignature(publicKeyPem, payload, signatureBase64) {
  const verifier = crypto.createVerify('SHA256');
  verifier.update(payload, 'utf8');
  verifier.end();

  return verifier.verify(publicKeyPem, Buffer.from(signatureBase64, 'base64'));
}
```

Example usage in an endpoint:

```js
app.post('/api/biometric/verify', async (req, res) => {
  const { userId, deviceId, challengeId, challenge, signature } = req.body;

  const keyRecord = await db.biometric_keys.findOne({
    userId,
    deviceId,
    isActive: true,
  });

  if (!keyRecord) {
    return res.status(404).json({ success: false, message: 'Key not found' });
  }

  const challengeRecord = await db.biometric_challenges.findOne({
    id: challengeId,
    userId,
    deviceId,
  });

  if (!challengeRecord) {
    return res.status(404).json({ success: false, message: 'Challenge not found' });
  }

  if (challengeRecord.usedAt) {
    return res.status(400).json({ success: false, message: 'Challenge already used' });
  }

  if (new Date(challengeRecord.expiresAt) < new Date()) {
    return res.status(400).json({ success: false, message: 'Challenge expired' });
  }

  if (challengeRecord.challenge !== challenge) {
    return res.status(400).json({ success: false, message: 'Challenge mismatch' });
  }

  const valid = verifySignature(keyRecord.publicKeyPem, challenge, signature);

  if (!valid) {
    return res.status(401).json({ success: false, message: 'Invalid signature' });
  }

  await db.biometric_challenges.update({ id: challengeId }, { usedAt: new Date().toISOString() });

  return res.json({
    success: true,
    accessToken: 'issue-real-token-here',
  });
});
```

## Registration Endpoint Example

A simple registration endpoint usually does this:

1. Authenticate the user with your normal login flow
2. Accept the public key from the mobile app
3. Validate that it is a valid PEM public key
4. Upsert it for the current user and device

Pseudo-flow:

```text
POST /api/biometric/register
-> validate authenticated user
-> validate deviceId
-> validate publicKeyPem
-> store or update key record
-> return success
```

## Suggested Mobile-to-Backend Flow

Your Flutter app can eventually evolve to this:

### Enrollment

1. User logs in with existing credentials
2. App calls `createKeys()`
3. App sends `publicKey` to `/api/biometric/register`
4. Backend stores the key

### Login With Biometrics

1. App calls `/api/biometric/challenge`
2. Backend returns `challengeId` and `challenge`
3. App calls `createSignature(payload: challenge)`
4. App sends `{ challengeId, challenge, signature }` to `/api/biometric/verify`
5. Backend verifies the signature and returns a token/session

## Error Handling Recommendations

Return clear backend responses for these cases:

- key not found
- challenge not found
- challenge expired
- challenge already used
- challenge mismatch
- invalid signature
- user or device not allowed

Example failure response:

```json
{
  "success": false,
  "message": "Challenge expired"
}
```

## Production Recommendations

For production, consider these additions:

- encrypt sensitive database fields at rest
- add audit logs for biometric registration and verification attempts
- add device revocation support
- rate-limit challenge creation and verification endpoints
- invalidate old keys when a new device key is registered
- attach challenge requests to a pre-auth session or user identity proof
- use HTTPS only
- monitor repeated invalid signature attempts

## R&D Notes For This Repository

The current Flutter app uses a hardcoded challenge:

```dart
String challenge = 'sample_challenge_123';
```

That is acceptable only for local research and UI testing.

Before integrating with a real backend, replace that flow with:

- fetch challenge from backend
- sign backend challenge
- send signature back for verification

## Suggested Next Step

After this document, the next useful change would be updating [lib/main.dart](/d:/Work/jacepm/flutter_biometric/lib/main.dart) to:

1. call a backend endpoint for a challenge
2. sign the returned challenge
3. call a backend verify endpoint

That would turn this repo from local biometric R&D into an end-to-end prototype.
