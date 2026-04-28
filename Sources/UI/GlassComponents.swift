import SwiftUI

struct GlassPanel<Content: View>: View {
    var prominence: GlassProminence = .balanced
    @ViewBuilder var content: Content
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        Group {
            if reduceTransparency {
                content
                    .padding(18)
                    .background(.regularMaterial, in: shape)
                    .overlay(shape.stroke(.white.opacity(0.18), lineWidth: 1))
            } else {
                content
                    .padding(18)
                    .glassEffect(glass, in: shape)
            }
        }
    }

    private var cornerRadius: CGFloat {
        switch prominence {
        case .subtle:
            18
        case .balanced:
            24
        case .prominent:
            30
        }
    }

    private var glass: Glass {
        switch prominence {
        case .subtle:
            .regular.interactive(false)
        case .balanced:
            .regular.interactive(false)
        case .prominent:
            .regular.tint(.blue.opacity(0.16)).interactive(false)
        }
    }
}

struct GlassStatusPill: View {
    let text: String
    let systemImage: String
    let prominence: GlassProminence

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.headline)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .glassEffect(glass, in: Capsule())
            .accessibilityLabel(text)
    }

    private var glass: Glass {
        switch prominence {
        case .subtle:
            .regular
        case .balanced:
            .regular.interactive(false)
        case .prominent:
            .regular.tint(.orange.opacity(0.20)).interactive(false)
        }
    }
}

struct GlassMeetingCard: View {
    let event: MeetingEvent

    var body: some View {
        GlassPanel(prominence: .balanced) {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text(event.title)
                        .font(.system(size: 46, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.65)

                    Text(event.calendarTitle)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Label(event.timeRangeLabel, systemImage: "clock")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct GlassProminentActionButton: View {
    let title: String
    let systemImage: String
    var tint: Color = .orange
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(minWidth: 150)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.extraLarge)
        .tint(isEnabled ? tint : .gray)
        .disabled(!isEnabled)
    }
}
