# Shit 📆

[![build](https://github.com/GrantBirki/shit/actions/workflows/build.yml/badge.svg)](https://github.com/GrantBirki/shit/actions/workflows/build.yml)
[![test](https://github.com/GrantBirki/shit/actions/workflows/test.yml/badge.svg)](https://github.com/GrantBirki/shit/actions/workflows/test.yml)
[![lint](https://github.com/GrantBirki/shit/actions/workflows/lint.yml/badge.svg)](https://github.com/GrantBirki/shit/actions/workflows/lint.yml)
[![release](https://github.com/GrantBirki/shit/actions/workflows/release.yml/badge.svg)](https://github.com/GrantBirki/shit/actions/workflows/release.yml)

A native macOS menu bar app that helps you miss fewer meetings.

When I miss a meeting: _Shit..._

Shit reads your locally synced Apple Calendar events and shows a hard-to-miss overlay when a meeting is about to start or is already active. It does not use Google OAuth, cloud services, telemetry, or external credentials. It is 100% local.

Requires macOS Tahoe 26 or later.

https://github.com/user-attachments/assets/cf1a85d8-4d4b-42be-a2db-ff151c092b24

## Installation

Homebrew (recommended):

```bash
brew install --cask grantbirki/tap/shit
```

## Features

- Local Apple Calendar access through macOS privacy permissions.
- Full-screen meeting overlay with Liquid Glass panels and controls.
- Configurable alert timing, calendar filters, and launch at login.
- Native menu bar controls for checking meetings, reopening the current alert, settings, and quit.

## Usage

- End-user guide: [docs/usage.md](docs/usage.md)
- Settings reference: [docs/settings.md](docs/settings.md)

## Verify Releases

Release artifacts are published with SLSA provenance. After downloading `Shit.zip`:

```bash
gh attestation verify Shit.zip \
  --repo grantbirki/shit \
  --signer-workflow grantbirki/shit/.github/workflows/release.yml \
  --source-ref refs/heads/main \
  --deny-self-hosted-runners
```

Minimal verification by owner:

```bash
gh attestation verify Shit.zip --owner grantbirki
```

You can also verify the checksum:

```bash
shasum -a 256 Shit.zip
```

## Unsigned Builds

Shit releases are currently unsigned. macOS Gatekeeper may block the first launch.

To open it:

1. Right-click `Shit.app` and choose Open.
2. Or go to System Settings -> Privacy & Security and click Open Anyway.
3. If neither shows, remove the quarantine attribute:

```bash
xattr -dr com.apple.quarantine /Applications/Shit.app
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
