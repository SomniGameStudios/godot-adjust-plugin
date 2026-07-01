# MIT License

# Copyright (c) 2026-present Somni Game Studios

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

class_name AdjustPlugin
extends RefCounted

const MobileSingletonPlugin := preload("res://addons/adjust/gdscript/src/core/MobileSingletonPlugin.gd")

static var _plugin := MobileSingletonPlugin._get_plugin("AdjustGodotPlugin")

# Assign these before calling initialize(); the native plugin emits
# initialization_completed synchronously from within initialize().
static var attribution_changed: Callable
static var initialization_completed: Callable

# Async getters resolve via these signals: assign the callback, then call the
# matching request_*() method. The native SDK getters are all callback-based.
static var adid_received: Callable
static var google_ad_id_received: Callable
static var idfa_received: Callable
static var sdk_version_received: Callable
static var is_enabled_received: Callable

static var _connected := false

## Values for the `adjust/config/environment` Project Setting.
## AUTO derives the environment from the build type (debug -> sandbox).
enum EnvironmentMode { AUTO, SANDBOX, PRODUCTION }

const _PREFIX := "adjust/config/"

## Omitted arguments fall back to the `adjust/config/*` Project Settings, so a
## project can be configured entirely in the editor and just call initialize().
static func initialize(app_token := "", is_sandbox := is_sandbox_environment(), att_wait_interval := -1, fb_app_id := "") -> void:
	if not _plugin:
		var platform := OS.get_name()
		if platform == "Android" or platform == "iOS":
			push_error("AdjustPlugin: native plugin unavailable on %s; Adjust will not track. Check the plugin is enabled in the export." % platform)
		return
	if app_token.is_empty():
		app_token = str(_setting("app_token", ""))
	if app_token.is_empty():
		push_error("AdjustPlugin: no app token provided and 'adjust/config/app_token' is unset; SDK not initialized.")
		return
	if att_wait_interval < 0:
		att_wait_interval = int(_setting("att_wait_interval", 30))
	if fb_app_id.is_empty():
		fb_app_id = str(_setting("fb_app_id", ""))
	_connect_signals()
	_plugin.initialize(app_token, is_sandbox, att_wait_interval, fb_app_id)

static func _connect_signals() -> void:
	if _connected:
		return
	_connected = true
	MobileSingletonPlugin.safe_connect(_plugin, "attribution_changed", _on_attribution_changed)
	MobileSingletonPlugin.safe_connect(_plugin, "initialization_completed", _on_initialization_completed)
	MobileSingletonPlugin.safe_connect(_plugin, "adid_received", _on_adid_received)
	MobileSingletonPlugin.safe_connect(_plugin, "google_ad_id_received", _on_google_ad_id_received)
	MobileSingletonPlugin.safe_connect(_plugin, "idfa_received", _on_idfa_received)
	MobileSingletonPlugin.safe_connect(_plugin, "sdk_version_received", _on_sdk_version_received)
	MobileSingletonPlugin.safe_connect(_plugin, "is_enabled_received", _on_is_enabled_received)

## Capability probe that works on both platforms. On Android the native
## singleton is a JNISingleton whose `@UsedByGodot` methods live in a private
## map (not ClassDB), so `Object.has_method()` is always false for them — the
## engine exposes `has_java_method()` for that case. iOS is a real GDCLASS, so
## `has_method()` is authoritative there.
static func _plugin_has(method: String) -> bool:
	if not _plugin:
		return false
	if _plugin.has_method(method):
		return true
	return _plugin.has_method("has_java_method") and _plugin.has_java_method(method)

## Tracks a custom event. `options` may carry: `revenue` (float) + `currency`
## (String), `deduplication_id` (String), `callback_id` (String),
## `callback_params` (Dictionary), `partner_params` (Dictionary).
static func track_event(event_token: String, options := {}) -> void:
	if _plugin:
		_plugin.track_event(event_token, options)

## Convenience over track_event() for the common revenue case.
static func track_event_with_revenue(event_token: String, amount: float, currency: String) -> void:
	track_event(event_token, {"revenue": amount, "currency": currency})

static func track_play_store_subscription(price: int, currency: String, sku: String, order_id: String, signature: String, purchase_token: String) -> void:
	if _plugin_has("track_play_store_subscription"):
		_plugin.track_play_store_subscription(price, currency, sku, order_id, signature, purchase_token)

static func track_app_store_subscription(price: String, currency: String, transaction_id: String) -> void:
	if _plugin_has("track_app_store_subscription"):
		_plugin.track_app_store_subscription(price, currency, transaction_id)

## Records third-party data-sharing preference. `granular_options` maps a
## partner name to a Dictionary of key/value options, e.g.
## {"google_dma": {"eea": "1", "ad_personalization": "1"}} for Google DMA / Meta.
static func track_third_party_sharing(enabled: bool, granular_options := {}) -> void:
	if _plugin_has("track_third_party_sharing"):
		_plugin.track_third_party_sharing(enabled, granular_options)

## Convenience: disables third-party sharing with no granular options.
static func disable_third_party_sharing() -> void:
	track_third_party_sharing(false, {})

static func gdpr_forget_me() -> void:
	if _plugin:
		_plugin.gdpr_forget_me()

static func set_url_strategy(urls: PackedStringArray, use_subdomains: bool, is_data_residency: bool) -> void:
	if _plugin:
		_plugin.set_url_strategy(urls, use_subdomains, is_data_residency)

static func request_tracking_authorization() -> void:
	if _plugin_has("request_tracking_authorization"):
		_plugin.request_tracking_authorization()

static func get_attribution() -> Dictionary:
	if _plugin_has("get_attribution"):
		var attribution: Dictionary = _plugin.get_attribution()
		return attribution
	return {}

static func track_measurement_consent(enabled: bool) -> void:
	if _plugin_has("track_measurement_consent"):
		_plugin.track_measurement_consent(enabled)

static func track_ad_revenue(source: String, revenue: float, currency: String) -> void:
	if _plugin_has("track_ad_revenue"):
		_plugin.track_ad_revenue(source, revenue, currency)

## Puts the SDK into offline mode (events are queued, not sent) or back online.
static func set_offline_mode(offline: bool) -> void:
	if _plugin_has("set_offline_mode"):
		_plugin.set_offline_mode(offline)

## Re-enables the SDK after disable(). Tracking resumes.
static func enable() -> void:
	if _plugin_has("enable_sdk"):
		_plugin.enable_sdk()

## Disables the SDK. No events track until enable() is called.
static func disable() -> void:
	if _plugin_has("disable_sdk"):
		_plugin.disable_sdk()

## Requests the Adjust device id; resolves via the adid_received callback.
static func request_adid() -> void:
	if _plugin_has("request_adid"):
		_plugin.request_adid()

## (Android only) Requests the Google Advertising ID; resolves via google_ad_id_received.
static func request_google_ad_id() -> void:
	if _plugin_has("request_google_ad_id"):
		_plugin.request_google_ad_id()

## (iOS only) Requests the IDFA; resolves via idfa_received.
static func request_idfa() -> void:
	if _plugin_has("request_idfa"):
		_plugin.request_idfa()

## Requests the native Adjust SDK version; resolves via sdk_version_received.
static func request_sdk_version() -> void:
	if _plugin_has("request_sdk_version"):
		_plugin.request_sdk_version()

## Requests whether the SDK is currently enabled; resolves via is_enabled_received.
static func request_is_enabled() -> void:
	if _plugin_has("request_is_enabled"):
		_plugin.request_is_enabled()

static func _on_attribution_changed(data: Dictionary) -> void:
	if attribution_changed.is_valid():
		attribution_changed.call(data)

static func _on_initialization_completed() -> void:
	if initialization_completed.is_valid():
		initialization_completed.call()

static func _on_adid_received(adid: String) -> void:
	if adid_received.is_valid():
		adid_received.call(adid)

static func _on_google_ad_id_received(google_ad_id: String) -> void:
	if google_ad_id_received.is_valid():
		google_ad_id_received.call(google_ad_id)

static func _on_idfa_received(idfa: String) -> void:
	if idfa_received.is_valid():
		idfa_received.call(idfa)

static func _on_sdk_version_received(sdk_version: String) -> void:
	if sdk_version_received.is_valid():
		sdk_version_received.call(sdk_version)

static func _on_is_enabled_received(enabled: bool) -> void:
	if is_enabled_received.is_valid():
		is_enabled_received.call(enabled)


## Resolves whether the SDK should use the sandbox environment, based on the
## `adjust/config/environment` Project Setting (AUTO uses OS.is_debug_build()).
static func is_sandbox_environment() -> bool:
	match int(_setting("environment", EnvironmentMode.AUTO)):
		EnvironmentMode.SANDBOX:
			return true
		EnvironmentMode.PRODUCTION:
			return false
		_:
			return OS.is_debug_build()


static func _setting(key: String, default_value: Variant) -> Variant:
	return ProjectSettings.get_setting(_PREFIX + key, default_value)
