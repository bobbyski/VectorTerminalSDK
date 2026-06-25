import Testing
import VectorTerminalSDK

struct ShapeCommandTests {
    @Test func clearRectCommandClearsRetainedRegion() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)

        canvas.clearRect(id: "erase1", x: 10, y: 20, width: 30, height: 40, layer: VTGLayer.overlay2)
        canvas.clearRect(id: "clock-clear", x: 100, y: 120, width: 300, height: 80)

        #expect(output.text.contains("\u{1B}_VTG;clearRect,id=erase1,x=10,y=20,w=30,h=40,layer=2\u{1B}\\"))
        #expect(output.text.contains("\u{1B}_VTG;clearRect,id=clock-clear,x=100,y=120,w=300,h=80\u{1B}\\"))
    }

    @Test func rectCommandIncludesOptionalCornerRadius() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)

        canvas.rect(id: "rounded", x: 10, y: 20, width: 30, height: 40, stroke: .green, fill: "#22c55e33", lineWidth: 2, radius: 12, corners: "12421")
        canvas.rect(id: "sharp", x: 50, y: 60, width: 70, height: 80, stroke: .cyan)

        #expect(output.text.contains("\u{1B}_VTG;rect,id=rounded,x=10,y=20,w=30,h=40,stroke=#22c55e,fill=#22c55e33,width=2,radius=12,corners=124\u{1B}\\"))
        #expect(output.text.contains("\u{1B}_VTG;rect,id=sharp,x=50,y=60,w=70,h=80,stroke=#5eead4,fill=none,width=1\u{1B}\\"))
        #expect(!output.text.contains("id=sharp,x=50,y=60,w=70,h=80,stroke=#5eead4,width=1,radius"))
        #expect(!output.text.contains("id=sharp,x=50,y=60,w=70,h=80,stroke=#5eead4,width=1,corners"))
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
