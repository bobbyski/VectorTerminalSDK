import Foundation
import Testing
import VectorTerminalSDK

@MainActor
struct RasterCommandTests {
    @Test func imageCommandCanRequestNearestFiltering() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)

        canvas.image(
            id: "retro",
            x: 4,
            y: 5,
            width: 32,
            height: 24,
            pngData: Data([1, 2, 3]),
            filter: .nearest,
            layer: VTGLayer.overlay2
        )

        #expect(output.text.contains("\u{1B}_VTG;image,id=retro,format=png,x=4,y=5,width=32,height=24,filter=nearest,layer=2;AQID\u{1B}\\"))
    }
}
