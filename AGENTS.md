# AGENTS.md

This is a Swift-based macOS menu bar app that helps users miss fewer meetings. It reads locally synced Apple Calendar events with EventKit and shows a native full-screen overlay when a meeting is about to start or is currently active.

## Goals

- Keep setup simple: no Google OAuth, no cloud service, no telemetry, and no external credentials.
- Use local Apple Calendar access through macOS privacy permissions.
- Provide a polished macOS 26 experience with Liquid Glass in the overlay, controls, and settings.
- Follow the same open-source project discipline as OneShot: SwiftPM, XcodeGen, scripts to rule them all, GitHub Actions, zipped app releases, and Homebrew cask installation.

## Development Flow

- Bootstrap: `script/bootstrap`
- Update generated Xcode project: `script/update`
- Build: `script/build`
- Test: `script/test`
- Lint: `script/lint`
- Package: `script/package`
- Release check: `script/release`

All common work should go through the scripts under `script/`. This follows the "scripts to rule them all" pattern.

## Code Standards

1. Follow Swift best practices and idiomatic macOS patterns.
2. Keep behavior testable behind protocols, especially EventKit access.
3. Prefer simple native AppKit/SwiftUI components over custom infrastructure.
4. Use Liquid Glass intentionally for native visual hierarchy, not decorative noise.
5. Add or update unit tests for new behavior.
6. Update `docs/settings.md` when settings or setting-linked behavior changes.
7. Keep changes focused and auditable.
