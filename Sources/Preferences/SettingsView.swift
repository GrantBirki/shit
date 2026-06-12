import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var state: SettingsWindowState
    var onRequestCalendarAccess: () -> Void
    var onOpenCalendarSettings: () -> Void
    var onTestAlert: () -> Void

    @State private var selection: SettingsTab = .general
    @State private var showMenuBarHiddenAlert = false
    @State private var hasShownMenuBarHiddenAlert = false

    var body: some View {
        TabView(selection: $selection) {
            generalPage
                .tag(SettingsTab.general)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            alertsPage
                .tag(SettingsTab.alerts)
                .tabItem {
                    Label("Alerts", systemImage: "bell.badge")
                }

            calendarsPage
                .tag(SettingsTab.calendars)
                .tabItem {
                    Label("Calendars", systemImage: "calendar")
                }
        }
        .padding(.top, 8)
        .frame(minWidth: 680, idealWidth: 720, minHeight: 500, idealHeight: 560)
        .alert("Menu Bar Icon Hidden", isPresented: $showMenuBarHiddenAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("To show it again, open Shit from Spotlight and turn this setting back on.")
        }
    }

    private var generalPage: some View {
        SettingsPage(
            title: "General",
            subtitle: "Choose how Shit runs and where it appears."
        ) {
            SettingsSection(title: "App Behavior") {
                SettingsToggleRow(
                    title: "Launch at login",
                    systemImage: "power",
                    isOn: $settings.autoLaunchEnabled,
                    help: "Start Shit automatically when you sign in."
                )

                Divider()

                SettingsToggleRow(
                    title: "Show menu bar icon",
                    systemImage: "menubar.rectangle",
                    isOn: menuBarIconVisible,
                    help: "Show the Shit icon in the menu bar."
                )
            }
        }
    }

    private var alertsPage: some View {
        SettingsPage(
            title: "Alerts",
            subtitle: "Choose when Shit should interrupt you before a meeting."
        ) {
            SettingsSection(
                title: "Alert Timing",
                subtitle: "Set one alert, or add a second alert closer to the meeting start."
            ) {
                AlertLeadTimeControl(
                    title: "First alert",
                    minutes: firstAlertMinutes,
                    range: AlertOffset.supportedMinutes
                )

                Divider()

                SettingsToggleRow(
                    title: "Second alert",
                    systemImage: "bell.badge",
                    isOn: secondAlertEnabled,
                    isEnabled: settings.canEnableSecondAlert,
                    help: secondAlertHelp
                )

                if let secondMinutes = settings.secondAlertMinutes {
                    Divider()

                    AlertLeadTimeControl(
                        title: "Second alert",
                        minutes: secondAlertMinutes,
                        range: 0 ... max(0, settings.firstAlertMinutes - 1)
                    )

                    Text(
                        "Dismissing the first alert does not cancel the second alert. " +
                            "The second alert must be closer to the meeting start."
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(
                        "Second alert is \(AlertOffset(minutesBefore: secondMinutes)?.label ?? "off"). " +
                            "Dismissing the first alert does not cancel it."
                    )
                }

                Divider()

                HStack(alignment: .center, spacing: 14) {
                    Button(action: onTestAlert) {
                        Label("Test Alert", systemImage: "play.circle.fill")
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.blue)

                    Text("Shows the full-screen overlay with sample meeting details.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var calendarsPage: some View {
        SettingsPage(
            title: "Calendars",
            subtitle: "Manage local Calendar access and keep noisy events out of alerts."
        ) {
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

            SettingsSection(
                title: "Event Filters",
                subtitle: "These defaults skip events that usually do not need an alert."
            ) {
                SettingsToggleRow(
                    title: "Ignore all-day events",
                    systemImage: "calendar",
                    isOn: $settings.ignoreAllDayEvents
                )

                Divider()

                SettingsToggleRow(
                    title: "Ignore free events",
                    systemImage: "calendar.badge.minus",
                    isOn: $settings.ignoreFreeEvents
                )

                Divider()

                SettingsToggleRow(
                    title: "Ignore declined events",
                    systemImage: "person.crop.circle.badge.xmark",
                    isOn: $settings.ignoreDeclinedEvents
                )
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

            SettingsSection(title: "Data Use") {
                Text(
                    "Shit reads local Apple Calendar events only. It does not use Google OAuth, " +
                        "cloud APIs, telemetry, or external credentials."
                )
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var firstAlertMinutes: Binding<Int> {
        Binding(
            get: { settings.firstAlertMinutes },
            set: { settings.setFirstAlertMinutes($0) }
        )
    }

    private var secondAlertEnabled: Binding<Bool> {
        Binding(
            get: { settings.secondAlertMinutes != nil },
            set: { settings.setSecondAlertEnabled($0) }
        )
    }

    private var secondAlertMinutes: Binding<Int> {
        Binding(
            get: { settings.secondAlertMinutes ?? 0 },
            set: { settings.setSecondAlertMinutes($0) }
        )
    }

    private var menuBarIconVisible: Binding<Bool> {
        Binding(
            get: { settings.menuBarIconVisible },
            set: { isVisible in
                settings.menuBarIconVisible = isVisible
                if !isVisible, !hasShownMenuBarHiddenAlert {
                    hasShownMenuBarHiddenAlert = true
                    showMenuBarHiddenAlert = true
                }
            }
        )
    }

    private var secondAlertHelp: String {
        if settings.canEnableSecondAlert {
            return "Add another alert closer to the meeting start."
        }
        return "Move the first alert before the meeting start to add a second alert."
    }
}

private enum SettingsTab: Hashable {
    case general
    case alerts
    case calendars
}
