# Settings

Shit stores settings in macOS `UserDefaults` under the app bundle identifier.

## Alert Timing

Controls when meeting alerts appear.

- The first alert accepts any whole-minute value from 0 to 120.
- Default first alert: `5 minutes before`
- `0` means at the meeting start.
- An optional second alert can be set closer to the meeting start.
- Dismissing one alert does not cancel a later alert for the same meeting.

Advance alerts missed while the Mac is asleep are skipped instead of appearing late. An **At start** alert can still appear while the meeting is active, for up to 15 minutes after it begins.

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

## Menu Bar Icon

Controls whether the Shit icon appears in the menu bar.

- Default: on
- Alerts continue running while the icon is hidden.
- To show the icon again, open Shit from Spotlight and enable it in General settings.

## Calendar Access and Data Use

Shit reads local calendar events through EventKit. It does not use Google OAuth, remote APIs, telemetry, or external credentials.
