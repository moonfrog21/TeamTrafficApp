# Implementation Plan: GPS Telemetry Flutter App

## Context and Workspace State
**Target Environment:** VS Code with the Flutter extension active.
**Working Directory:** `test_app_1` (The root directory of the Flutter project).
**Current State:** The project currently contains the default Flutter starter code (the counter app) in `lib/main.dart`.
**Objective:** Replace the default app with a GPS telemetry application that posts user location data to an ngrok tunnel, conforming exactly to the accompanying `PRD.md`.
**Execution Strategy:** An AI assistant will execute these steps sequentially, one by one. Do not proceed to the next step until the current one is verified and functional.

---

## Step 1: Inject Package Dependencies
Open `pubspec.yaml` located in the root of the `test_app_1` directory and add the required external libraries under the `dependencies:` block. You will need to insert `http:` for handling the network requests to the ngrok server. You must also add `geolocator:` to interface with the device's native GPS hardware, and `shared_preferences:` to write the target URL to non-volatile device memory. After saving the file, instruct the editor to run `flutter pub get` to download and link these packages to the build environment.

## Step 2: Configure Native OS Permissions
Before the app can request location data at runtime, the native project files must declare the intention to use these hardware features. For Android, navigate to `android/app/src/main/AndroidManifest.xml` and insert the `<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />` and `ACCESS_COARSE_LOCATION` tags above the application block. For iOS, open `ios/Runner/Info.plist` and inject the `NSLocationWhenInUseUsageDescription` key with an appropriate string value explaining why the app needs GPS access. Failing to declare these native strings will cause both operating systems to silently block the runtime permission dialogs, crashing the location service.

## Step 3: Implement the Storage Service
Create a new file named `lib/storage_service.dart` to handle data persistence independently from the UI code. This service must utilize the `shared_preferences` package to expose asynchronous methods for setting and getting the `ngrok_url` string. It is crucial that this service loads the saved URL immediately upon application startup so the networking client is initialized and ready. Isolating this logic ensures that the main application state remains clean and that the user's custom ngrok domain survives a complete application kill or device reboot.

## Step 4: Construct the Location and Networking Logic
Create a file named `lib/telemetry_service.dart` to manage the core data extraction and transmission pipeline. This module must first invoke the `geolocator` permission handler to trigger the standard OS-level permission popup if access has not yet been granted. Once permission is secured, it must extract the current latitude and longitude, retrieve the local system time, and construct the precise JSON dictionary defined in the PRD (using the static user identifier "Noah"). Finally, the module must execute an HTTP POST request to the dynamically loaded ngrok URL appended with `/data`, incorporating robust `try-catch` blocks to handle `SocketException` or server timeouts gracefully.

## Step 5: Build the Settings Interface
Create a new UI component named `lib/settings_screen.dart` to fulfill the configuration requirements outlined in the PRD. This screen must consist of a simple `Scaffold` containing a `TextField` specifically designated for entering the base ngrok domain. The text controller must be initialized with the currently saved URL retrieved from the storage service so the user can see their active configuration. Include a save button that validates the input for basic HTTP/HTTPS formatting, writes the updated string to memory via the storage service, and pops the navigation stack to return the user to the main interface.

## Step 6: Refactor the Main UI and Integrate Services
Overwrite the existing `lib/main.dart` completely to eliminate the default Flutter counter application template. Construct a new `StatelessWidget` or `StatefulWidget` that features an `AppBar` with a settings cog icon (`Icons.settings`) wired to navigate to the `settings_screen.dart`. In the center of the screen, implement a prominently styled `ElevatedButton` labeled "Send GPS data" that triggers the `telemetry_service.dart` pipeline. The UI must await the completion of the network request and immediately display a `SnackBar` at the bottom of the screen reporting the HTTP status code or explicitly alerting the user if the connection failed.
