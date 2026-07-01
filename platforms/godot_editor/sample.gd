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

const COLOR_IDLE := Color(0.4, 0.4, 0.44)
const COLOR_OK := Color(0.18, 0.62, 0.28)
const COLOR_WARN := Color(0.84, 0.5, 0.1)

# --- CONFIGURATION ---
# Values are loaded from res://test_credentials.json when present (gitignored);
# copy test_credentials.json.example to get started. The defaults below keep the
# demo running in-editor without real tokens.
var app_token := "your_app_token"
var event_token := "your_event_token"
var is_sandbox := AdjustPlugin.is_sandbox_environment()
var fb_app_id := ""

@onready var status_label: Label = %StatusLabel
@onready var output: RichTextLabel = %OutputPanel

func _ready() -> void:
	_load_credentials()
	_restore_status()

	var platform := OS.get_name()
	var found := Engine.has_singleton("AdjustGodotPlugin")
	_log("ready", "Platform: %s | Native plugin found: %s" % [platform, str(found)])
	if not found and (platform == "Android" or platform == "iOS"):
		_log("warn", "Adjust native singleton missing — export with the plugin enabled.")

	AdjustPlugin.initialization_completed = _on_adjust_init_completed
	AdjustPlugin.attribution_changed = _on_adjust_attribution_changed

func _load_credentials() -> void:
	var path := "res://test_credentials.json"
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	var json_data := JSON.parse_string(file.get_as_text()) as Dictionary
	if json_data:
		app_token = json_data.get("app_token", app_token)
		event_token = json_data.get("event_token", event_token)
		is_sandbox = json_data.get("is_sandbox", is_sandbox)
		fb_app_id = json_data.get("fb_app_id", fb_app_id)

# --- Setup ---

func _on_initialize_pressed() -> void:
	var env := "sandbox" if is_sandbox else "production"
	_log("init", "Initializing Adjust (%s)..." % env)
	_set_status("Initializing...", COLOR_WARN)
	AdjustPlugin.initialize(app_token, is_sandbox, 30, fb_app_id)

func _on_initialize_from_settings_pressed() -> void:
	# Push the loaded test credentials into Project Settings in-memory (not saved)
	# so initialize() resolves them via its adjust/config/* fallback — this
	# exercises the no-argument, settings-driven path.
	ProjectSettings.set_setting("adjust/config/app_token", app_token)
	ProjectSettings.set_setting("adjust/config/fb_app_id", fb_app_id)
	ProjectSettings.set_setting("adjust/config/environment",
		AdjustPlugin.EnvironmentMode.SANDBOX if is_sandbox else AdjustPlugin.EnvironmentMode.PRODUCTION)
	_log("init", "Initializing Adjust from Project Settings (no-arg)...")
	_set_status("Initializing...", COLOR_WARN)
	AdjustPlugin.initialize()

func _on_request_att_pressed() -> void:
	if OS.get_name() != "iOS":
		_log("att", "ATT is iOS-only — skipped on %s." % OS.get_name())
		return
	_log("att", "Requesting ATT tracking authorization...")
	AdjustPlugin.request_tracking_authorization()

# --- Events & Revenue ---

func _on_track_event_pressed() -> void:
	_log("event", "Tracking event: %s" % event_token)
	AdjustPlugin.track_event(event_token)

func _on_track_revenue_pressed() -> void:
	_log("revenue", "Tracking revenue: 0.99 USD")
	AdjustPlugin.track_event_with_revenue(event_token, 0.99, "USD")

func _on_track_ad_revenue_pressed() -> void:
	_log("ad_revenue", "Tracking ad revenue: 0.45 USD (AppLovin)")
	AdjustPlugin.track_ad_revenue("AppLovin", 0.45, "USD")

# --- Subscription ---

func _on_track_subscription_pressed() -> void:
	var platform := OS.get_name()
	if platform == "iOS":
		_log("subscription", "Tracking App Store subscription: 9.99 USD (test)")
		AdjustPlugin.track_app_store_subscription("9.99", "USD", "test_transaction_id")
	elif platform == "Android":
		_log("subscription", "Tracking Play Store subscription: 9990000 micros (test)")
		AdjustPlugin.track_play_store_subscription(
			9990000, "USD", "test_sku", "test_order_id",
			"test_signature", "test_purchase_token"
		)
	else:
		_log("subscription", "Subscription tracking is only available on mobile platforms.")

# --- Attribution ---

func _on_get_attribution_pressed() -> void:
	_log("attribution", "Current attribution: %s" % str(AdjustPlugin.get_attribution()))

# --- Privacy & Consent ---

func _on_consent_true_pressed() -> void:
	_log("consent", "Measurement consent: TRUE")
	AdjustPlugin.track_measurement_consent(true)

func _on_consent_false_pressed() -> void:
	_log("consent", "Measurement consent: FALSE")
	AdjustPlugin.track_measurement_consent(false)

func _on_forget_me_pressed() -> void:
	$ConfirmationDialog.popup_centered()

func _on_forget_me_confirmed() -> void:
	_log("gdpr", "Requesting GDPR Forget Me (irreversible)...")
	AdjustPlugin.gdpr_forget_me()

# --- Callbacks ---

func _on_adjust_init_completed() -> void:
	AdjustDemoState.initialized = true
	AdjustDemoState.sandbox = is_sandbox
	_log("init", "Initialization completed.")
	_set_status("Initialized (%s)" % ("sandbox" if is_sandbox else "production"), COLOR_OK)

func _on_adjust_attribution_changed(data: Dictionary) -> void:
	_log("attribution", "Attribution changed: %s" % str(data))

# --- UI helpers ---

func _on_back_pressed() -> void:
	get_tree().change_scene_to_packed(load("res://main.tscn"))

func _on_clear_log_pressed() -> void:
	output.text = ""

func _restore_status() -> void:
	if AdjustDemoState.initialized:
		_set_status("Initialized (%s)" % ("sandbox" if AdjustDemoState.sandbox else "production"), COLOR_OK)
	else:
		var env := "sandbox" if AdjustPlugin.is_sandbox_environment() else "production"
		_set_status("Not initialized · %s" % env, COLOR_IDLE)

func _set_status(text: String, color: Color) -> void:
	status_label.text = "● %s" % text
	status_label.add_theme_color_override("font_color", color)

func _log(context: String, message: String) -> void:
	var t := Time.get_time_string_from_system()
	print("[AdjustSample] %s: %s" % [context, message])
	output.text += "[%s] %s: %s\n" % [t, context, message]
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if is_inside_tree():
		output.scroll_to_line(output.get_line_count())
