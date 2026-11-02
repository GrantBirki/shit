import SwiftUI

enum SettingsTab: Int, CaseIterable {
    case general
    case alerts
    case calendars

    fileprivate var label: Label<Text, Image> {
        switch self {
        case .general: Label("General", systemImage: "gearshape")
        case .alerts: Label("Alerts", systemImage: "bell.badge")
        case .calendars: Label("Calendars", systemImage: "calendar")
        }
    }

    func adjacent(forward: Bool) -> Self {
        let tabs = Self.allCases
        return tabs[(rawValue + (forward ? 1 : tabs.count - 1)) % tabs.count]
    }
}

struct SettingsTabStrip: View {
    @Binding var selection: SettingsTab
    @FocusState private var focusedTab: SettingsTab?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        HStack(spacing: 4) {
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                Button {
                    selection = tab
                } label: {
                    tab.label
                        .labelStyle(.titleAndIcon)
                        .fontWeight(selection == tab ? .semibold : .regular)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background {
                            if selection == tab {
                                selectedBackground
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .focused($focusedTab, equals: tab)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .onKeyPress(keys: [.leftArrow, .rightArrow]) { press in
            guard let focusedTab, press.modifiers.isDisjoint(with: [.shift, .control, .option, .command])
            else { return .ignored }
            let forward = (press.key == .rightArrow) == (layoutDirection == .leftToRight)
            selection = focusedTab.adjacent(forward: forward)
            self.focusedTab = selection
            return .handled
        }
        .onChange(of: selection) {
            if focusedTab != nil {
                focusedTab = selection
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: selection)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Settings sections")
        .accessibilityAddTraits(.isTabBar)
    }

    @ViewBuilder private var selectedBackground: some View {
        if reduceTransparency {
            Capsule()
                .fill(Color(nsColor: .controlBackgroundColor))
                .strokeBorder(Color.accentColor, lineWidth: 2)
        } else {
            Color.clear
                .glassEffect(.regular.tint(.accentColor.opacity(0.4)), in: Capsule())
        }
    }
}
