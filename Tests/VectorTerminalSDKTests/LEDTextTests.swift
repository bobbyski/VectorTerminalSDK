import Testing
import VectorTerminalSDK

struct LEDTextTests {
    private let esc = "\u{1B}"

    @Test func ledTextSizeMatchesLEDPrintAdvance() {
        #expect(VectorTerminalCanvas.ledTextSize(height: 16, value: "") == VTGTextSize(width: 0, height: 16))
        #expect(VectorTerminalCanvas.ledTextSize(height: 16, value: "A") == VTGTextSize(width: 12, height: 16))
        #expect(VectorTerminalCanvas.ledTextSize(height: 32, value: "AB C") == VTGTextSize(width: 96, height: 32))
    }

    @Test func ledTextSizeUsesMinimumGlyphHeight() {
        #expect(VectorTerminalCanvas.ledTextSize(height: 1, value: "AB") == VTGTextSize(width: 24, height: 16))
    }

    @Test func ledPrintDrawsOnlyLitSegmentsByDefault() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        harness.canvas.ledPrint(id: "led", x: 10, y: 20, height: 16, value: "A", color: "#B7FF2AFF")

        let output = harness.output()
        #expect(output.contains("\(esc)_VTG;path,id=led-0-a,stroke=none,fill=#B7FF2AFF,width=1,lineJoin=round"))
        #expect(output.contains("id=led-0-b"))
        #expect(output.contains("id=led-0-c"))
        #expect(output.contains("id=led-0-e"))
        #expect(output.contains("id=led-0-f"))
        #expect(output.contains("id=led-0-g"))
        #expect(output.contains("id=led-0-d") == false)
        #expect(output.contains("id=led-0-h") == false)
    }

    @Test func ledPrintCanDrawInactiveSegments() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        harness.canvas.ledPrint(
            id: "led",
            x: 10,
            y: 20,
            height: 16,
            value: "1",
            color: "#B7FF2AFF",
            inactiveColor: "#10201866"
        )

        let output = harness.output()
        #expect(output.contains("id=led-0-b,stroke=none,fill=#B7FF2AFF"))
        #expect(output.contains("id=led-0-c,stroke=none,fill=#B7FF2AFF"))
        #expect(output.contains("id=led-0-a,stroke=none,fill=#10201866"))
        #expect(output.contains("id=led-0-m,stroke=none,fill=#10201866"))
    }

    @Test func ledColonDrawsOnlyTwoDotsByDefault() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        harness.canvas.ledPrint(id: "led", x: 10, y: 20, height: 16, value: ":", color: "#B7FF2AFF")

        let output = harness.output()
        #expect(output.contains("id=led-0-n,stroke=none,fill=#B7FF2AFF"))
        #expect(output.contains("id=led-0-o,stroke=none,fill=#B7FF2AFF"))
        #expect(output.contains("id=led-0-a") == false)
        #expect(output.contains("id=led-0-g") == false)
    }

    @Test func ledBVWUseRequestedSegments() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        harness.canvas.ledPrint(id: "led", x: 10, y: 20, height: 16, value: "BVW", color: "#B7FF2AFF")

        let output = harness.output()
        #expect(output.contains("id=led-0-c"))
        #expect(output.contains("id=led-0-d"))
        #expect(output.contains("id=led-0-e"))
        #expect(output.contains("id=led-0-f"))
        #expect(output.contains("id=led-0-g"))
        #expect(output.contains("id=led-0-a") == false)
        #expect(output.contains("id=led-0-b") == false)
        #expect(output.contains("id=led-1-f"))
        #expect(output.contains("id=led-1-e"))
        #expect(output.contains("id=led-1-k"))
        #expect(output.contains("id=led-1-l"))
        #expect(output.contains("id=led-1-b") == false)
        #expect(output.contains("id=led-1-c") == false)
        #expect(output.contains("id=led-1-m") == false)
        #expect(output.contains("id=led-2-f"))
        #expect(output.contains("id=led-2-e"))
        #expect(output.contains("id=led-2-l"))
        #expect(output.contains("id=led-2-m"))
        #expect(output.contains("id=led-2-b"))
        #expect(output.contains("id=led-2-c"))
        #expect(output.contains("id=led-2-d") == false)
    }

    @Test func canvasInstanceLEDTextSizeDelegatesToStaticHelper() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        #expect(harness.canvas.ledTextSize(height: 24, value: "VTG") == VTGTextSize(width: 54, height: 24))
    }

    @Test func deleteLEDTextDeletesRememberedSegments() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        harness.canvas.ledPrint(id: "led", x: 10, y: 20, height: 16, value: "1", color: "#B7FF2AFF")
        harness.canvas.deleteLEDText(id: "led")

        let output = harness.output()
        #expect(output.contains("_VTG;path,id=led-0-b"))
        #expect(output.contains("_VTG;path,id=led-0-c"))
        #expect(output.contains("_VTG;delete,id=led-0-b"))
        #expect(output.contains("_VTG;delete,id=led-0-c"))
    }

    @Test func deleteLCDTextAliasesLEDTextCleanup() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        harness.canvas.ledPrint(id: "lcd", x: 10, y: 20, height: 16, value: "1", color: "#B7FF2AFF")
        harness.canvas.deleteLCDText(id: "lcd")

        let output = harness.output()
        #expect(output.contains("_VTG;delete,id=lcd-0-b"))
        #expect(output.contains("_VTG;delete,id=lcd-0-c"))
    }

    @Test func ledPrintDeletesPreviousChildrenBeforeRedraw() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        harness.canvas.ledPrint(id: "led", x: 10, y: 20, height: 16, value: "8", color: "#B7FF2AFF")
        harness.canvas.ledPrint(id: "led", x: 10, y: 20, height: 16, value: "1", color: "#B7FF2AFF")

        let output = harness.output()
        #expect(output.contains("_VTG;delete,id=led-0-a"))
        #expect(output.contains("_VTG;delete,id=led-0-g"))
        #expect(output.contains("_VTG;path,id=led-0-b"))
    }
}
