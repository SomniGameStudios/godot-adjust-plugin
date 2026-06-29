# MIT License
#
# Copyright (c) 2026-present Somni Game Studios
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

extends Control

# --- CONFIGURATION ---
var app_token := "your_app_token"
var event_token := "your_event_token"
var is_sandbox := true
var fb_app_id := ""

@onready var status_label := $VBoxContainer/StatusLabel
@onready var log_label := $VBoxContainer/ScrollContainer/LogLabel

func _ready() -> void:
	_load_credentials()
	var platform := OS.get_name()
	var found := Engine.has_singleton("AdjustGodotPlugin")
	_log("Sample Ready. Platform: %s. Plugin found: %s" % [platform, str(found)])
	
	AdjustPlugin.initialization_completed = _on_adjust_init_completed
	AdjustPlugin.attribution_changed = _on_adjust_attribution_changed

func _load_credentials() -> void:
	var path := "res://test_credentials.json"
	if not FileAccess.file_exists(path):
		return
	
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	
	var content := file.get_as_text()
	var json_data := JSON.parse_string(content) as Dictionary
	if json_data:
		if json_data.has("app_token"):
			app_token = json_data["app_token"]
		if json_data.has("event_token"):
			event_token = json_data["event_token"]
		if json_data.has("is_sandbox"):
			is_sandbox = json_data["is_sandbox"]
		if json_data.has("fb_app_id"):
			fb_app_id = json_data["fb_app_id"]

func _log(message: String) -> void:
	print("[AdjustSample] ", message)
	if log_label:
		log_label.text += "\n> " + message

func _on_initialize_pressed() -> void:
	_log("Initializing Adjust...")
	AdjustPlugin.initialize(app_token, is_sandbox, 30, fb_app_id)

func _on_track_event_pressed() -> void:
	_log("Tracking event: " + event_token)
	AdjustPlugin.track_event(event_token)

func _on_track_revenue_pressed() -> void:
	_log("Tracking revenue: 0.99 USD")
	AdjustPlugin.track_event_with_revenue(event_token, 0.99, "USD")

func _on_forget_me_pressed() -> void:
	$ConfirmationDialog.popup_centered()

func _on_forget_me_confirmed() -> void:
	_log("Requesting GDPR Forget Me...")
	AdjustPlugin.gdpr_forget_me()

func _on_request_att_pressed() -> void:
	_log("Requesting ATT tracking authorization...")
	AdjustPlugin.request_tracking_authorization()

func _on_get_attribution_pressed() -> void:
	var attr := AdjustPlugin.get_attribution()
	_log("Current Attribution: " + str(attr))

func _on_track_ad_revenue_pressed() -> void:
	_log("Tracking Ad Revenue: 0.45 USD from 'AppLovin'")
	AdjustPlugin.track_ad_revenue("AppLovin", 0.45, "USD")

func _on_track_subscription_pressed() -> void:
	var platform := OS.get_name()
	if platform == "iOS":
		_log("Tracking App Store subscription: 9.99 USD (test transaction)")
		AdjustPlugin.track_app_store_subscription("9.99", "USD", "test_transaction_id")
	elif platform == "Android":
		_log("Tracking Play Store subscription: 9990000 USD (micros, test purchase)")
		AdjustPlugin.track_play_store_subscription(9990000, "USD", "test_sku", "test_order_id", "test_signature", "test_purchase_token")
	else:
		_log("Subscription tracking is only available on mobile platforms")

func _on_consent_true_pressed() -> void:
	_log("Setting Measurement Consent: True")
	AdjustPlugin.track_measurement_consent(true)

func _on_consent_false_pressed() -> void:
	_log("Setting Measurement Consent: False")
	AdjustPlugin.track_measurement_consent(false)

func _on_adjust_init_completed() -> void:
	_log("Callback: Initialization Completed!")
	status_label.text = "Status: Initialized"
	status_label.modulate = Color.GREEN

func _on_adjust_attribution_changed(data: Dictionary) -> void:
	_log("Callback: Attribution Changed! " + str(data))
