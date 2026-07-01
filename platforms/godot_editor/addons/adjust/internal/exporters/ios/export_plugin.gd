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

func _get_name() -> String:
	return "AdjustIOS"

func _supports_platform(platform: EditorExportPlatform) -> bool:
	return platform.get_os_name() == "iOS"

func _end_generate_apple_embedded_project(path: String, _will_build_archive: bool) -> void:
	if not _supports_platform(get_export_platform()):
		return

	var export_dir := path.get_base_dir()
	var project_name := path.get_file().get_basename()

	print("Adjust iOS: Xcode project generated at: %s" % path)

	_generate_package_swift(export_dir)
	_generate_dummy_source(export_dir)
	_patch_xcodeproj(export_dir, project_name)
	_resolve_dependencies(export_dir, project_name)


func _patch_xcodeproj(export_dir: String, project_name: String) -> void:
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


func _resolve_dependencies(export_dir: String, project_name: String) -> void:
	var globalized_project := ProjectSettings.globalize_path(
		export_dir.path_join(project_name)
	)
	var script_content := """#!/bin/bash
set -e
xcodebuild -resolvePackageDependencies \\
	-project "%s.xcodeproj" \\
	-scheme "%s"
""" % [globalized_project, project_name]

	var script_path := export_dir.path_join("resolve_spm.sh")
	var file := FileAccess.open(script_path, FileAccess.WRITE)
	if not file:
		push_error("Adjust iOS: Failed to write resolve script.")
		return

	file.store_string(script_content)
	file.close()

	var chmod_output: Array = []
	OS.execute("chmod", ["+x", script_path], chmod_output, true, false)

	print("Adjust iOS: Resolving SPM dependencies...")

	var output: Array = []
	var exit_code := OS.execute(script_path, [], output, true, false)

	if exit_code == 0:
		for line in output:
			print("Adjust iOS SPM: %s" % line)
		print("Adjust iOS: SPM dependencies resolved successfully.")
	else:
		for line in output:
			push_error("Adjust iOS SPM: %s" % line)
		push_error("Adjust iOS: Failed to resolve SPM dependencies. Try manually in Xcode.")


func _generate_package_swift(export_dir: String) -> void:
	var source_dir := export_dir.path_join("AdjustDeps")
	if not DirAccess.dir_exists_absolute(source_dir):
		DirAccess.make_dir_recursive_absolute(source_dir)

	var content := """// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AdjustDeps",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "AdjustDeps",
            targets: ["AdjustDeps"]),
    ],
    dependencies: [
        .package(url: "https://github.com/adjust/ios_sdk", exact: "5.7.0"),
    ],
    targets: [
        .target(
            name: "AdjustDeps",
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
	var source_dir := export_dir.path_join("AdjustDeps")
	if not DirAccess.dir_exists_absolute(source_dir):
		DirAccess.make_dir_recursive_absolute(source_dir)

	var content := (
		"// Dummy\n"
		+ "import Foundation\n\n"
		+ "public struct AdjustDeps {\n"
		+ "    public init() {}\n"
		+ "}\n"
	)
	var file := FileAccess.open(source_dir.path_join("Dummy.swift"), FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()
