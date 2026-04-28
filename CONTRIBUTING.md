# Contributing to Shit

This project uses the `script/` tools for all common tasks.

## Setup

```bash
script/bootstrap
```

This installs required tools (XcodeGen, SwiftLint, SwiftFormat), generates the Xcode project, and runs a Swift package build.

## Development

- Build: `script/build`
- Test: `script/test`
- Lint/format checks: `script/lint`
- Run the app (Debug): `script/server`
- Record a manual performance trace: `script/perf`

If you change `project.yml`, run `script/update` to regenerate the Xcode project.

## Release Flow

Versioning is driven by the `VERSION` file. Bump it manually in `X.Y.Z` format.

Releases are created by GitHub Actions when `VERSION` changes on `main`. The workflow:

- Builds the release zip via `script/package`
- Creates the GitHub release and tag
- Publishes a checksum and build provenance

Update the Homebrew cask manually in `grantbirki/homebrew-tap` after each release.

## Permissions

Shit needs Calendar access so it can read locally synced Apple Calendar events. If the Debug app does not appear in Calendar permissions after launch, add or re-enable it in System Settings -> Privacy & Security -> Calendars.

To reset Calendar permissions for the Debug app:

```bash
tccutil reset Calendar io.birki.shit.dev
```

## Guidelines

- Use Swift best practices and keep changes focused.
- Add or update tests for new behavior.
- Update `docs/settings.md` when settings or behavior tied to settings change.
- Prefer the scripts under `script/` over direct tool invocations.
- Only add original work or code/assets with a license that allows redistribution in this project.
