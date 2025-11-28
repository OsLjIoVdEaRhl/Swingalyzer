# Login Feature Integration Guide

This folder contains a complete Firebase email/password authentication system with user profile management. Follow these steps to integrate it into your Flutter app.

## Overview

The login feature includes:

- User registration (email, password, name, phone, year joined, dominant hand, typical ball flight)
- User sign-in (email, password)
- Home page showing user profile
- Firestore integration to store user data
- Profile data fetching and display

## Prerequisites

- Flutter SDK (3.9.2 or later)
- Firebase project with:
  - Authentication (Email/Password enabled)
  - Firestore Database
  - Android and/or iOS app registered

## Step 1: Copy Files to Your Main App

Copy the entire `Login_feature` folder structure into your main Flutter app:

```
your_main_app/
├── lib/
│   ├── services/
│   │   └── auth_service.dart        ← Copy from Login_feature/lib/services/
│   ├── pages/
│   │   ├── login_page.dart          ← Copy from Login_feature/lib/pages/
│   │   ├── register_page.dart       ← Copy from Login_feature/lib/pages/
│   │   └── home_page.dart           ← Copy from Login_feature/lib/pages/
│   ├── firebase_options.dart        ← Copy from Login_feature/lib/firebase_options.dart
│   └── main.dart                    ← Merge with your existing main.dart (see Step 4)
├── android/
│   ├── build.gradle.kts
│   └── app/
│       ├── build.gradle.kts
│       └── google-services.json     ← Add your Firebase config file
├── ios/
│   └── Runner/
│       └── GoogleService-Info.plist ← Add your Firebase config file
└── pubspec.yaml                     ← Update with dependencies
```

## Step 2: Update `pubspec.yaml`

Add the following dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.0
  firebase_auth: ^4.17.1
  cloud_firestore: ^4.13.3
  provider: ^6.1.1
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

Then run:

```bash
flutter pub get
```

## Step 3: Configure Firebase

### 3a. Create/Register Firebase Apps

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select an existing one
3. Register your app for Android:
   - Settings → Your apps → Android → Register new app
   - Download `google-services.json`
   - Place it in `android/app/`
4. Register your app for iOS:
   - Settings → Your apps → iOS → Register new app
   - Download `GoogleService-Info.plist`
   - Add it to `ios/Runner/` in Xcode

### 3b. Enable Email/Password Authentication

1. Go to Firebase Console → Authentication → Sign-in method
2. Enable "Email/Password"
3. Click Save

### 3c. Configure Firestore Database

1. Go to Firebase Console → Firestore Database → Create database
2. Start in test mode (for development)
3. Choose a region
4. Once created, go to Rules tab and paste:

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

Then click Publish.

## Step 4: Update Your `main.dart`

Replace or merge your existing `main.dart` with the one from `Login_feature/lib/main.dart`. The key parts are:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [Provider<AuthService>(create: (_) => AuthService())],
      child: MaterialApp(
        title: 'Your App',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<firebase_auth.User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomePage();
        } else {
          return const LoginRegisterPage();
        }
      },
    );
  }
}

class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage> {
  bool showLoginPage = true;

  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(showRegisterPage: togglePages);
    } else {
      return RegisterPage(showLoginPage: togglePages);
    }
  }
}
```

If you have other screens in your app, wrap them conditionally after `HomePage()` or integrate `HomePage()` as a tab/section.

## Step 5: Update Firebase Options (Important!)

The `firebase_options.dart` file contains the Firebase credentials. **Your friend must regenerate it** for their own Firebase project:

1. Install FlutterFire CLI (if not already installed):

   ```bash
   dart pub global activate flutterfire_cli
   export PATH="$PATH":"$HOME/.pub-cache/bin"
   ```

2. From your main app root, run:

   ```bash
   flutterfire configure
   ```

3. Select your Firebase project when prompted
4. Select the platforms (Android/iOS/Web)
5. The CLI will update `lib/firebase_options.dart` with your project credentials

**Do not use the `firebase_options.dart` from this folder** — it contains test project credentials and won't work for your friend's setup.

## Step 6: Android-Specific Setup (if targeting Android)

Ensure `android/build.gradle.kts` (project-level) includes the Google Services plugin:

```kotlin
buildscript {
  repositories {
    google()
    mavenCentral()
  }
  dependencies {
    classpath("com.google.gms:google-services:4.4.0")
  }
}
```

And `android/app/build.gradle.kts` (app-level) applies the plugin:

```kotlin
plugins {
  id("com.android.application")
  id("kotlin-android")
  id("com.google.gms.google-services")  // Add this line
}
```

## Step 7: iOS-Specific Setup (if targeting iOS)

1. Open `ios/Runner.xcworkspace` in Xcode (not `.xcodeproj`)
2. Drag `GoogleService-Info.plist` into the Runner folder
3. Select "Copy if needed"
4. Ensure `GoogleService-Info.plist` is added to the Runner target (Build Phases → Copy Bundle Resources)

## Step 8: Run and Test

```bash
flutter pub get
flutter run
```

Try registering a new user with all profile fields (name, phone, year joined, dominant hand, ball flight). Then:

1. Check Firebase Console → Authentication → Users (should see the new user)
2. Check Firebase Console → Firestore Database → Data → users collection (should see a document with the user's UID containing all profile fields)

## Troubleshooting

### "FirebaseOptions have not been configured for [platform]"

- Run `flutterfire configure` to regenerate `firebase_options.dart` for your Firebase project

### User appears in Authentication but not in Firestore

- Check Firestore Rules → ensure they allow authenticated writes (see Step 3c)
- Check Firebase Console logs for permission errors
- Ensure `google-services.json` / `GoogleService-Info.plist` are correctly added

### "Permission denied" when writing to Firestore

- Go to Firestore Rules and update them (see Step 3c)
- The production rules require users to only write to their own documents

### App crashes on startup

- Ensure `Firebase.initializeApp()` is called in `main()` before `runApp()`
- Verify Firebase project credentials in `firebase_options.dart`
- Check Android Logcat / iOS Console for Firebase initialization errors

## File Structure Reference

```
Login_feature/
├── lib/
│   ├── main.dart                 # Entry point with Firebase init & auth routing
│   ├── firebase_options.dart     # Firebase config (MUST BE REGENERATED)
│   ├── services/
│   │   └── auth_service.dart     # Firebase Auth & Firestore wrapper
│   └── pages/
│       ├── login_page.dart       # Sign-in form
│       ├── register_page.dart    # Registration form (with profile fields)
│       └── home_page.dart        # Shows logged-in user's profile
├── android/
│   ├── app/
│   │   ├── build.gradle.kts
│   │   └── google-services.json  # ADD YOUR FILE HERE
│   └── build.gradle.kts
├── ios/
│   └── Runner/
│       └── GoogleService-Info.plist  # ADD YOUR FILE HERE
├── pubspec.yaml                  # Dependencies
└── INTEGRATION_GUIDE.md           # This file
```

## Next Steps

Once integrated and working:

1. **Customize UI**: Modify `pages/login_page.dart`, `register_page.dart`, and `home_page.dart` to match your app's design
2. **Add more fields**: Edit `AuthService.register()` and the form pages to add/remove profile fields
3. **Integrate with your app**: Replace or wrap the `AuthWrapper` in your main app to show your other screens after login
4. **Switch to production rules**: Update Firestore rules for a production-ready security model

## Questions?

Refer to:

- [Firebase Flutter Docs](https://firebase.flutter.dev/)
- [FlutterFire GitHub](https://github.com/firebase/flutterfire)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/start)
