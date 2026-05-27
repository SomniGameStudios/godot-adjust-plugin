# Godot Adjust Plugin

Godot Adjust Plugin for Android and iOS. This plugin provides a bridge to the Adjust SDK v5.6.0.

## Features
- Install attribution tracking.
- Revenue event tracking.
- GDPR compliance (`gdpr_forget_me`).
- ATT passthrough for iOS.
- EU data residency support.

## Architecture
This plugin follows the "Editor Plugin" pattern, allowing easy management and export of native dependencies.

## Building
Use the provided build script:
```bash
./scripts/build_local.sh all 4.6.2
```

## Documentation
See `AGENTS.md` for architectural details and coding standards.

## Testing on iOS Simulator

### 1. Compile the Plugin for Simulator
Run the build script to compile the plugin with simulator support:
```bash
./scripts/build_local.sh ios 4.6.2
```

### 2. Export from Godot
1. Open the project in `platforms/godot_editor` with Godot 4.6.2.
2. Go to **Project -> Export -> iOS**.
3. Enable **AdjustGodotPlugin** in the **Plugins** section.
4. Export the project to a folder (e.g., `exports/ios/adjust_sample`).

### 3. Run in Xcode Simulator
1. Open the exported project:
   ```bash
   open exports/ios/adjust_sample/AdjustSample.xcodeproj
   ```
2. Wait for Xcode to resolve Swift Package Manager (SPM) dependencies (downloads the native `AdjustSdk` automatically).
3. Select an iOS Simulator destination (e.g., *iPhone 16 Simulator*).
4. Build and Run (`Cmd + R`).

### 4. Verify on the Adjust Dashboard
1. Look at the Xcode console log for `[Adjust]` tags to find your **ADID** or **IDFV**:
   * Example: `[Adjust] Info: adid: your_adjust_device_id`
   * Example: `[Adjust] Info: IDFV: your_ios_idfv`
2. Open the [Adjust Testing Console](https://suite.adjust.com/).
3. Search for the **ADID** or **IDFV** to see real-time tracked events (e.g., `your_event_token`).
4. To test a fresh install, click **Forget Device** in the Testing Console, delete the app from the simulator, and run again.

## Testing on Android (Device or Emulator)

### 1. Compile the Plugin for Android
Run the build script to compile the Android plugin AAR files:
```bash
./scripts/build_local.sh android 4.6.2
```

### 2. Export from Godot
1. Open the project in `platforms/godot_editor` with Godot 4.6.2.
2. Go to **Project -> Export -> Android**.
3. Enable **Use Custom Build** in the Android export options.
4. Enable the **Adjust** plugin in the **Plugins** section.
5. Click **Export Project** to generate the APK (e.g., `exports/android/adjust_sample.apk`).

### 3. Run and Monitor Logs
1. Install and run the APK on your Android device or emulator:
   ```bash
   adb install exports/android/adjust_sample.apk
   ```
2. Monitor logcat output filtering for `Adjust` to find your test device identifier (e.g., Google Play Services ADID or Adjust Device ID):
   ```bash
   adb logcat -s Adjust
   ```
   * Look for logs like:
     * `[Adjust] Info: gps_adid: your_google_play_services_advertising_id`
     * `[Adjust] Info: adid: your_adjust_device_id`

### 4. Verify on the Adjust Dashboard
1. Open the [Adjust Testing Console](https://suite.adjust.com/).
2. Search for the retrieved **gps_adid** or **adid**.
3. Trigger events in the app and verify they show up in real-time.
4. To test a fresh install, click **Forget Device** in the Testing Console, uninstall the app from the device, and run again.


