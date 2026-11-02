# Settings

Use the General, Alerts, and Calendars tabs to move between settings. A glass capsule marks the selected tab. With Reduce Transparency turned on in macOS, the selection uses a fill and outline.

Shit stores settings in macOS `UserDefaults` under the app bundle identifier.

## Alert Timing

Controls when meeting alerts appear.

- The first alert accepts any whole-minute value from 0 to 120.
- Default first alert: `5 minutes before`
- `0` means at the meeting start.
- You can add a second alert closer to the meeting start. Both alerts are saved across relaunches, including when the first is left at five minutes.
- Dismissing one alert does not cancel a later alert for the same meeting.
- When several reminders are due, they appear one at a time in trigger order. Dismiss an unlocked reminder to see the next one.

Shit keeps checking for reminders while its menu is open. Advance alerts missed while the Mac is asleep are skipped instead of appearing late. Shit can first detect an **At start** reminder up to 15 minutes after the meeting begins. A reminder already in the queue stays eligible until the meeting ends.

Meeting times follow the Mac's current timezone. Changing the system timezone refreshes the menu and any visible alert without restarting Shit or changing when alerts are due.

## Alert Focus

App switching stays available by default. To keep the alert in front and disable ⌘Tab until dismissal, enable **Block app switching during alerts** in Alerts settings. Dismissing a locked reminder or opening its meeting link releases the lock. Use **Show Current Alert** in the menu to continue through the remaining reminders.

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
