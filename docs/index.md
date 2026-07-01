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

Configure the SDK in *Project > Project Settings > Adjust*. `app_token` is
required; the rest have sensible defaults:

| Setting | Meaning |
| --- | --- |
| `adjust/config/app_token` | Your Adjust app token. **Required.** |
| `adjust/config/fb_app_id` | Optional Meta App ID (Android Meta Install Referrer). |
| `adjust/config/att_wait_interval` | *(iOS only)* ATT consent wait, `0`–`360` seconds. |
| `adjust/config/environment` | `Auto` (debug build → sandbox), `Sandbox`, or `Production`. |

Assign your callbacks and call `initialize()` as early as possible — an autoload's
`_ready()` is a good place. Called with no arguments, `initialize()` reads the
settings above; pass arguments to override any of them.

**Assign `initialization_completed` and `attribution_changed` before calling
`initialize()`.** The plugin registers them with the SDK during that call, and
`initialization_completed` fires synchronously from within `initialize()`, so a
callback assigned afterward is missed.

```gdscript
extends Node

func _ready() -> void:
    AdjustPlugin.initialization_completed = _on_adjust_init_completed
    AdjustPlugin.attribution_changed = _on_adjust_attribution_changed

    AdjustPlugin.initialize()  # reads Project Settings; or override: initialize("your_app_token", true)

func _on_adjust_init_completed() -> void:
    AdjustPlugin.track_event("your_event_token")

func _on_adjust_attribution_changed(data: Dictionary) -> void:
    print("Attribution: ", data)
```

If you need to run anything **before** init — a consent prompt, or pre-init
configuration such as `AdjustPlugin.set_url_strategy(...)` for EU data residency
(which must be called *before* `initialize`) — do it ahead of the `initialize()`
call above.

This addon wraps the native Adjust SDK; see the [Adjust SDK documentation](https://dev.adjust.com/en/sdk) for SDK-level behavior and platform setup.
