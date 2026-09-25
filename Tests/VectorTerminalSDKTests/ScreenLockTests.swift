import Testing
@testable import VectorTerminalSDK

/// A screen of an exact size: what the SDK sends, and what it makes of the
/// answer. The point of the feature is a program reproducing a machine, so the
/// numbers it asks for have to survive the round trip exactly.
struct ScreenLockTests {
    private let esc = "\u{1B}"

    @Test func lockScreenSendsTheResolutionAndGrid() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        harness.canvas.lockScreen(width: 320, height: 200, columns: 40, rows: 25)

        #expect(harness.output().contains("\(esc)_VTG;screenLock,width=320,height=200,cols=40,rows=25\(esc)\\"))
    }

    @Test func aResolutionWithNoGridLeavesTheGridToTheTerminal() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        harness.canvas.lockScreen(width: 256, height: 192)

        let sent = harness.output()
        #expect(sent.contains("screenLock,width=256,height=192"))
        #expect(!sent.contains("cols="))
        #expect(!sent.contains("rows="))
    }

    @Test func aScreenWithNoSizeIsNotSent() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        harness.canvas.lockScreen(width: 0, height: 200)

        #expect(!harness.output().contains("screenLock"))
    }

    @Test func queryScreenLockReadsTheScreenAndWhereItSits() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        harness.writeInput("\(esc)_VTG;screen,locked=1,width=320,height=200,cols=40,rows=25,"
            + "scale=3,x=20,y=50,pixelWidth=960,pixelHeight=600,exact=1\(esc)\\")

        let screen = harness.canvas.queryScreenLock(timeoutMilliseconds: 50)

        #expect(screen?.isLocked == true)
        #expect(screen?.width == 320 && screen?.height == 200)
        #expect(screen?.columns == 40 && screen?.rows == 25)
        #expect(screen?.scale == 3)
        #expect(screen?.x == 20 && screen?.y == 50)
        #expect(screen?.isExact == true)
        #expect(harness.output().contains("\(esc)_VTG;screen?\(esc)\\"))
    }

    @Test func anUnlockedScreenIsReportedPlainly() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        harness.writeInput("\(esc)_VTG;screen,locked=0\(esc)\\")

        #expect(harness.canvas.queryScreenLock(timeoutMilliseconds: 50) == .unlocked)
    }

    @Test func aWindowTooSmallForOneToOneSaysSo() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        harness.writeInput("\(esc)_VTG;screen,locked=1,width=320,height=200,cols=40,rows=25,"
            + "scale=0.5,x=0,y=0,pixelWidth=160,pixelHeight=100,exact=0\(esc)\\")

        let screen = harness.canvas.queryScreenLock(timeoutMilliseconds: 50)
        #expect(screen?.isLocked == true)
        #expect(screen?.scale == 0.5)
        #expect(screen?.isExact == false)
    }

    @Test func unlockScreenGivesTheWindowBack() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        harness.canvas.unlockScreen()

        #expect(harness.output().contains("\(esc)_VTG;screenUnlock\(esc)\\"))
    }
}
