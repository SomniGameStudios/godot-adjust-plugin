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

extends EditorExportPlugin

const Config := preload("res://addons/adjust/android/config.gd")

func _get_name() -> String:
	return "AdjustAndroid"

func _supports_platform(platform: EditorExportPlatform) -> bool:
	if not platform is EditorExportPlatformAndroid:
		return false
	
	var config := Config.new()
	return config.is_enabled

func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
	return PackedStringArray(["res://addons/adjust/android/bin/AdjustGodotPlugin-release.aar"])

func _get_android_dependencies(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
	return PackedStringArray([
		"com.adjust.sdk:adjust-android:5.6.0",
		"com.adjust.sdk:adjust-android-meta-referrer:5.6.0",
		"com.android.installreferrer:installreferrer:2.2",
		"com.google.android.gms:play-services-ads-identifier:18.0.1"
	])

func _get_android_manifest_element(platform: EditorExportPlatform, debug: bool) -> String:
	return """
	<uses-permission android:name="android.permission.INTERNET" />
	<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
	"""
