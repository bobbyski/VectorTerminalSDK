import Foundation
import Testing
import VectorTerminalSDK

struct EventParsingTests {
    private let esc = "\u{1B}"

    @Test func readEventParsesSpecialKeys() throws {
        let harness = EventHarness()
        defer { harness.close() }

        harness.write("\(esc)[A")
        #expect(harness.canvas.readEvent(timeoutMilliseconds: 50) == .specialKey(.up))

        harness.write("\(esc)OD")
        #expect(harness.canvas.readEvent(timeoutMilliseconds: 50) == .specialKey(.left))
    }

    @Test func readEventParsesVTGMouseWithPixelCellScrollAndHitData() throws {
        let harness = EventHarness()
        defer { harness.close() }

        harness.write("\(esc)_VTG;mouse,type=scroll,button=5,x=412,y=318,cellX=42,cellY=17,scrollX=0,scrollY=-3,mods=shift|ctrl,hit=quit,target=quitButton\(esc)\\")

        guard case .mouse(let mouse) = harness.canvas.readEvent(timeoutMilliseconds: 50) else {
            Issue.record("Expected VTG mouse event")
            return
        }

        #expect(mouse.type == "scroll")
        #expect(mouse.button == 5)
        #expect(mouse.x == 412)
        #expect(mouse.y == 318)
        #expect(mouse.cellX == 42)
        #expect(mouse.cellY == 17)
        #expect(mouse.scrollX == 0)
        #expect(mouse.scrollY == -3)
        #expect(mouse.modifiers == "shift|ctrl")
        #expect(mouse.hitID == "quit")
        #expect(mouse.targetID == "quitButton")
    }

    @Test func readEventParsesCanvasResponses() throws {
        let harness = EventHarness()
        defer { harness.close() }

        harness.write("\(esc)_VTG;resize,width=1200,height=900\(esc)\\")
        #expect(harness.canvas.readEvent(timeoutMilliseconds: 50) == .resize(VTGCanvas(
            width: 1200,
            height: 900,
            source: "resize",
            rawResponse: "\(esc)_VTG;resize,width=1200,height=900\(esc)\\"
        )))

        harness.write("\(esc)_VTG;capabilities,protocol=VTG,schema=vtg.capabilities.v1,version=0.1,canvasWidth=1440,canvasHeight=1000\(esc)\\")
        #expect(harness.canvas.readEvent(timeoutMilliseconds: 50) == .canvas(VTGCanvas(
            width: 1440,
            height: 1000,
            source: "capabilities",
            rawResponse: "\(esc)_VTG;capabilities,protocol=VTG,schema=vtg.capabilities.v1,version=0.1,canvasWidth=1440,canvasHeight=1000\(esc)\\"
        )))
    }

    @Test func readEventParsesLargeSGRMouseCoordinatesAsSingleEvent() throws {
        let harness = EventHarness()
        defer { harness.close() }

        harness.write("\(esc)[<0;1569;957M")

        guard case .mouse(let mouse) = harness.canvas.readEvent(timeoutMilliseconds: 50) else {
            Issue.record("Expected SGR mouse event")
            return
        }

        #expect(mouse.type == "down")
        #expect(mouse.button == 0)
        #expect(mouse.x == 1569)
        #expect(mouse.y == 957)
        #expect(mouse.isPress)
    }

    @Test func readEventParsesX10MouseReports() throws {
        let harness = EventHarness()
        defer { harness.close() }

        harness.write([0x1B, UInt8(ascii: "["), UInt8(ascii: "M"), 32, 42, 52])

        guard case .mouse(let mouse) = harness.canvas.readEvent(timeoutMilliseconds: 50) else {
            Issue.record("Expected X10 mouse event")
            return
        }

        #expect(mouse.type == "down")
        #expect(mouse.button == 0)
        #expect(mouse.x == 10)
        #expect(mouse.y == 20)
    }

    private final class EventHarness {
        private let inputPipe = Pipe()
        private let outputPipe = Pipe()
        let canvas: VectorTerminalCanvas

        init() {
            canvas = .noOp(
                input: inputPipe.fileHandleForReading,
                output: outputPipe.fileHandleForWriting
            )
        }

        func write(_ value: String) {
            write(Array(value.utf8))
        }

        func write(_ bytes: [UInt8]) {
            inputPipe.fileHandleForWriting.write(Data(bytes))
        }

        func close() {
            try? inputPipe.fileHandleForReading.close()
            try? inputPipe.fileHandleForWriting.close()
            try? outputPipe.fileHandleForReading.close()
            try? outputPipe.fileHandleForWriting.close()
        }
    }
}
