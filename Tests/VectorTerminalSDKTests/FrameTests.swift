import Foundation
import Testing
import VectorTerminalSDK

struct FrameTests {
    @Test func frameCommandsAreEmittedThroughCanvas() throws {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)

        canvas.startFrame(id: "frame1", timeoutMilliseconds: 500)
        canvas.rect(id: "card", x: 10, y: 20, width: 30, height: 40, stroke: .green)
        canvas.endFrame(id: "frame1")

        #expect(output.text.contains("\u{1B}_VTG;startFrame,id=frame1,timeout=500\u{1B}\\"))
        #expect(output.text.contains("\u{1B}_VTG;rect,id=card,x=10,y=20,w=30,h=40"))
        #expect(output.text.contains("\u{1B}_VTG;endFrame,id=frame1\u{1B}\\"))
    }

    @Test func withFrameCancelsWhenBodyThrows() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)

        #expect(throws: FrameTestError.self) {
            try canvas.withFrame(id: "frame1") {
                canvas.line(id: "axis", x1: 0, y1: 0, x2: 10, y2: 10)
                throw FrameTestError.failed
            }
        }

        #expect(output.text.contains("\u{1B}_VTG;startFrame,id=frame1,timeout=250\u{1B}\\"))
        #expect(output.text.contains("\u{1B}_VTG;line,id=axis"))
        #expect(output.text.contains("\u{1B}_VTG;cancelFrame,id=frame1\u{1B}\\"))
        #expect(!output.text.contains("\u{1B}_VTG;endFrame,id=frame1\u{1B}\\"))
    }

    @Test func frameCommandsIgnoreInvalidIDsAndClampTimeout() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)

        canvas.startFrame(id: "bad-id!", timeoutMilliseconds: 500)
        canvas.endFrame(id: "bad-id!")
        canvas.cancelFrame(id: "bad-id!")

        #expect(output.text.isEmpty)

        canvas.startFrame(id: "frame1", timeoutMilliseconds: -50)

        #expect(output.text == "\u{1B}_VTG;startFrame,id=frame1,timeout=1\u{1B}\\")
    }

}

private enum FrameTestError: Error {
    case failed
}
