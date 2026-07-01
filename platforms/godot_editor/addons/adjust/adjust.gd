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

@tool
extends EditorPlugin

# Project Settings exposed under Project > Project Settings > Adjust.
const _SETTINGS := {
	"adjust/config/app_token": {
		"type": TYPE_STRING, "value": "",
		"hint": PROPERTY_HINT_NONE, "hint_string": "Your Adjust app token.",
	},
	"adjust/config/fb_app_id": {
		"type": TYPE_STRING, "value": "",
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "Optional Meta (Facebook) App ID for the Android Meta Install Referrer.",
	},
	"adjust/config/att_wait_interval": {
		"type": TYPE_INT, "value": 30,
		"hint": PROPERTY_HINT_RANGE, "hint_string": "0,360,1",
	},
	"adjust/config/environment": {
		"type": TYPE_INT, "value": 0,
		"hint": PROPERTY_HINT_ENUM, "hint_string": "Auto (Debug=Sandbox),Sandbox,Production",
	},
	"adjust/config/auto_initialize": {
		"type": TYPE_BOOL, "value": false,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "Auto-initialize the SDK on boot from these settings.",
	},
}

var _android_exporter := preload("res://addons/adjust/internal/exporters/android/export_plugin.gd").new()
var _ios_exporter := preload("res://addons/adjust/internal/exporters/ios/export_plugin.gd").new()

func _enter_tree() -> void:
	add_export_plugin(_android_exporter)
	add_export_plugin(_ios_exporter)
	_register_settings()

func _exit_tree() -> void:
	remove_export_plugin(_android_exporter)
	remove_export_plugin(_ios_exporter)

func _register_settings() -> void:
	var dirty := false
	for key in _SETTINGS:
		var cfg: Dictionary = _SETTINGS[key]
		if not ProjectSettings.has_setting(key):
			ProjectSettings.set_setting(key, cfg.value)
			dirty = true
		ProjectSettings.set_initial_value(key, cfg.value)
		ProjectSettings.add_property_info({
			"name": key,
			"type": cfg.type,
			"hint": cfg.hint,
			"hint_string": cfg.hint_string,
		})
		ProjectSettings.set_as_basic(key, true)
	if dirty:
		ProjectSettings.save()
