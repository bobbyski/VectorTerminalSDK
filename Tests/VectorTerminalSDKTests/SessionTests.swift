import Foundation
import Testing
import VectorTerminalSDK

@MainActor
struct SessionTests {
    private let esc = "\u{1B}"

    @Test func sessionStartAndEndEmitLifecycleSequences() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        let session = VectorTerminalSession(
            canvas: harness.canvas,
            options: VectorTerminalSessionOptions(
                useAlternateScreen: true,
                hideCursor: true,
                clearOnStart: true,
                clearOnEnd: true,
                resetTextAttributesOnEnd: true,
                resizeEvents: true,
                mouseMode: "all",
                rawInput: false
            )
        )

        session.start()
        session.end()

        let output = harness.output()
        #expect(output.contains("\(esc)_VTG;capabilities?\(esc)\\"))
        #expect(output.contains("\(esc)[?1049h"))
        #expect(output.contains("\(esc)[?25l"))
        #expect(output.contains("\(esc)[2J"))
        #expect(output.contains("\(esc)_VTG;clear\(esc)\\"))
        #expect(output.contains("\(esc)_VTG;resizeEvents,enabled=1\(esc)\\"))
        #expect(output.contains("\(esc)_VTG;mouseEvents,enabled=1,mode=all\(esc)\\"))
        #expect(output.contains("\(esc)_VTG;mouseEvents,enabled=0\(esc)\\"))
        #expect(output.contains("\(esc)_VTG;resizeEvents,enabled=0\(esc)\\"))
        #expect(output.contains("\(esc)[?1016l"))
        #expect(output.contains("\(esc)[?1015l"))
        #expect(output.contains("\(esc)[?25h"))
        #expect(output.contains("\(esc)[0m"))
        #expect(output.contains("\(esc)[?1049l"))
        #expect(output.range(of: "\(esc)_VTG;mouseEvents,enabled=0\(esc)\\")!.lowerBound < output.range(of: "\(esc)[?1049l")!.lowerBound)
    }

    @Test func sessionEndIsIdempotent() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        let session = VectorTerminalSession(
            canvas: harness.canvas,
            options: VectorTerminalSessionOptions(
                useAlternateScreen: true,
                hideCursor: false,
                clearOnStart: false,
                clearOnEnd: false,
                resetTextAttributesOnEnd: false,
                resizeEvents: false,
                rawInput: false
            )
        )

        session.start()
        session.end()
        session.end()

        let output = harness.output()
        #expect(output.components(separatedBy: "\(esc)[?1049h").count - 1 == 1)
        #expect(output.components(separatedBy: "\(esc)[?1049l").count - 1 == 1)
    }

}
