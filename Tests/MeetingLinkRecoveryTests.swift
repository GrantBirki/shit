import AppKit
@testable import Shit
import SwiftUI
import XCTest

@MainActor
final class MeetingLinkRecoveryTests: XCTestCase {
    private let frames = [NSRect(x: 0, y: 0, width: 160, height: 100), NSRect(x: 160, y: 0, width: 160, height: 100)]
    private let start = Date()

    func testFailedJoinOffersTheSameLinkOnBothDisplaysUntilRetrySucceeds() throws {
        _ = NSApplication.shared
        let url = try XCTUnwrap(URL(string: "https://video.example.org/room?room=a%2Fb#join"))
        let candidate = makeCandidate(url: url)
        var canOpen = false
        var copied: [String] = []
        var joins = 0
        var announcements = 0
        let controller = OverlayWindowController(
            displayFrames: { self.frames }, isAppActive: { false }, openURL: { _ in canOpen },
            copyURL: { copied.append($0.absoluteString) }, announceLinkFailure: { announcements += 1 }
        )
        defer { controller.dismiss() }
        controller.show(
            candidate: candidate, requestFocus: false, onJoined: { joins += 1 }, onDismiss: { XCTFail("Dismissed") }
        )
        let views = hiddenViews(for: candidate)
        let first = try XCTUnwrap(views.first)
        let second = try XCTUnwrap(views.last)

        try XCTUnwrap(first.onOpenMeeting)()
        XCTAssertEqual(first.linkRecovery.failedURL, url)
        XCTAssertEqual(second.linkRecovery.failedURL, url)
        XCTAssertTrue(copied.isEmpty)
        try XCTUnwrap(second.onOpenMeeting)()
        XCTAssertEqual(announcements, 1)
        second.linkRecovery.copyLink()
        XCTAssertEqual(copied, [url.absoluteString])
        XCTAssertEqual(joins, 0)

        canOpen = true
        try XCTUnwrap(second.onOpenMeeting)()
        XCTAssertEqual(joins, 1)
        XCTAssertNil(first.linkRecovery.failedURL)
        XCTAssertNil(second.linkRecovery.failedURL)
    }

    func testFailureSurvivesMetadataRefreshButClearsOnNewURLOrReminder() throws {
        _ = NSApplication.shared
        let url = try XCTUnwrap(URL(string: "https://video.example.org/old"))
        let updatedURL = try XCTUnwrap(URL(string: "https://video.example.org/new"))
        var copied: [URL] = []
        let controller = OverlayWindowController(
            displayFrames: { self.frames }, isAppActive: { false },
            openURL: { _ in false }, copyURL: { copied.append($0) }, announceLinkFailure: {}
        )
        defer { controller.dismiss() }
        func show(_ candidate: AlertCandidate) throws -> MeetingOverlayView {
            controller.show(candidate: candidate, requestFocus: false) { XCTFail("Dismissed") }
            return try XCTUnwrap(hiddenViews(for: candidate).first)
        }

        let first = try show(makeCandidate(url: url))
        try XCTUnwrap(first.onOpenMeeting)()
        let renamed = try show(makeCandidate(title: "Renamed", url: url))
        XCTAssertEqual(renamed.linkRecovery.failedURL, url)
        let updated = try show(makeCandidate(url: updatedURL))
        XCTAssertNil(updated.linkRecovery.failedURL)
        try XCTUnwrap(first.onOpenMeeting)()
        first.linkRecovery.copyLink()
        XCTAssertTrue(copied.isEmpty)
        try XCTUnwrap(updated.onOpenMeeting)()
        updated.linkRecovery.copyLink()
        XCTAssertEqual(copied, [updatedURL])

        let next = try show(makeCandidate(id: "next", url: updatedURL))
        XCTAssertNil(next.linkRecovery.failedURL)
        try XCTUnwrap(next.onOpenMeeting)()
        let linkless = try show(makeCandidate(id: "next", url: nil))
        XCTAssertNil(linkless.onOpenMeeting)
        XCTAssertNil(linkless.linkRecovery.failedURL)
    }

    private func makeCandidate(id: String = "first", title: String = "Meeting", url: URL?) -> AlertCandidate {
        AlertCandidate(event: .fixture(id: id, title: title, startDate: start, meetingURL: url), offset: .atStart)
    }

    private func hiddenViews(for candidate: AlertCandidate) -> [MeetingOverlayView] {
        let views = NSApplication.shared.windows.compactMap { window -> MeetingOverlayView? in
            guard let view = (window.contentViewController as? NSHostingController<MeetingOverlayView>)?.rootView,
                  view.candidate == candidate else { return nil }
            XCTAssertFalse(window.isVisible)
            return view
        }
        XCTAssertEqual(views.count, frames.count)
        return views
    }
}
