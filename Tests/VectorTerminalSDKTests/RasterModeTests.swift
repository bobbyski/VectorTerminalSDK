import Foundation
import Testing
import VectorTerminalSDK

struct RasterModeTests {
    @Test func rasterModeIsOneCommandEachWay() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)

        canvas.enterRasterMode()
        canvas.leaveRasterMode()

        #expect(output.text == "\u{1B}_VTG;rasterMode,on=1\u{1B}\\\u{1B}_VTG;rasterMode,on=0\u{1B}\\")
    }

    /// Nothing else about the protocol changes: the same drawing command, with
    /// its id, is sent in either mode.
    @Test func drawingCommandsAreUnchangedInRasterMode() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)

        canvas.line(id: "beam", x1: 0, y1: 0, x2: 10, y2: 10, stroke: .green)
        let retained = output.text
        output.reset()

        canvas.enterRasterMode()
        output.reset()
        canvas.line(id: "beam", x1: 0, y1: 0, x2: 10, y2: 10, stroke: .green)

        #expect(output.text == retained)
    }

    @Test func repeatedSwitchesSendNothingAndTheFlagFollows() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)

        #expect(!canvas.isInRasterMode)
        canvas.enterRasterMode()
        #expect(canvas.isInRasterMode)
        output.reset()
        canvas.enterRasterMode()
        canvas.setRasterMode(true)
        #expect(output.text.isEmpty)

        canvas.leaveRasterMode()
        #expect(!canvas.isInRasterMode)
        #expect(output.text == "\u{1B}_VTG;rasterMode,on=0\u{1B}\\")
    }
}
