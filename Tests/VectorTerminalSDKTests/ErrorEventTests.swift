import Foundation
import Testing
import VectorTerminalSDK

/// Being told when a sprite command is refused: by the terminal, after
/// `enableErrorEvents()`, and by the SDK when it will not send one.
struct ErrorEventTests {
    private func reply(_ body: String) -> String {
        "\u{1B}_VTG;\(body)\u{1B}\\"
    }

    @Test func enablingAndDisablingSendTheSubscription() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)
        canvas.enableErrorEvents()
        canvas.disableErrorEvents()
        #expect(output.text == reply("errorEvents,enabled=1") + reply("errorEvents,enabled=0"))
    }

    @Test func theTerminalsRefusalReachesTheHandlerAndNotTheEventStream() {
        let harness = EventHarness()
        defer { harness.close() }
        var refusals: [VTGCommandRejection] = []
        harness.canvas.commandRejectedHandler = { refusals.append($0) }

        harness.write(reply("commandRejected,command=spriteUpload,id=ship,reason=limit"))
        harness.write("q")

        #expect(harness.canvas.readEvent(timeoutMilliseconds: 100) == .key(UInt8(ascii: "q")))
        #expect(refusals == [VTGCommandRejection(command: "spriteUpload", id: "ship", reason: "limit", fromTerminal: true)])
    }

    @Test func theSDKSaysWhatItWouldNotSend() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)
        var refusals: [VTGCommandRejection] = []
        canvas.commandRejectedHandler = { refusals.append($0) }

        canvas.uploadSprite(id: "bad$id", width: 1, height: 1, pngData: Data([1]))
        canvas.uploadSprite(id: "short", width: 2, height: 2, pixels: [0, 1, 1], palette: [.cyan])
        canvas.uploadSprite(id: "flat", width: 0, height: 2, pixels: [], palette: [.cyan])
        canvas.uploadSprite(id: "nopalette", width: 1, height: 1, pixels: [0], palette: [])
        canvas.sprite(id: "ship1", imageID: "bad$image", x: 0, y: 0)

        #expect(output.text.isEmpty, "nothing refused was sent")
        #expect(refusals.map(\.reason) == ["badId", "badData", "badSize", "badPalette", "unknownAsset"])
        #expect(refusals.allSatisfy { !$0.fromTerminal })
    }

    @Test func namesWithDashAndUnderscoreAreSent() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)
        var refusals: [VTGCommandRejection] = []
        canvas.commandRejectedHandler = { refusals.append($0) }

        canvas.uploadSprite(id: "player_ship", width: 1, height: 1, pngData: Data([1]))
        canvas.sprite(id: "player-1", imageID: "player_ship", x: 0, y: 0)

        #expect(refusals.isEmpty)
        #expect(output.text.contains("spriteUpload,id=player_ship,"))
        #expect(output.text.contains("sprite,id=player-1,image=player_ship,"))
    }
}
