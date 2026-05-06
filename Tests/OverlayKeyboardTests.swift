@testable import Shit
import XCTest

final class OverlayKeyboardTests: XCTestCase {
    func testRecognizesEscapeByKeyCode() {
        XCTAssertTrue(
            OverlayKeyboard.isEscapeKey(
                keyCode: 53,
                charactersIgnoringModifiers: nil
            )
        )
    }

    func testRecognizesEscapeByCharacter() {
        XCTAssertTrue(
            OverlayKeyboard.isEscapeKey(
                keyCode: 0,
                charactersIgnoringModifiers: "\u{1B}"
            )
        )
    }

    func testRejectsOtherKeys() {
        XCTAssertFalse(
            OverlayKeyboard.isEscapeKey(
                keyCode: 0,
                charactersIgnoringModifiers: "a"
            )
        )
    }
}
