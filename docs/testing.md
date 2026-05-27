# Integration and Testing Guide

To verify that your Adjust integration is working correctly before release, use the **Adjust Testing Console** to view real-time installs and events.

---

## Testing on iOS Simulator

### 1. Compile the Plugin for Simulator
Run the build script to compile the Adjust plugin with simulator support:
```bash
./scripts/build_local.sh ios 4.6.2
```

### 2. Export from Godot
1. Open the project in `platforms/godot_editor` with Godot 4.6.2.
2. Go to **Project -> Export -> iOS**.
3. Under the **Plugins** section, check/enable **AdjustGodotPlugin**.
4. Click **Export Project** and choose a target folder (e.g. `exports/ios/adjust_sample`).

### 3. Run in Xcode Simulator
1. Open the exported project:
   ```bash
   open exports/ios/adjust_sample/AdjustSample.xcodeproj
   ```
2. Wait for Xcode to resolve Swift Package Manager (SPM) dependencies (downloads the native `AdjustSdk` automatically).
3. Select an iOS Simulator destination (e.g., *iPhone 16 Simulator*).
4. Build and Run (`Cmd + R`).

### 4. Locate Your Device Identifier
On iOS Simulators, IDFA (Advertising Identifier) is zeroed out by default. Use the **IDFV** (Identifier for Vendor) or the **ADID** (Adjust Device ID):

1. Monitor the Xcode console log for `[Adjust]` logs (ensure you initialized with `is_sandbox = true` to get verbose logs).
2. Look for lines like:
   * `[Adjust] Info: IDFV: your_ios_idfv`
   * `[Adjust] Info: adid: your_adjust_device_id`
3. Copy either of these values.


---

## Testing on Android (Device or Emulator)

### 1. Compile the Plugin for Android
Run the build script to compile the Android plugin AAR files:
```bash
./scripts/build_local.sh android 4.6.2
```

### 2. Export from Godot
1. Open the project in `platforms/godot_editor` with Godot 4.6.2.
2. Go to **Project -> Export -> Android**.
3. Under the Android export options, check **Use Custom Build**.
4. Click **Export Project** to generate the APK (e.g., `exports/android/adjust_sample.apk`).

### 3. Run and Monitor Logs
1. Install and run the APK on your Android device or emulator:
   ```bash
   adb install exports/android/adjust_sample.apk
   ```
2. Monitor logcat output filtering for `Adjust` to retrieve your Google Play Services ADID (`gps_adid`) or Adjust Device ID (`adid`):
   ```bash
   adb logcat -s Adjust
   ```
   * Look for logs like:
     * `[Adjust] Info: gps_adid: your_google_play_services_advertising_id`
     * `[Adjust] Info: adid: your_adjust_device_id`

---

## Verifying in the Adjust Console

1. Log in to the [Adjust Suite Dashboard](https://suite.adjust.com/).
2. Navigate to **AppView** -> **Testing Console**.
3. Search for the retrieved identifier (**adid**, **IDFV**, or **gps_adid**).
4. If your device communicated with Adjust successfully, it will display in the console showing the tracked install.
5. Trigger events in your app (like tracking events or revenue) and verify that they appear in real-time.

---

## Resetting State (For fresh install tests)

To test the install attribution flow again as a new user:

1. Click **Forget Device** in the Adjust Testing Console.
2. Uninstall the app from your test device/simulator.
3. Re-run the app from Xcode/Android Studio. It will register as a brand-new install.

