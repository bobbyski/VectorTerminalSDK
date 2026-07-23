import XCTest
@testable import VectorTerminalSDK

final class LinkDetectionTests: XCTestCase {
    func testEnableUsesTerminalDefaultColorWhenColorIsOmitted() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        harness.canvas.enableLinkDetection()

        XCTAssertTrue(harness.output().contains("_VTG;linkDetection,enabled=1,decorate=1"))
        XCTAssertFalse(harness.output().contains("color="))
    }

    func testEnableCanDisableDecorationAndSetColor() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        harness.canvas.enableLinkDetection(decorate: false, color: "#ff00aa")

        XCTAssertTrue(harness.output().contains(
            "_VTG;linkDetection,enabled=1,decorate=0,color=#ff00aa"
        ))
    }

    func testDisableSendsLinkDetectionCommand() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        harness.canvas.disableLinkDetection()

        XCTAssertTrue(harness.output().contains("_VTG;linkDetection,enabled=0"))
    }
}
