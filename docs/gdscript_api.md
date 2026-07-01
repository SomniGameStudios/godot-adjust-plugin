# GDScript API Reference

This page describes the API reference for the `AdjustPlugin` class.

## Callbacks

### `initialization_completed`
Called when the Adjust SDK initialization finishes successfully.
```gdscript
static var initialization_completed: Callable
```

### `attribution_changed`
Called when Adjust receives new user attribution data (from install campaigns, deep links, etc.).
```gdscript
static var attribution_changed: Callable
```
The `data` Dictionary passed to the callback contains:
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
Initializes the Adjust SDK. Call this as early as possible. Any omitted argument falls back to the matching `adjust/config/*` Project Setting, so a project configured in the editor can just call `initialize()` with no arguments. Assign `initialization_completed` / `attribution_changed` **before** calling this.
```gdscript
static func initialize(app_token := "", is_sandbox := is_sandbox_environment(), att_wait_interval := -1, fb_app_id := "") -> void
```
* **`app_token`**: Your Adjust app token from the dashboard. Falls back to `adjust/config/app_token`; if both are empty the SDK is not initialized.
* **`is_sandbox`**: `true` for testing/sandbox, `false` for production. Defaults to `is_sandbox_environment()` (resolved from `adjust/config/environment`).
* **`att_wait_interval`**: *(iOS only)* The time (in seconds, `0`–`360`) the SDK waits for the user to respond to the App Tracking Transparency (ATT) dialog before sending install data, improving IDFA attribution. Maps to iOS `ADJConfig.attConsentWaitingInterval`. Ignored on Android (no ATT). A negative value falls back to `adjust/config/att_wait_interval` (default `30`).
* **`fb_app_id`**: *(optional)* The Facebook App ID. Provide it to enable the Meta partner integration (Meta Install Referrer on Android). Falls back to `adjust/config/fb_app_id`; leave empty to disable.

---

### `is_sandbox_environment`
Resolves whether the SDK should use the sandbox environment, based on the `adjust/config/environment` Project Setting. `AUTO` uses `OS.is_debug_build()`.
```gdscript
static func is_sandbox_environment() -> bool
```

---

### `track_event`
Tracks a custom event by token, with optional revenue, deduplication, and callback/partner parameters.
```gdscript
static func track_event(event_token: String, options := {}) -> void
```
* **`event_token`**: The token identifier for the event defined in the Adjust dashboard.
* **`options`** *(optional Dictionary)*, any of:
    * `revenue` (float) + `currency` (String, ISO 4217) — records revenue on the event.
    * `deduplication_id` (String) — suppresses duplicate event processing (e.g. purchase transaction id).
    * `callback_id` (String) — custom event identifier surfaced in callbacks/reporting.
    * `callback_params` (Dictionary) — key/value pairs appended to your raw-data callback URLs.
    * `partner_params` (Dictionary) — key/value pairs forwarded to integrated ad-network partners.

```gdscript
AdjustPlugin.track_event("abc123", {
    "revenue": 0.99, "currency": "USD",
    "partner_params": {"product_id": "coin_pack_1"},
})
```

---

### `track_event_with_revenue`
Convenience over `track_event()` for the common revenue case.
```gdscript
static func track_event_with_revenue(event_token: String, amount: float, currency: String) -> void
```
* **`event_token`**: The token identifier for the event.
* **`amount`**: The value of the revenue event (e.g., `0.99`).
* **`currency`**: The ISO 4217 currency code (e.g., `"USD"`).

---

### `track_play_store_subscription`
*(Android Only)* Tracks subscription purchases via the Google Play Store.
```gdscript
static func track_play_store_subscription(
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
static func track_app_store_subscription(
    price: String, 
    currency: String, 
    transaction_id: String
) -> void
```

---

### `track_third_party_sharing`
Records the user's third-party data-sharing preference, with optional per-partner granular options (e.g. Google DMA / Meta consent in the EEA).
```gdscript
static func track_third_party_sharing(enabled: bool, granular_options := {}) -> void
```
* **`enabled`**: `true` to allow third-party sharing, `false` to disable.
* **`granular_options`** *(optional Dictionary)*: maps a partner name to a Dictionary of key/value options, e.g. `{"google_dma": {"eea": "1", "ad_personalization": "1"}}`.

---

### `disable_third_party_sharing`
Convenience for `track_third_party_sharing(false)`.
```gdscript
static func disable_third_party_sharing() -> void
```

---

### `gdpr_forget_me`
Requests the deletion of the user's historical analytics data from Adjust servers.
!!! warning
    This action is irreversible. Future events and sessions from this user will not be tracked.
```gdscript
static func gdpr_forget_me() -> void
```

---

### `set_url_strategy`
Configures a custom URL strategy for data collection (e.g., for EU data residency).
!!! info "Important"
    This must be called **before** calling `initialize()`.
```gdscript
static func set_url_strategy(urls: PackedStringArray, use_subdomains: bool, is_data_residency: bool) -> void
```

* **`urls`**: Custom domain endpoints.
* **`use_subdomains`**: Enable subdomain fallback strategies.
* **`is_data_residency`**: Enable strict data residency constraints.

---

### `request_tracking_authorization`
*(iOS Only)* Prompts the user with the App Tracking Transparency (ATT) dialog.
```gdscript
static func request_tracking_authorization() -> void
```

---

### `get_attribution`
Returns the most recent attribution the SDK has resolved, as a snapshot. The SDK
resolves attribution asynchronously, so this may be empty until attribution is
available (typically shortly after `initialization_completed`); assign
`attribution_changed` to be notified when it updates.
```gdscript
static func get_attribution() -> Dictionary
```
Returns a Dictionary with keys like `tracker_token`, `tracker_name`, `network`, `campaign`, `adgroup`, `creative`, and `click_label`, or an empty Dictionary if attribution is not yet available.

---

### `track_measurement_consent`
Tracks the GDPR measurement consent status.
```gdscript
static func track_measurement_consent(enabled: bool) -> void
```
* **`enabled`**: `true` to opt-in to measurement tracking; `false` to opt-out.

---

### `track_ad_revenue`
Tracks impression-level ad revenue (e.g. from AdMob, AppLovin).
```gdscript
static func track_ad_revenue(source: String, revenue: float, currency: String) -> void
```
* **`source`**: The source of the ad revenue (e.g. `"admob_sdk"`).
* **`revenue`**: The ad revenue amount.
* **`currency`**: The ISO 4217 currency code (e.g. `"USD"`).

