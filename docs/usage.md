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
- Open Meeting Link button when the event contains a meeting link

You can switch apps with ⌘Tab while a reminder is visible. Enable **Block app switching during alerts** in Alerts settings to keep the reminder in front until dismissal. Click **Dismiss** or press **Escape** to close it on every display. That alert stays dismissed so it does not immediately pop back up. If you configured a second alert, dismissing the first does not cancel the later alert.

Click **Open Meeting Link** or press **⌘J** to open the link with the default app. The overlay closes when macOS accepts the link. If the organizer changes or removes the link while the alert is open, the button and shortcut update on the next calendar refresh. Shit checks the event URL and recognizes web links embedded in the location. It also recognizes conference links in the event notes, including Google Meet, Zoom, Microsoft Teams, Webex, and FaceTime.

Shit shows the same full-screen alert on every display. Dismissing the alert or opening its meeting link from any display closes all copies. Dismissing an unlocked reminder shows the next eligible one. If you switch away, another due reminder can take its place. Joining a meeting or dismissing a locked reminder leaves the rest of that batch in the menu under **Show Current Alert**. Newly due reminders still appear automatically.

Advance alerts missed while the Mac is asleep are skipped instead of being shown late. Shit can first detect an **At start** reminder up to 15 minutes after the meeting begins. A reminder already in the queue stays eligible until the meeting ends.

## Calendar Permissions

If Calendar access is denied, open System Settings -> Privacy & Security -> Calendars and enable Shit.

For local development, reset the Debug app permission with:

```bash
tccutil reset Calendar io.birki.shit.dev
```
