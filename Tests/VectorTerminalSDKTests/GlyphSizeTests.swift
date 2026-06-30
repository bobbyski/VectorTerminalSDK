import Testing
@testable import VectorTerminalSDK

struct GlyphSizeTests {
    private let esc = "\u{1B}"

    @Test func queryTerminalGlyphSizeParsesVTGResponse() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        harness.writeInput("\(esc)_VTG;glyphSize,character=W,width=9,height=18\(esc)\\")

        let size = harness.canvas.queryTerminalGlyphSize(timeoutMilliseconds: 50)

        #expect(size?.width == 9)
        #expect(size?.height == 18)
        #expect(harness.output().contains("\(esc)_VTG;glyphSize?\(esc)\\"))
    }

    @Test func queryTerminalWSizePrefersVTGGlyphSizeResponse() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        harness.writeInput("\(esc)_VTG;glyphSize,character=W,width=10,height=20\(esc)\\")

        let size = harness.canvas.queryTerminalWSize(timeoutMilliseconds: 50)

        #expect(size?.width == 10)
        #expect(size?.height == 20)
    }

    @Test func terminalWSizeCanFallbackToKnownGridAndCanvas() {
        let cellSize = TerminalCellSize(columns: 100, rows: 40)
        let canvas = VTGCanvas(width: 1200, height: 800)

        let size = VectorTerminalCanvas.terminalWSize(from: cellSize, canvas: canvas)

        #expect(size?.width == 12)
        #expect(size?.height == 20)
    }
}
