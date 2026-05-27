# Godot Adjust Plugin

Welcome to the documentation for the **Godot Adjust Plugin**. This addon provides a lightweight and robust GDScript bridge to the native **Adjust SDK v5.6.0** for both iOS and Android.

## Features

- **Install Attribution Tracking:** Track app installs and receive attribution callback data.
- **Event Tracking:** Track standard events and events with monetary revenue.
- **Subscription Tracking:** Track App Store (iOS) and Play Store (Android) subscriptions.
- **GDPR Compliance:** Support for user data deletion via the GDPR `gdpr_forget_me` method.
- **Data Residency Support:** Customize URL strategies and enforce EU data residency requirements.

---

## Installation

1. Go to the [Releases](https://github.com/SomniGameStudios/godot-adjust-plugin/releases) page and download the latest `godot-adjust-plugin-v*.zip` file.
2. Extract the ZIP contents into the root directory of your Godot project. This will automatically copy the pre-compiled native binaries into the `addons/` and `ios/` folders of your project.
3. Open your Godot project, navigate to **Project -> Project Settings -> Plugins**, and check **Enable** next to the **Adjust** plugin.


---

## Quick Start (GDScript)

To start tracking installs and events, instantiate and initialize the `AdjustPlugin` node:

```gdscript
extends Node

var adjust: AdjustPlugin

func _ready() -> void:
    # 1. Instantiate the plugin node
    adjust = AdjustPlugin.new()
    add_child(adjust)
    
    # 2. Connect to signals
    adjust.initialization_completed.connect(_on_adjust_init_completed)
    adjust.attribution_changed.connect(_on_adjust_attribution_changed)
    
    # 3. Initialize with your App Token
    var app_token := "your_app_token"
    var is_sandbox := true # Set to false for Production
    adjust.initialize(app_token, is_sandbox)

func _on_adjust_init_completed() -> void:
    print("Adjust SDK Initialized successfully!")
    
    # Track a custom event
    adjust.track_event("your_event_token")

func _on_adjust_attribution_changed(data: Dictionary) -> void:
    print("User Attribution Changed: ", data)
```
