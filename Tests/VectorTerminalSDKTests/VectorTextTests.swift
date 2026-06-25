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
}
