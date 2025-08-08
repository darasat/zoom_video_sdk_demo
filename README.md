
# zoom_video_sdk_demo

This Flutter project demonstrates how to integrate Zoom Video SDK to enable video calls, following the tutorial explained in my Medium article:  
[Integrate Flutter with Zoom VideoCalling](https://medium.com/@darasat/integratar-flutter-zoom-videocalling-960dbec5b8f7)

---

## Overview

This app uses the `flutter_zoom_videosdk` package to connect with Zoom’s native SDK, allowing users to join video sessions authenticated via JWT.

The article walks through the entire process — from initial setup, JWT generation, to Flutter implementation.

---

## Prerequisites

- Flutter installed ([Flutter installation guide](https://flutter.dev/docs/get-started/install))  
- Zoom Developer account with SDK Key and SDK Secret from [Zoom Marketplace](https://marketplace.zoom.us/)  
- Camera and microphone permissions configured for Android and iOS  

---

## Key Integration Steps

### 1. Add dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_zoom_videosdk: ^1.14.0
  permission_handler: ^11.4.0
  dart_jsonwebtoken: ^2.13.0
2. Configure permissions
AndroidManifest.xml:

xml
Copiar código
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
Info.plist for iOS:

xml
Copiar código
<key>NSCameraUsageDescription</key>
<string>Camera access is required for video calls.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required for video calls.</string>
3. Generate JWT
The article includes an example of generating the JWT token, which is necessary for authentication.

For security, generate this token in your backend, but for testing, you can generate it locally as follows:

dart
Copiar código
import 'dart:math';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

String makeId(int length) {
  String result = '';
  const String characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final rnd = Random();
  for (var i = 0; i < length; i++) {
    result += characters[rnd.nextInt(characters.length)];
  }
  return result;
}

String generateJwt(String sdkKey, String sdkSecret, String sessionName, int role) {
  final iat = DateTime.now();
  final exp = iat.add(const Duration(days: 2));
  final jwt = JWT({
    'app_key': sdkKey,
    'iat': (iat.millisecondsSinceEpoch / 1000).round(),
    'exp': (exp.millisecondsSinceEpoch / 1000).round(),
    'tpc': sessionName,
    'user_identity': makeId(10),
    'role_type': role, // 1: host, 2: participant
  });

  return jwt.sign(SecretKey(sdkSecret));
}
4. Use Zoom SDK in Flutter
Example main.dart showing how to create the Zoom view:

dart
Copiar código
import 'package:flutter/material.dart';
import 'package:flutter_zoom_videosdk/flutter_zoom_view.dart' as zoom;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Zoom Video SDK Demo')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              zoom.ZoomView.create(
                zoomViewOptions: zoom.ZoomViewOptions(
                  domain: 'zoom.us',
                  jwt: 'YOUR_GENERATED_JWT',
                  meetingNumber: 'MEETING_ID',
                  userName: 'DemoUser',
                  userId: '123456',
                  userType: zoom.ZoomUserType.ZoomUserTypeNormal,
                ),
              );
            },
            child: const Text('Join Meeting'),
          ),
        ),
      ),
    );
  }
}
Replace 'YOUR_GENERATED_JWT' and 'MEETING_ID' with actual values.

Resources
Integrate Flutter Zoom VideoCalling

Official Zoom Video SDK docs

