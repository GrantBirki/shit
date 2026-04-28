import SwiftUI

struct MeetingOverlayView: View {
    let candidate: AlertCandidate
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        ZStack {
            Color.black.opacity(reduceTransparency ? 0.78 : 0.38)
                .ignoresSafeArea()

            GlassEffectContainer(spacing: 18) {
                VStack(spacing: 18) {
                    GlassStatusPill(
                        text: statusText,
                        systemImage: "calendar.badge.clock",
                        prominence: .balanced
                    )

                    GlassMeetingCard(event: candidate.event)

                    HStack(spacing: 12) {
                        GlassProminentActionButton(
                            title: "Dismiss",
                            systemImage: "checkmark",
                            tint: Color(red: 0.18, green: 0.64, blue: 0.34),
                            isEnabled: true,
                            action: onDismiss
                        )
                    }
                }
                .padding(30)
                .frame(maxWidth: 760)
            }
            .transition(reduceMotion ? .opacity : .scale(scale: 0.96).combined(with: .opacity))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var statusText: String {
        OverlayPresentation.statusText(for: candidate.event, now: Date())
    }
}
