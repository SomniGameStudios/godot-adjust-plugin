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

## Convenience singleton for the Adjust plugin, registered as the `Adjust` autoload.
##
## It optionally auto-initializes the SDK from Project Settings
## (Project > Project Settings > Adjust) and re-exposes the full AdjustPlugin API
## as instance methods, so consuming apps can call e.g. `Adjust.track_event("token")`
## and connect to the `Adjust.initialization_completed` / `Adjust.attribution_changed`
## signals without touching the static API.
##
## Use this autoload OR the static `AdjustPlugin` API for callbacks — not both, as
## the autoload binds the static callbacks to re-emit its own signals.
extends Node

signal initialization_completed
signal attribution_changed(data: Dictionary)

## Values for the `adjust/config/environment` Project Setting.
## AUTO derives the environment from the build type (debug -> sandbox).
enum EnvironmentMode { AUTO, SANDBOX, PRODUCTION }

const _PREFIX := "adjust/config/"


func _ready() -> void:
	AdjustPlugin.initialization_completed = _emit_initialization_completed
	AdjustPlugin.attribution_changed = _emit_attribution_changed
	if bool(_setting("auto_initialize", false)):
		_auto_initialize()


func _auto_initialize() -> void:
	var app_token := str(_setting("app_token", ""))
	if app_token.is_empty():
		push_warning("Adjust: auto_initialize is enabled but 'adjust/config/app_token' is empty; skipping initialization.")
		return
	initialize(app_token, is_sandbox_environment(), int(_setting("att_wait_interval", 30)), str(_setting("fb_app_id", "")))


## Resolves whether the SDK should use the sandbox environment, based on the
## `adjust/config/environment` Project Setting (AUTO uses OS.is_debug_build()).
func is_sandbox_environment() -> bool:
	match int(_setting("environment", EnvironmentMode.AUTO)):
		EnvironmentMode.SANDBOX:
			return true
		EnvironmentMode.PRODUCTION:
			return false
		_:
			return OS.is_debug_build()


# --- Facade: mirrors the static AdjustPlugin API ---

func initialize(app_token: String, is_sandbox: bool, att_wait_interval: int = 30, fb_app_id: String = "") -> void:
	AdjustPlugin.initialize(app_token, is_sandbox, att_wait_interval, fb_app_id)


func track_event(event_token: String) -> void:
	AdjustPlugin.track_event(event_token)


func track_event_with_revenue(event_token: String, amount: float, currency: String) -> void:
	AdjustPlugin.track_event_with_revenue(event_token, amount, currency)


func track_play_store_subscription(price: int, currency: String, sku: String, order_id: String, signature: String, purchase_token: String) -> void:
	AdjustPlugin.track_play_store_subscription(price, currency, sku, order_id, signature, purchase_token)


func track_app_store_subscription(price: String, currency: String, transaction_id: String) -> void:
	AdjustPlugin.track_app_store_subscription(price, currency, transaction_id)


func disable_third_party_sharing() -> void:
	AdjustPlugin.disable_third_party_sharing()


func gdpr_forget_me() -> void:
	AdjustPlugin.gdpr_forget_me()


func set_url_strategy(urls: PackedStringArray, use_subdomains: bool, is_data_residency: bool) -> void:
	AdjustPlugin.set_url_strategy(urls, use_subdomains, is_data_residency)


func request_tracking_authorization() -> void:
	AdjustPlugin.request_tracking_authorization()


func get_attribution() -> Dictionary:
	return AdjustPlugin.get_attribution()


func track_measurement_consent(enabled: bool) -> void:
	AdjustPlugin.track_measurement_consent(enabled)


func track_ad_revenue(source: String, revenue: float, currency: String) -> void:
	AdjustPlugin.track_ad_revenue(source, revenue, currency)


# --- Internal ---

func _emit_initialization_completed() -> void:
	initialization_completed.emit()


func _emit_attribution_changed(data: Dictionary) -> void:
	attribution_changed.emit(data)


func _setting(key: String, default_value: Variant) -> Variant:
	return ProjectSettings.get_setting(_PREFIX + key, default_value)
