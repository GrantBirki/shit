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
- Custom first and optional second alert timing from 0 to 120 minutes before a meeting.
- Configurable calendar filters, launch at login, and menu bar icon visibility.
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

## Signing and Gatekeeper

Official GitHub release archives contain a Developer ID-signed and Apple-notarized application with a stapled notarization ticket. The protected release job verifies the unsigned build artifact before it receives signing credentials, performs signing and notarization without checking out repository code, and publishes only the finalized archive.

Local builds created without maintainer credentials use an ad-hoc signature, which verifies bundle integrity but is not trusted by Gatekeeper. If Gatekeeper blocks an official release, do not disable Gatekeeper or clear quarantine; verify the release checksum and provenance, then report the failure.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
