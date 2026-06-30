import Testing
@testable import VectorTerminalSDK

struct PillButtonTests {
    private let esc = "\u{1B}"

    @Test func pillButtonDrawsSolidUnderTextPillAtCurrentCursor() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }
        harness.writeInput("\(esc)[2;3R")
        harness.writeInput("\(esc)_VTG;glyphSize,character=W,width=10,height=20\(esc)\\")

        let layout = harness.canvas.pillButton(
            id: "confirm",
            text: "OK",
            fill: "#06111bcc",
            stroke: nil,
            lineWidth: 2,
            layer: VTGLayer.underText,
            target: "confirm-action",
            timeoutMilliseconds: 50
        )

        #expect(layout == VTGPillButtonLayout(x: 10, y: 20, width: 40, height: 20, row: 2, column: 2))
        #expect(harness.output().contains("\(esc)[6n"))
        #expect(harness.output().contains("\(esc)_VTG;glyphSize?\(esc)\\"))
        #expect(harness.output().contains("rect,id=confirm-pill,x=10,y=20,w=40,h=20,stroke=none,fill=#06111bcc,width=2,radius=10,layer=-1"))
        #expect(harness.output().contains("OK\(esc)[2;6H"))
        #expect(harness.output().contains("draw,id=confirm-label") == false)
        #expect(harness.output().contains("hit,id=confirm-hit,x=10,y=20,w=40,h=20,layer=-1,target=confirm-action"))
    }

    @Test func pillButtonCanUseKnownGlyphSizeWithoutQuerying() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }
        harness.writeInput("\(esc)[1;1R")

        let layout = harness.canvas.pillButton(
            id: "known",
            text: "RUN",
            glyphSize: TerminalGlyphSize(width: 8, height: 16),
            timeoutMilliseconds: 1
        )

        #expect(layout == VTGPillButtonLayout(x: 0, y: 0, width: 40, height: 16, row: 1, column: 1))
        #expect(harness.output().contains("\(esc)[6n"))
        #expect(harness.output().contains("glyphSize?") == false)
        #expect(harness.output().contains("rect,id=known-pill,x=0,y=0,w=40,h=16"))
        #expect(harness.output().contains("RUN\(esc)[1;5H"))
    }

    @Test func pillButtonUsesFractionalGlyphSizeBeforeRoundingPixels() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }
        harness.writeInput("\(esc)[10;24R")

        let layout = harness.canvas.pillButton(
            id: "fractional",
            text: "RUN",
            glyphSize: TerminalGlyphSize(width: 8.66, height: 18.27),
            timeoutMilliseconds: 1
        )

        #expect(layout == VTGPillButtonLayout(x: 191, y: 164, width: 43, height: 18, row: 10, column: 23))
        #expect(harness.output().contains("rect,id=fractional-pill,x=191,y=164,w=43,h=18"))
    }
}
