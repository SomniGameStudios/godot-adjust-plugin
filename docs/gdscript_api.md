# GDScript API Reference

This page describes the API reference for the `AdjustPlugin` class.

## Signals

### `initialization_completed`
Emitted when the Adjust SDK initialization finishes successfully.
```gdscript
signal initialization_completed
```

### `attribution_changed`
Emitted when Adjust receives new user attribution data (from install campaigns, deep links, etc.).
```gdscript
signal attribution_changed(data: Dictionary)
```
The `data` Dictionary contains:
* `tracker_token` (String)
* `tracker_name` (String)
* `network` (String)
* `campaign` (String)
* `adgroup` (String)
* `creative` (String)
* `click_label` (String)

---

## Methods

### `initialize`
Initializes the Adjust SDK. Call this as early as possible.
```gdscript
func initialize(app_token: String, is_sandbox: bool, att_wait_interval: int = 30) -> void
```
* **`app_token`**: Your Adjust app token from the dashboard.
* **`is_sandbox`**: Set to `true` for testing/sandbox mode. Set to `false` for production builds.
* **`att_wait_interval`**: *(iOS only)* The time (in seconds) the SDK waits for the user to approve App Tracking Transparency (ATT) dialog before sending install data. Default: `30` seconds.

---

### `track_event`
Tracks a custom event by token.
```gdscript
func track_event(event_token: String) -> void
```
* **`event_token`**: The token identifier for the event defined in the Adjust dashboard.

---

### `track_event_with_revenue`
Tracks a custom event with associated monetary revenue.
```gdscript
func track_event_with_revenue(event_token: String, amount: float, currency: String) -> void
```
* **`event_token`**: The token identifier for the event.
* **`amount`**: The value of the revenue event (e.g., `0.99`).
* **`currency`**: The ISO 4217 currency code (e.g., `"USD"`).

---

### `track_play_store_subscription`
*(Android Only)* Tracks subscription purchases via the Google Play Store.
```gdscript
func track_play_store_subscription(
    price: int, 
    currency: String, 
    sku: String, 
    order_id: String, 
    signature: String, 
    purchase_token: String
) -> void
```

---

### `track_app_store_subscription`
*(iOS Only)* Tracks subscription purchases via the Apple App Store.
```gdscript
func track_app_store_subscription(
    price: String, 
    currency: String, 
    transaction_id: String
) -> void
```

---

### `disable_third_party_sharing`
Disables data sharing with third-party partners (e.g., for privacy compliance).
```gdscript
func disable_third_party_sharing() -> void
```

---

### `gdpr_forget_me`
Requests the deletion of the user's historical analytics data from Adjust servers.
!!! warning
    This action is irreversible. Future events and sessions from this user will not be tracked.
```gdscript
func gdpr_forget_me() -> void
```

---

### `set_url_strategy`
Configures a custom URL strategy for data collection (e.g., for EU data residency).
!!! info "Important"
    This must be called **before** calling `initialize()`.
```gdscript
func set_url_strategy(urls: PackedStringArray, use_subdomains: bool, is_data_residency: bool) -> void
```

* **`urls`**: Custom domain endpoints.
* **`use_subdomains`**: Enable subdomain fallback strategies.
* **`is_data_residency`**: Enable strict data residency constraints.
