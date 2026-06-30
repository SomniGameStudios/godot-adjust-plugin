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

## Quick Start (recommended): Project Settings + autoload

When the plugin is enabled it registers an **`Adjust`** autoload and a set of
**Project Settings** under *Project > Project Settings > Adjust*:

| Setting | Meaning |
| --- | --- |
| `adjust/config/app_token` | Your Adjust app token. |
| `adjust/config/fb_app_id` | Optional Meta App ID (Android Meta Install Referrer). |
| `adjust/config/att_wait_interval` | *(iOS only)* ATT consent wait, `0`–`360` seconds. |
| `adjust/config/environment` | `Auto` (debug build → sandbox), `Sandbox`, or `Production`. |
| `adjust/config/auto_initialize` | Initialize the SDK on boot from these settings. |

Set your token, enable `auto_initialize`, and the SDK starts itself — no init
code required. Then use the `Adjust` singleton anywhere:

```gdscript
func _ready() -> void:
    Adjust.initialization_completed.connect(_on_adjust_init_completed)
    Adjust.attribution_changed.connect(_on_adjust_attribution_changed)

func _on_adjust_init_completed() -> void:
    Adjust.track_event("your_event_token")
```

Leave `auto_initialize` **off** if you need to run anything before init — a
consent prompt, or pre-init configuration such as `Adjust.set_url_strategy(...)`
for EU data residency, which must be called *before* `initialize`. In that case
call `Adjust.initialize(...)` yourself once the pre-init step is done.

## Quick Start (manual): static API

Alternatively, skip the autoload and drive the static `AdjustPlugin` class
directly. Use this **or** the autoload for callbacks, not both.

```gdscript
extends Node

func _ready() -> void:
    # 1. Connect to static callbacks
    AdjustPlugin.initialization_completed = _on_adjust_init_completed
    AdjustPlugin.attribution_changed = _on_adjust_attribution_changed
    
    # 2. Initialize with your App Token
    var app_token := "your_app_token"
    # Debug/editor builds -> sandbox; exported release builds -> production.
    var is_sandbox := OS.is_debug_build()
    AdjustPlugin.initialize(app_token, is_sandbox)

func _on_adjust_init_completed() -> void:
    print("Adjust SDK Initialized successfully!")
    
    # Track a custom event
    AdjustPlugin.track_event("your_event_token")

func _on_adjust_attribution_changed(data: Dictionary) -> void:
    print("User Attribution Changed: ", data)
```
