import Foundation
import Testing
import VectorTerminalSDK

@MainActor
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

        harness.write("\(esc)_VTG;mouse,type=scroll,button=5,x=412,y=318,cellX=42,cellY=17,scrollX=0,scrollY=-3,viewportLayer=4,virtualX=120,virtualY=80,mods=shift|ctrl,hit=quit,target=quitButton\(esc)\\")

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
        #expect(mouse.viewportLayer == 4)
        #expect(mouse.virtualX == 120)
        #expect(mouse.virtualY == 80)
        #expect(mouse.modifiers == "shift|ctrl")
        #expect(mouse.hitID == "quit")
        #expect(mouse.targetID == "quitButton")
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
}
