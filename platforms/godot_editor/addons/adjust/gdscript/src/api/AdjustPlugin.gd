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
extends Node

signal attribution_changed(data: Dictionary)
signal initialization_completed

var _plugin: Object

func _init() -> void:
	_plugin = MobileSingletonPlugin._get_plugin("AdjustGodotPlugin")
	if _plugin:
		MobileSingletonPlugin.safe_connect(_plugin, "attribution_changed", _on_attribution_changed)
		MobileSingletonPlugin.safe_connect(_plugin, "initialization_completed", _on_initialization_completed)
	else:
		print("AdjustPlugin: Native plugin not found. Actions will be ignored in this platform (Editor/Desktop).")

func initialize(app_token: String, is_sandbox: bool, att_wait_interval: int = 30) -> void:
	if _plugin:
		_plugin.initialize(app_token, is_sandbox, att_wait_interval)

func track_event(event_token: String) -> void:
	if _plugin:
		_plugin.track_event(event_token)

func track_event_with_revenue(event_token: String, amount: float, currency: String) -> void:
	if _plugin:
		_plugin.track_event_with_revenue(event_token, amount, currency)

func track_play_store_subscription(price: int, currency: String, sku: String, order_id: String, signature: String, purchase_token: String) -> void:
	if _plugin and _plugin.has_method("track_play_store_subscription"):
		_plugin.track_play_store_subscription(price, currency, sku, order_id, signature, purchase_token)

func track_app_store_subscription(price: String, currency: String, transaction_id: String) -> void:
	if _plugin and _plugin.has_method("track_app_store_subscription"):
		_plugin.track_app_store_subscription(price, currency, transaction_id)

func disable_third_party_sharing() -> void:
	if _plugin:
		_plugin.disable_third_party_sharing()

func gdpr_forget_me() -> void:
	if _plugin:
		_plugin.gdpr_forget_me()

func set_url_strategy(urls: PackedStringArray, use_subdomains: bool, is_data_residency: bool) -> void:
	if _plugin:
		_plugin.set_url_strategy(urls, use_subdomains, is_data_residency)

func _on_attribution_changed(data: Dictionary) -> void:
	attribution_changed.emit(data)

func _on_initialization_completed() -> void:
	initialization_completed.emit()
