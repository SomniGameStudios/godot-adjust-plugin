# Godot Adjust Plugin

Godot Adjust Plugin for Android and iOS. This plugin provides a bridge to the Adjust SDK v5.6.0.

## Features
- Install attribution tracking.
- Revenue event tracking.
- GDPR compliance (`gdpr_forget_me`).
- ATT passthrough for iOS.
- EU data residency support.

## Architecture
This plugin follows the "Editor Plugin" pattern, allowing easy management and export of native dependencies.

## Building
Use the provided build script:
```bash
./scripts/build_local.sh all 4.6.2
```

## Documentation
See `AGENTS.md` for architectural details and coding standards.
