import Foundation
import Testing
import VectorTerminalSDK

/// Key down and up from a terminal that reports them (VGT-11).
struct KeyEventTests {
    private func reply(_ body: String) -> String {
        "\u{1B}_VTG;\(body)\u{1B}\\"
    }

    @Test func subscribingSendsTheCommand() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)
        canvas.enableKeyEvents()
        canvas.enableKeyEvents(repeats: true)
        canvas.disableKeyEvents()
        #expect(output.text == reply("keyEvents,enabled=1") + reply("keyEvents,enabled=1,repeat=1") + reply("keyEvents,enabled=0"))
    }

    @Test func keyMessagesReachTheHandlerAndNotTheEventStream() {
        let harness = EventHarness()
        defer { harness.close() }
        var keys: [VTGKeyEvent] = []
        harness.canvas.keyEventHandler = { keys.append($0) }

        harness.write(reply("key,type=down,key=LEFT,mods=none"))
        harness.write(reply("key,type=down,key=CHAR,char=49,text=33,mods=shift"))
        harness.write(reply("key,type=up,key=LEFT,reason=focus,mods=none"))
        harness.write("q")

        #expect(harness.canvas.readEvent(timeoutMilliseconds: 100) == .key(UInt8(ascii: "q")))
        #expect(keys.map(\.kind) == [.down, .down, .up])
        #expect(keys[0].key == "LEFT")
        #expect(keys[1].key == "CHAR" && keys[1].character == "1" && keys[1].text == "!" && keys[1].modifiers == "shift")
        #expect(keys[2].lostFocus)
    }
}
