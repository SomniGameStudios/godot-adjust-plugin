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

static var attribution_changed: Callable
static var initialization_completed: Callable

## Values for the `adjust/config/environment` Project Setting.
## AUTO derives the environment from the build type (debug -> sandbox).
enum EnvironmentMode { AUTO, SANDBOX, PRODUCTION }

const _PREFIX := "adjust/config/"

static func _static_init() -> void:
	if _plugin:
		MobileSingletonPlugin.safe_connect(_plugin, "attribution_changed", _on_attribution_changed)
		MobileSingletonPlugin.safe_connect(_plugin, "initialization_completed", _on_initialization_completed)
	if bool(_setting("auto_initialize", false)):
		_auto_initialize()

static func initialize(app_token: String, is_sandbox: bool, att_wait_interval: int = 30, fb_app_id: String = "") -> void:
	if not _plugin:
		var platform := OS.get_name()
		if platform == "Android" or platform == "iOS":
			push_error("AdjustPlugin: native plugin unavailable on %s; Adjust will not track. Check the plugin is enabled in the export." % platform)
		return
	_plugin.initialize(app_token, is_sandbox, att_wait_interval, fb_app_id)

static func track_event(event_token: String) -> void:
	if _plugin:
		_plugin.track_event(event_token)

static func track_event_with_revenue(event_token: String, amount: float, currency: String) -> void:
	if _plugin:
		_plugin.track_event_with_revenue(event_token, amount, currency)

static func track_play_store_subscription(price: int, currency: String, sku: String, order_id: String, signature: String, purchase_token: String) -> void:
	if _plugin and _plugin.has_method("track_play_store_subscription"):
		_plugin.track_play_store_subscription(price, currency, sku, order_id, signature, purchase_token)

static func track_app_store_subscription(price: String, currency: String, transaction_id: String) -> void:
	if _plugin and _plugin.has_method("track_app_store_subscription"):
		_plugin.track_app_store_subscription(price, currency, transaction_id)

static func disable_third_party_sharing() -> void:
	if _plugin:
		_plugin.disable_third_party_sharing()

static func gdpr_forget_me() -> void:
	if _plugin:
		_plugin.gdpr_forget_me()

static func set_url_strategy(urls: PackedStringArray, use_subdomains: bool, is_data_residency: bool) -> void:
	if _plugin:
		_plugin.set_url_strategy(urls, use_subdomains, is_data_residency)

static func request_tracking_authorization() -> void:
	if _plugin and _plugin.has_method("request_tracking_authorization"):
		_plugin.request_tracking_authorization()

static func get_attribution() -> Dictionary:
	if _plugin and _plugin.has_method("get_attribution"):
		var attribution: Dictionary = _plugin.get_attribution()
		return attribution
	return {}

static func track_measurement_consent(enabled: bool) -> void:
	if _plugin and _plugin.has_method("track_measurement_consent"):
		_plugin.track_measurement_consent(enabled)

static func track_ad_revenue(source: String, revenue: float, currency: String) -> void:
	if _plugin and _plugin.has_method("track_ad_revenue"):
		_plugin.track_ad_revenue(source, revenue, currency)

static func _on_attribution_changed(data: Dictionary) -> void:
	if attribution_changed.is_valid():
		attribution_changed.call(data)

static func _on_initialization_completed() -> void:
	if initialization_completed.is_valid():
		initialization_completed.call()


static func _auto_initialize() -> void:
	var app_token := str(_setting("app_token", ""))
	if app_token.is_empty():
		push_warning("Adjust: auto_initialize is enabled but 'adjust/config/app_token' is empty; skipping initialization.")
		return
	initialize(app_token, is_sandbox_environment(), int(_setting("att_wait_interval", 30)), str(_setting("fb_app_id", "")))


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
