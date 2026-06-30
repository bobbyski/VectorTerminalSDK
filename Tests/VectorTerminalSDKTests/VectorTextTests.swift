import Testing
import VectorTerminalSDK

struct VectorTextTests {
    @Test func vectorTextSizeMatchesVectorPrintAdvance() {
        #expect(VectorTerminalCanvas.vectorTextSize(height: 7, value: "").width == 0)
        #expect(VectorTerminalCanvas.vectorTextSize(height: 7, value: "A") == VTGTextSize(width: 7, height: 7))
        #expect(VectorTerminalCanvas.vectorTextSize(height: 14, value: "AB C") == VTGTextSize(width: 56, height: 14))
    }

    @Test func vectorTextSizeUsesMinimumGlyphHeight() {
        #expect(VectorTerminalCanvas.vectorTextSize(height: 1, value: "AB") == VTGTextSize(width: 14, height: 7))
    }

    @Test func canvasInstanceVectorTextSizeDelegatesToStaticHelper() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        #expect(harness.canvas.vectorTextSize(height: 21, value: "VTG") == VTGTextSize(width: 63, height: 21))
    }

    @Test func deleteVectorTextDeletesRememberedGlyphStrokes() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        harness.canvas.vectorPrint(id: "word", x: 10, y: 20, height: 14, value: "A", stroke: .cyan)
        harness.canvas.deleteVectorText(id: "word")

        let output = harness.output()
        #expect(output.contains("_VTG;draw,id=word-0-0"))
        #expect(output.contains("_VTG;draw,id=word-0-1"))
        #expect(output.contains("_VTG;delete,id=word-0-0"))
        #expect(output.contains("_VTG;delete,id=word-0-1"))
    }

    @Test func vectorPrintDeletesPreviousChildrenBeforeRedraw() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        harness.canvas.vectorPrint(id: "word", x: 10, y: 20, height: 14, value: "A", stroke: .cyan)
        harness.canvas.vectorPrint(id: "word", x: 10, y: 20, height: 14, value: "I", stroke: .cyan)

        let output = harness.output()
        #expect(output.contains("_VTG;delete,id=word-0-0"))
        #expect(output.contains("_VTG;delete,id=word-0-1"))
        #expect(output.contains("_VTG;draw,id=word-0-2"))
    }

    @Test func vectorPunctuationUsesDedicatedGlyphs() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        harness.canvas.vectorPrint(id: "punct", x: 10, y: 20, height: 7, value: ":.-/!?", stroke: .cyan, width: 1)

        let output = harness.output()
        #expect(output.contains("_VTG;draw,id=punct-0-0"))
        #expect(output.contains("_VTG;draw,id=punct-1-0"))
        #expect(output.contains("_VTG;draw,id=punct-2-0"))
        #expect(output.contains("_VTG;draw,id=punct-3-0"))
        #expect(output.contains("_VTG;draw,id=punct-4-0"))
        #expect(output.contains("_VTG;draw,id=punct-5-0"))
        #expect(output.contains(";10,20 14,20 14,27 10,27 10,20") == false)
    }
}
