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

## Meeting Alerts

By default, Shit alerts you 5 minutes before a meeting. The full-screen overlay includes:

- Meeting title
- Calendar name
- Time range
- Countdown or active-meeting status
- Dismiss button

Click Dismiss or press Escape to close the current overlay. The alert stays dismissed for that meeting so it does not immediately pop back up.

## Calendar Permissions

If Calendar access is denied, open System Settings -> Privacy & Security -> Calendars and enable Shit.

For local development, reset the Debug app permission with:

```bash
tccutil reset Calendar io.birki.shit.dev
```
