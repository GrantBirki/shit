import AppKit
import SwiftUI

struct SettingsPage<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            GlassEffectContainer(spacing: 16) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .font(.largeTitle.weight(.semibold))
                        Text(subtitle)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 2)

                    content
                }
                .padding(24)
            }
        }
        .scrollIndicators(.automatic)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder var content: Content

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        GlassPanel(prominence: .subtle) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    if let subtitle {
                        Text(subtitle)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct GlassIconToggle: View {
    let title: String
    let systemImage: String
    @Binding var isOn: Bool
    var isEnabled = true
    var help: String?

    var body: some View {
        Toggle(isOn: $isOn) {
            Image(systemName: systemImage)
                .symbolVariant(isOn ? .fill : .none)
                .frame(minWidth: 18)
        }
        .toggleStyle(.button)
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
        .disabled(!isEnabled)
        .help(help ?? title)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

struct SettingsToggleRow: View {
    let title: String
    let systemImage: String
    @Binding var isOn: Bool
    var isEnabled = true
    var help: String?

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.callout)

            Spacer(minLength: 12)

            GlassIconToggle(
                title: title,
                systemImage: systemImage,
                isOn: $isOn,
                isEnabled: isEnabled,
                help: help
            )
        }
    }
}

struct AlertLeadTimeControl: View {
    let title: String
    @Binding var minutes: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.callout)

            Spacer(minLength: 12)

            TextField("", value: $minutes, format: .number)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: 58)
                .accessibilityLabel("\(title) minutes before")

            Stepper("", value: $minutes, in: range)
                .labelsHidden()
                .fixedSize()
                .accessibilityLabel("Adjust \(title.lowercased())")

            Text(unitLabel)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 104, alignment: .leading)
        }
    }

    private var unitLabel: String {
        switch minutes {
        case 0:
            "at start"
        case 1:
            "minute before"
        default:
            "minutes before"
        }
    }
}

struct CalendarToggleRow: View {
    let calendar: CalendarSource
    @Binding var isIncluded: Bool

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(calendar.displayColor)
                .frame(width: 10, height: 10)

            Text(calendar.title)
                .font(.callout)
                .lineLimit(1)

            Spacer(minLength: 12)

            GlassIconToggle(
                title: "Include \(calendar.title)",
                systemImage: "checkmark",
                isOn: $isIncluded,
                help: "Include \(calendar.title) in meeting alerts."
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }
}

struct EmptySettingsState: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.callout.weight(.medium))
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct CalendarAccessBadge: View {
    let authorization: CalendarAuthorizationState

    var body: some View {
        Label(
            authorization.menuTitle,
            systemImage: authorization.canReadEvents ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
        )
        .font(.callout.weight(.medium))
        .foregroundStyle(authorization.canReadEvents ? Color.green : Color.orange)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(.regular.interactive(false), in: Capsule())
    }
}

private extension CalendarSource {
    var displayColor: Color {
        guard let colorHex,
              let color = NSColor(hexString: colorHex)
        else {
            return .accentColor
        }
        return Color(nsColor: color)
    }
}

private extension NSColor {
    convenience init?(hexString: String) {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }

        guard hex.count == 6,
              let value = Int(hex, radix: 16)
        else {
            return nil
        }

        let red = CGFloat((value >> 16) & 0xFF) / 255
        let green = CGFloat((value >> 8) & 0xFF) / 255
        let blue = CGFloat(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}
