# 🤖 Project Intelligence: Godot Adjust Plugin

This file is the authoritative source of truth for ALL AI agents (Gemini, Claude, Cursor). 
**Read this first** to minimize token usage and ensure architectural consistency.

## 🏗️ Repository Architecture
- **Primary Branch:** `main`
- **GDScript (Core):** `platforms/godot_editor/addons/adjust/`
  - `adjust.gd`: Main entry point.
  - `internal/`: Logic. **Rule: No `class_name` here, use `preload`.**
  - `gdscript/src/api/AdjustPlugin.gd`: Public API with `class_name AdjustPlugin`.
- **Native Bridges:** Android (Kotlin/JNI) in `platforms/android/`, iOS (Objective-C++) in `platforms/ios/`.

## 📦 Current Environment
- **Godot Version:** 4.6.2 (Current target for builds and testing).
- **Adjust SDK:** v5.6.0.

## 🛠️ Critical Commands
- **Build All/Specific Platforms:** Use the central script for all compilation needs. 
  - ` ./scripts/build_local.sh [android|ios|all] <godot_version>`
  - *Example (All):* `./scripts/build_local.sh all 4.6.2`

## 📝 Coding Standards
- **License Header:** EVERY new file MUST start with the project's MIT License header (Somni Game Studios).
- **GDScript:** Always use `:=` for type inference.
- **Privacy:** `gdpr_forget_me()` is irreversible. Warn the user in documentation and logs.

## 🚫 Constraints & Security
- **Security:** Never log/commit App Tokens or `.env` files.
- **Gemini:** Respect `.geminiignore` patterns.

## 📋 Pending Tasks
- Verify ATT passthrough behavior on physical iOS devices.

## 🔗 Key Files
- `platforms/godot_editor/addons/adjust/gdscript/src/api/AdjustPlugin.gd` (Main API)
- `platforms/android/src/core/src/main/java/com/somnigamestudios/godot/adjust/AdjustGodotPlugin.kt` (Android Bridge)
- `platforms/ios/src/AdjustGodotPlugin.mm` (iOS Bridge)

