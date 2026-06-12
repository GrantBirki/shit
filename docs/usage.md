# Usage

Shit runs as a macOS menu bar app.

## First Launch

1. Start Shit.
2. Approve Calendar access when macOS prompts.
3. Keep your work calendars synced into Apple Calendar.

Shit reads local Calendar data only. It does not connect directly to Google Calendar.

## Menu Bar

The menu bar item shows the current Calendar access state and meeting state. From the menu you can:

- Reopen the current alert.
- Test the alert overlay.
- Check calendars now.
- Open settings.
- Open the About window.
- Quit Shit.

The menu bar icon can be hidden from General settings. Shit continues checking for meetings while it is hidden. Open Shit from Spotlight to return to Settings and show the icon again.

## Meeting Alerts

By default, Shit alerts you 5 minutes before a meeting. You can set the first alert to any whole-minute value from 0 to 120 and optionally add a second alert closer to the meeting start. The full-screen overlay includes:

- Meeting title
- Calendar name
- Time range
- Countdown or active-meeting status
- Dismiss button

Click Dismiss or press Escape to close the current overlay. That alert stays dismissed so it does not immediately pop back up. If you configured a second alert, dismissing the first does not cancel the later alert.

Advance alerts missed while the Mac is asleep are skipped instead of being shown late. An **At start** alert can still appear while the meeting is active, for up to 15 minutes after it begins.

## Calendar Permissions

If Calendar access is denied, open System Settings -> Privacy & Security -> Calendars and enable Shit.

For local development, reset the Debug app permission with:

```bash
tccutil reset Calendar io.birki.shit.dev
```
