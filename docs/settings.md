# Settings

Shit stores settings in macOS `UserDefaults` under the app bundle identifier.

## Alert Timing

Controls when meeting alerts appear.

- Default: `5 minutes before`
- Other supported modes: at start, 1 minute before, 1 minute before + at start

## Calendar Filters

Shit monitors all local Apple Calendars by default, then applies filters.

Defaults:

- Ignore all-day events: on
- Ignore free events: on
- Ignore declined or canceled events: on
- Excluded calendars: none
- Ignored title keywords: none

## Launch At Login

Controls whether Shit registers itself with macOS launch-at-login services.

- Default: off

## Privacy

Shit reads local calendar events through EventKit. It does not use Google OAuth, remote APIs, telemetry, or external credentials.
