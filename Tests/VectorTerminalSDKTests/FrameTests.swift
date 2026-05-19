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

    @Test func rectCommandIncludesOptionalCornerRadius() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)

        canvas.rect(id: "rounded", x: 10, y: 20, width: 30, height: 40, stroke: .green, fill: "#22c55e33", lineWidth: 2, radius: 12)
        canvas.rect(id: "sharp", x: 50, y: 60, width: 70, height: 80, stroke: .cyan)

        #expect(output.text.contains("\u{1B}_VTG;rect,id=rounded,x=10,y=20,w=30,h=40,stroke=#22c55e,fill=#22c55e33,width=2,radius=12\u{1B}\\"))
        #expect(output.text.contains("\u{1B}_VTG;rect,id=sharp,x=50,y=60,w=70,h=80,stroke=#5eead4,fill=none,width=1\u{1B}\\"))
        #expect(!output.text.contains("id=sharp,x=50,y=60,w=70,h=80,stroke=#5eead4,width=1,radius"))
    }

    @Test func triangleCommandIncludesOptionalCornerRadius() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)

        canvas.triangle(
            id: "rounded-tri",
            p1: VTGPoint(x: 10, y: 80),
            p2: VTGPoint(x: 90, y: 80),
            p3: VTGPoint(x: 50, y: 10),
            stroke: .white,
            fill: "#3b82f655",
            lineWidth: 3,
            radius: 14
        )
        canvas.triangle(
            id: "sharp-tri",
            p1: VTGPoint(x: 1, y: 2),
            p2: VTGPoint(x: 3, y: 4),
            p3: VTGPoint(x: 5, y: 6)
        )

        #expect(output.text.contains("\u{1B}_VTG;triangle,id=rounded-tri,x1=10,y1=80,x2=90,y2=80,x3=50,y3=10,stroke=#f8fafc,fill=#3b82f655,width=3,radius=14\u{1B}\\"))
        #expect(output.text.contains("\u{1B}_VTG;triangle,id=sharp-tri,x1=1,y1=2,x2=3,y2=4,x3=5,y3=6,stroke=#f8fafc,fill=none,width=1\u{1B}\\"))
        #expect(!output.text.contains("id=sharp-tri,x1=1,y1=2,x2=3,y2=4,x3=5,y3=6,stroke=#f8fafc,fill=none,width=1,radius"))
    }

    @Test func drawingCommandsIncludeOptionalStrokePaintStyle() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)

        canvas.draw(
            id: "styled",
            points: [VTGPoint(x: 0, y: 0), VTGPoint(x: 10, y: 10), VTGPoint(x: 20, y: 0)],
            stroke: .green,
            width: 4,
            lineCap: .square,
            lineJoin: .bevel
        )
        canvas.path(
            id: "plain",
            payload: "M 0 0 L 10 10",
            stroke: .cyan
        )

        #expect(output.text.contains("\u{1B}_VTG;draw,id=styled,stroke=#22c55e,width=4,lineCap=square,lineJoin=bevel;0,0 10,10 20,0\u{1B}\\"))
        #expect(output.text.contains("\u{1B}_VTG;path,id=plain,stroke=#5eead4,fill=none,width=1;M 0 0 L 10 10\u{1B}\\"))
        #expect(!output.text.contains("id=plain,stroke=#5eead4,fill=none,width=1,lineCap"))
    }
}

private enum FrameTestError: Error {
    case failed
}

private final class CapturingOutput: VTGOutput {
    private(set) var data = Data()

    var text: String {
        String(decoding: data, as: UTF8.self)
    }

    func write(_ data: Data) {
        self.data.append(data)
    }
}
