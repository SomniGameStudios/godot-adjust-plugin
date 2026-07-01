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

# Values are loaded from res://test_credentials.json when present (gitignored).
var app_token := "your_app_token"
var event_token := "your_event_token"
var is_sandbox := AdjustPlugin.is_sandbox_environment()
var fb_app_id := ""

@onready var status_label: Label = %StatusLabel
@onready var output: RichTextLabel = %OutputPanel

var _init_completed := false
var _running := false

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

# --- E2E paths ---
# Run one path per app launch — Adjust is a singleton, so a second initialize()
# in the same run is a no-op. ATT (manual system prompt) and GDPR forget-me
# (irreversible) are intentionally excluded from the automated sequence.

func _on_run_path_explicit_pressed() -> void:
	await _run_e2e("explicit args", _init_explicit)

func _on_run_path_settings_pressed() -> void:
	await _run_e2e("project settings", _init_from_settings)

func _init_explicit() -> void:
	_log("init", "Initializing Adjust (explicit args)...")
	_set_status("Initializing...", COLOR_WARN)
	AdjustPlugin.initialize(app_token, is_sandbox, 30, fb_app_id)

func _init_from_settings() -> void:
	# Push the loaded test credentials into Project Settings in-memory (not saved)
	# so initialize() resolves them via its adjust/config/* fallback.
	ProjectSettings.set_setting("adjust/config/app_token", app_token)
	ProjectSettings.set_setting("adjust/config/fb_app_id", fb_app_id)
	ProjectSettings.set_setting("adjust/config/environment",
		AdjustPlugin.EnvironmentMode.SANDBOX if is_sandbox else AdjustPlugin.EnvironmentMode.PRODUCTION)
	_log("init", "Initializing Adjust from Project Settings (no-arg)...")
	_set_status("Initializing...", COLOR_WARN)
	AdjustPlugin.initialize()

func _run_e2e(label: String, init_action: Callable) -> void:
	if _running:
		return
	_running = true
	_log("e2e", "===== E2E START (%s) =====" % label)
	_init_completed = false
	init_action.call()
	if not await _await_init(5.0):
		_log("e2e", "FAIL: initialization_completed not received within 5s")
		_log("e2e", "===== E2E END (%s): FAILED =====" % label)
		_running = false
		return
	await _delay(1.0)
	_log("e2e", "attribution: %s" % str(AdjustPlugin.get_attribution()))
	await _delay(0.5)
	AdjustPlugin.track_event(event_token)
	_log("e2e", "tracked event: %s" % event_token)
	await _delay(0.5)
	AdjustPlugin.track_event_with_revenue(event_token, 0.99, "USD")
	_log("e2e", "tracked revenue: 0.99 USD")
	await _delay(0.5)
	AdjustPlugin.track_ad_revenue("AppLovin", 0.45, "USD")
	_log("e2e", "tracked ad revenue: 0.45 USD")
	await _delay(0.5)
	AdjustPlugin.track_measurement_consent(true)
	_log("e2e", "measurement consent: true")
	await _delay(2.0)
	_log("e2e", "attribution (after events): %s" % str(AdjustPlugin.get_attribution()))
	_log("e2e", "===== E2E END (%s): OK =====" % label)
	_running = false

func _await_init(timeout_seconds: float) -> bool:
	var elapsed := 0.0
	while not _init_completed and elapsed < timeout_seconds:
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1
	return _init_completed

func _delay(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

# --- Callbacks ---

func _on_adjust_init_completed() -> void:
	_init_completed = true
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
