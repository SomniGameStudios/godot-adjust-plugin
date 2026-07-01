# Godot Adjust Plugin

Welcome to the documentation for the **Godot Adjust Plugin**. This addon provides a lightweight and robust GDScript bridge to the native **Adjust SDK v5.7.0** for both iOS and Android.

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

## Quick Start

### Option A: Auto-initialize from Project Settings

Set your token in *Project > Project Settings > Adjust* and enable `auto_initialize`:

| Setting | Meaning |
| --- | --- |
| `adjust/config/app_token` | Your Adjust app token. |
| `adjust/config/fb_app_id` | Optional Meta App ID (Android Meta Install Referrer). |
| `adjust/config/att_wait_interval` | *(iOS only)* ATT consent wait, `0`–`360` seconds. |
| `adjust/config/environment` | `Auto` (debug build → sandbox), `Sandbox`, or `Production`. |
| `adjust/config/auto_initialize` | Initialize the SDK on boot from these settings. |

Then use `AdjustPlugin` anywhere:

```gdscript
func _ready() -> void:
    AdjustPlugin.initialization_completed = _on_adjust_init_completed
    AdjustPlugin.attribution_changed = _on_adjust_attribution_changed

func _on_adjust_init_completed() -> void:
    AdjustPlugin.track_event("your_event_token")
```

### Option B: Manual initialization

```gdscript
extends Node

func _ready() -> void:
    AdjustPlugin.initialization_completed = _on_adjust_init_completed
    AdjustPlugin.attribution_changed = _on_adjust_attribution_changed
    
    var app_token := "your_app_token"
    var is_sandbox := AdjustPlugin.is_sandbox_environment()
    AdjustPlugin.initialize(app_token, is_sandbox)

func _on_adjust_init_completed() -> void:
    AdjustPlugin.track_event("your_event_token")

func _on_adjust_attribution_changed(data: Dictionary) -> void:
    print("Attribution: ", data)
```
