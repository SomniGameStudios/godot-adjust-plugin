# <img src="platforms/godot_editor/icon.svg" width="36" valign="middle"> Godot Adjust Plugin

A lightweight and high-performance native wrapper for the **Adjust SDK v5.7.0** on Android and iOS, built specifically for Godot Engine.

👉 **[Read the Documentation](https://somnigamestudios.github.io/godot-adjust-plugin/)** | **[Class API Reference](https://somnigamestudios.github.io/godot-adjust-plugin/gdscript_api/)**

---

## Features
- **Install Attribution:** Track campaigns, networks, and custom attributions.
- **Events & Revenue:** Track standard events or events with custom monetary revenue (ISO 4217).
- **Subscriptions:** Natively track iOS App Store and Android Play Store subscription purchases.
- **Privacy Controls:** GDPR compliance (`gdpr_forget_me`) and ATT passthrough for iOS.
- **Data Residency:** Built-in EU data residency and custom URL strategies.

## ⚙️ Installation

1. Go to the [Releases](https://github.com/SomniGameStudios/godot-adjust-plugin/releases) page and download the latest `godot-adjust-plugin-v*.zip` file.
2. Extract the ZIP contents into the root directory of your Godot project. This will automatically copy the pre-compiled binaries into the `addons/` and `ios/` folders of your project.
3. Open your Godot project, navigate to **Project -> Project Settings -> Plugins**, and check **Enable** next to the **Adjust** plugin.

## Architecture
This plugin follows the "Editor Plugin" pattern, allowing easy management and export of native dependencies.

## Building
Use the provided build script:
```bash
./scripts/build_local.sh all 4.6.2
```

## Documentation
Full documentation, including API Reference and Testing Guides, is available at:
👉 **[somnigamestudios.github.io/godot-adjust-plugin](https://somnigamestudios.github.io/godot-adjust-plugin/)**

See `AGENTS.md` for architectural details and coding standards.

## Demo Project Setup

The demo in `platforms/godot_editor` exercises every plugin API (initialize, events, revenue, ad revenue, subscription, ATT, measurement consent, attribution, and GDPR forget-me).

1. Provide your Adjust **sandbox** tokens (gitignored, so they are never committed):

   ```bash
   cd platforms/godot_editor
   cp test_credentials.json.example test_credentials.json
   ```

   Fill in your app token and event token; they load automatically on startup (`is_sandbox` defaults to `true`).

2. `export_presets.cfg` is gitignored, so your real signing values are never committed. Copy the committed template, which already has the plugin enabled — keep `plugins/AdjustGodotPlugin=true` (iOS) and `Use Gradle Build` (Android) so the native plugin is bundled:

   ```bash
   cd platforms/godot_editor
   cp export_presets.cfg.example export_presets.cfg
   ```

   Then set your Apple **Team ID** and **bundle identifier** in Godot before exporting.

Then follow the per-platform steps below to build onto a device.

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
3. Enable **Use Custom Build** in the Android export options. (The Android plugin binary is integrated dynamically during export).
4. Click **Export Project** to generate the APK (e.g., `exports/android/adjust_sample.apk`).

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

