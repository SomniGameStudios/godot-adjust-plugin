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

const PbxprojService := preload("res://addons/adjust/internal/services/pbxproj_service.gd")

var _export_path := ""
var _is_ios := false

func _get_name() -> String:
	return "AdjustIOS"

func _supports_platform(platform: EditorExportPlatform) -> bool:
	return platform.get_os_name() == "iOS"

func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	_export_path = path
	_is_ios = features.has("ios")

func _export_end() -> void:
	if not _is_ios or _export_path.is_empty():
		return
		
	var export_dir := _export_path.get_base_dir()
	_generate_package_swift(export_dir)
	_generate_dummy_source(export_dir)
	_defer_pbxproj_patch.call_deferred(export_dir)

func _defer_pbxproj_patch(export_dir: String) -> void:
	_patch_xcodeproj(export_dir)

func _patch_xcodeproj(export_dir: String) -> void:
	var project_name := _export_path.get_file().get_basename()
	var pbxproj_path := export_dir.path_join(project_name + ".xcodeproj/project.pbxproj")
	
	if FileAccess.file_exists(pbxproj_path):
		PbxprojService.patch(pbxproj_path)
		return
	
	var dir := DirAccess.open(export_dir)
	if not dir:
		return
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".xcodeproj"):
			var found_path := export_dir.path_join(file_name).path_join("project.pbxproj")
			if FileAccess.file_exists(found_path):
				PbxprojService.patch(found_path)
			break
		file_name = dir.get_next()

func _generate_package_swift(export_dir: String) -> void:
	var source_dir := export_dir.path_join("SomniAdjustDeps")
	if not DirAccess.dir_exists_absolute(source_dir):
		DirAccess.make_dir_recursive_absolute(source_dir)
			
	var content := """// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SomniAdjustDeps",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "SomniAdjustDeps",
            targets: ["SomniAdjustDeps"]),
    ],
    dependencies: [
        .package(url: "https://github.com/adjust/ios_sdk", from: "5.6.0"),
    ],
    targets: [
        .target(
            name: "SomniAdjustDeps",
            dependencies: [
                .product(name: "AdjustSdk", package: "ios_sdk"),
            ],
            path: "."
        )
    ]
)
"""
	var file := FileAccess.open(source_dir.path_join("Package.swift"), FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()

func _generate_dummy_source(export_dir: String) -> void:
	var source_dir := export_dir.path_join("SomniAdjustDeps")
	if not DirAccess.dir_exists_absolute(source_dir):
		DirAccess.make_dir_recursive_absolute(source_dir)
			
	var content := "// Dummy\nimport Foundation\n\npublic struct SomniAdjustDeps {\n    public init() {}\n}\n"
	var file := FileAccess.open(source_dir.path_join("Dummy.swift"), FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()
