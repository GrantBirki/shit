import SwiftUI

@MainActor
@Observable
final class MeetingLinkRecovery {
    var failedURL: URL?
    private let copyURL: (URL) -> Void

    init(copyURL: @escaping (URL) -> Void) {
        self.copyURL = copyURL
    }

    func copyLink() {
        if let failedURL {
            copyURL(failedURL)
        }
    }
}

struct MeetingOverlayView: View {
    let candidate: AlertCandidate
    let onDismiss: () -> Void
    let onOpenMeeting: (() -> Void)?
    let linkRecovery: MeetingLinkRecovery

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

                    if linkRecovery.failedURL != nil {
                        GlassPanel(prominence: .subtle) {
                            HStack {
                                Label("Couldn't open the meeting link.", systemImage: "exclamationmark.circle")
                                Button("Copy Link", action: linkRecovery.copyLink)
                                    .accessibilityHint("Copies the meeting link to the clipboard.")
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        if let onOpenMeeting {
                            GlassActionButton(
                                title: "Open Meeting Link",
                                systemImage: "video",
                                isProminent: true,
                                action: onOpenMeeting
                            )
                            .keyboardShortcut("j", modifiers: .command)
                            .help("Open the meeting link (⌘J)")
                        }
                        GlassActionButton(
                            title: "Dismiss",
                            systemImage: "checkmark",
                            isProminent: onOpenMeeting == nil,
                            action: onDismiss
                        )
                        .help("Dismiss the alert (Esc)")
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
