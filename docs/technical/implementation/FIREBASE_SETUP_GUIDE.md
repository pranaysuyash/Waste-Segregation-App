# Firebase Setup Guide for Waste Segregation App

This guide outlines the steps to set up and configure Firebase for the Waste Segregation App. Follow these instructions carefully to ensure proper integration and functionality.

## Prerequisites

- A Google Account
- Flutter development environment set up
- The Waste Segregation App codebase cloned locally

## 1. Create a Firebase Project

1.  **Go to the Firebase Console**: [https://console.firebase.google.com/](https://console.firebase.google.com/)
2.  **Add a new project** (or select an existing one if applicable).
3.  **Enter your project name** (e.g., "Waste Segregation App").
4.  **Configure Google Analytics** (recommended, but optional) or disable it for now.
5.  **Create project**.

## 2. Add Apps to Firebase

You'll need to add configurations for each platform your app targets (Android, iOS, Web).

### For Android

1.  In your Firebase project dashboard, click **Add app** and select the **Android** icon.
2.  **Register app**:
    *   **Android package name**: Find this in your `android/app/build.gradle` file (usually `applicationId`). Example: `com.example.waste_segregation_app`.
    *   **App nickname** (optional): E.g., "Waste App Android".
    *   **Debug signing certificate SHA-1** (optional but recommended for auth features like Google Sign-In):
        *   Open a terminal and navigate to your project's `android` directory.
        *   Run the command: `./gradlew signingReport`
        *   Copy the SHA-1 value for the `debugAndroidTest` variant (or your debug variant).
3.  Click **Register app**.
4.  **Download config file**: Download `google-services.json`.
5.  **Move `google-services.json`** into your Flutter project's `android/app/` directory.
6.  **Add Firebase SDK**: Firebase will show you snippets to add to your `build.gradle` files. Most of this should already be handled by FlutterFire, but verify:
    *   Project-level `android/build.gradle`:
        ```gradle
        buildscript {
            dependencies {
                classpath 'com.google.gms:google-services:4.4.2' // Or latest
            }
        }
        plugins {
            id 'com.google.gms.google-services' version '4.4.2' apply false // Or latest
        }
        ```
    *   App-level `android/app/build.gradle`:
        ```gradle
        plugins {
            id 'com.google.gms.google-services'
        }
        dependencies {
            implementation platform('com.google.firebase:firebase-bom:LATEST_VERSION')
            implementation 'com.google.firebase:firebase-analytics'
            // Add other Firebase SDKs as needed (e.g., firebase-auth, firebase-firestore)
        }
        ```
7.  Click **Next**, then **Continue to console**.

### For iOS

1.  In your Firebase project dashboard, click **Add app** and select the **iOS** icon.
2.  **Register app**:
    *   **iOS bundle ID**: Find this in Xcode under `Runner > General > Identity > Bundle Identifier`. Example: `com.example.wasteSegregationApp`.
    *   **App nickname** (optional): E.g., "Waste App iOS".
    *   **App Store ID** (optional): Leave blank for now.
3.  Click **Register app**.
4.  **Download config file**: Download `GoogleService-Info.plist`.
5.  **Move `GoogleService-Info.plist`** into your Flutter project's `ios/Runner/` directory. Ensure it's added to the Runner target in Xcode.
6.  **Add Firebase SDK**: This is typically handled by FlutterFire through Cocoapods. Ensure your `ios/Podfile` includes the necessary Firebase pods (e.g., `Firebase/Core`, `Firebase/Auth`).
7.  Click **Next**, then **Continue to console**.

### For Web

1.  In your Firebase project dashboard, click **Add app** and select the **Web** icon ( `</>` ).
2.  **Register app**:
    *   **App nickname**: E.g., "Waste App Web".
    *   Optionally, set up Firebase Hosting if you plan to deploy your web app through Firebase.
3.  Click **Register app**.
4.  **Add Firebase SDK**: Firebase will provide you with a configuration script.
    ```html
    <script type="module">
      // Import the functions you need from the SDKs you need
      import { initializeApp } from "https://www.gstatic.com/firebasejs/LATEST_VERSION/firebase-app.js";
      // TODO: Add SDKs for Firebase products that you want to use
      // https://firebase.google.com/docs/web/setup#available-libraries

      // Your web app's Firebase configuration
      const firebaseConfig = {
        apiKey: "YOUR_API_KEY",
        authDomain: "YOUR_AUTH_DOMAIN",
        projectId: "YOUR_PROJECT_ID",
        storageBucket: "YOUR_STORAGE_BUCKET",
        messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
        appId: "YOUR_APP_ID"
      };

      // Initialize Firebase
      const app = initializeApp(firebaseConfig);
    </script>
    ```
    You will integrate this configuration into your Flutter web app, typically in `web/index.html` and `lib/firebase_options.dart`.
5.  Click **Continue to console**.

## 3. Configure Firebase Authentication

If your app uses authentication (e.g., Google Sign-In, Email/Password):

1.  In the Firebase Console, go to **Authentication** (under Build).
2.  Click the **Sign-in method** tab.
3.  **Enable the providers** you want to use (e.g., Google, Email/Password, Apple).
    *   For Google Sign-In on Android, ensure your SHA-1 debug certificate is added to the Android app settings in Firebase (Project Settings > Your apps > Android app).

## 4. Configure Firestore Database (if used)

If your app uses Firestore:

1.  In the Firebase Console, go to **Firestore Database** (under Build).
2.  Click **Create database**.
3.  Choose **Start in production mode** or **Start in test mode**.
    *   Production mode: Data is private by default. You must write security rules.
    *   Test mode: Data is open by default for 30 days. Good for initial development.
4.  **Select a location** for your Firestore data. Choose carefully as this cannot be changed later.
5.  Click **Enable**.
6.  **Set up Security Rules**: Go to the **Rules** tab in Firestore and define appropriate rules to protect your data.

## 5. FlutterFire CLI (Recommended)

For easier configuration and to keep your Firebase setup in sync, use the FlutterFire CLI.

1.  **Install the CLI**:
    ```bash
    dart pub global activate flutterfire_cli
    ```
2.  **Log in to Firebase** (if not already):
    ```bash
    firebase login
    ```
3.  **Configure your Flutter app**:
    From the root of your Flutter project, run:
    ```bash
    flutterfire configure
    ```
    This command will guide you through selecting a Firebase project and will automatically generate the `lib/firebase_options.dart` file with configurations for all your registered platforms.

## Next Steps

- **Install Firebase Flutter Plugins**: Add the necessary Firebase plugins to your `pubspec.yaml` file (e.g., `firebase_core`, `firebase_auth`, `cloud_firestore`).
- **Initialize Firebase in your app**: In your `main.dart` file:
  ```dart
  import 'package:firebase_core/firebase_core.dart';
  import 'firebase_options.dart'; // Generated by FlutterFire CLI

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(MyApp());
  }
  ```

Refer to the specific FlutterFire plugin documentation for details on how to use each Firebase service. 