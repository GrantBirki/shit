import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var state: SettingsWindowState
    var onRequestCalendarAccess: () -> Void
    var onOpenCalendarSettings: () -> Void
    var onTestAlert: () -> Void

    @State private var selection: SettingsTab = .alerts

    var body: some View {
        TabView(selection: $selection) {
            SettingsPage(
                title: "Alerts",
                subtitle: "Choose when Shit should interrupt you before a meeting."
            ) {
                SettingsSection(
                    title: "Alert Timing",
                    subtitle: "Default is 5 minutes before the meeting starts."
                ) {
                    Picker("Alert timing", selection: $settings.alertTiming) {
                        ForEach(AlertTiming.allCases) { timing in
                            Text(timing.label).tag(timing)
                        }
                    }
                    .pickerStyle(.menu)

                    Divider()

                    HStack(alignment: .center, spacing: 14) {
                        Button(action: onTestAlert) {
                            Label("Test Alert", systemImage: "play.circle.fill")
                        }
                        .buttonStyle(.glassProminent)
                        .tint(.orange)

                        Text("Shows the full-screen overlay with sample meeting details.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .tag(SettingsTab.alerts)
            .tabItem {
                Label("Alerts", systemImage: "bell.badge")
            }

            SettingsPage(
                title: "Calendars",
                subtitle: "Keep noisy events and calendars out of meeting alerts."
            ) {
                SettingsSection(
                    title: "Event Filters",
                    subtitle: "These defaults skip events that usually do not need an alert."
                ) {
                    Toggle("Ignore all-day events", isOn: $settings.ignoreAllDayEvents)
                    Toggle("Ignore free events", isOn: $settings.ignoreFreeEvents)
                    Toggle("Ignore declined events", isOn: $settings.ignoreDeclinedEvents)
                }

                SettingsSection(
                    title: "Included Calendars",
                    subtitle: "Turn a calendar off here to exclude its meetings from alerts."
                ) {
                    if state.calendars.isEmpty {
                        EmptySettingsState(
                            systemImage: "calendar.badge.exclamationmark",
                            title: "No calendars available",
                            message: "Grant Calendar access and make sure Apple Calendar is syncing " +
                                "your work calendars."
                        )
                    } else {
                        VStack(spacing: 8) {
                            ForEach(state.calendars) { calendar in
                                CalendarToggleRow(
                                    calendar: calendar,
                                    isIncluded: Binding(
                                        get: {
                                            !settings.excludedCalendarIdentifiers.contains(calendar.id)
                                        },
                                        set: { isIncluded in
                                            if isIncluded {
                                                settings.excludedCalendarIdentifiers.remove(calendar.id)
                                            } else {
                                                settings.excludedCalendarIdentifiers.insert(calendar.id)
                                            }
                                        }
                                    )
                                )
                            }
                        }
                    }
                }

                SettingsSection(
                    title: "Ignored Title Keywords",
                    subtitle: "One keyword per line. Matching is case-insensitive."
                ) {
                    TextEditor(text: $settings.ignoredTitleKeywordsText)
                        .font(.body.monospaced())
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 112)
                        .padding(10)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(.white.opacity(0.14), lineWidth: 1)
                        }
                }
            }
            .tag(SettingsTab.calendars)
            .tabItem {
                Label("Calendars", systemImage: "calendar")
            }

            SettingsPage(
                title: "Privacy",
                subtitle: "Calendar access stays local to this Mac."
            ) {
                SettingsSection(title: "Launch At Login") {
                    Toggle("Launch at login", isOn: $settings.autoLaunchEnabled)
                }

                SettingsSection(
                    title: "Calendar Access",
                    subtitle: "Shit needs full Calendar access to read local Apple Calendar events."
                ) {
                    HStack(spacing: 12) {
                        CalendarAccessBadge(authorization: state.authorization)
                        Spacer()
                    }

                    HStack(spacing: 10) {
                        Button("Request Access", action: onRequestCalendarAccess)
                            .buttonStyle(.glass)
                        Button("Open Privacy Settings", action: onOpenCalendarSettings)
                            .buttonStyle(.glass)
                    }
                }

                SettingsSection(title: "Data Use") {
                    Text(
                        "Shit reads local Apple Calendar events only. It does not use Google OAuth, " +
                            "cloud APIs, telemetry, or external credentials."
                    )
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tag(SettingsTab.privacy)
            .tabItem {
                Label("Privacy", systemImage: "lock.shield")
            }
        }
        .padding(.top, 8)
        .frame(minWidth: 680, idealWidth: 720, minHeight: 500, idealHeight: 560)
    }
}

private enum SettingsTab: Hashable {
    case alerts
    case calendars
    case privacy
}
