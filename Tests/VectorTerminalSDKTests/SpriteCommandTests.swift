import Foundation
import Testing
import VectorTerminalSDK

@MainActor
struct SpriteCommandTests {
    @Test func indexedSpriteUploadEmitsPaletteDataPayload() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)

        canvas.uploadSprite(
            id: "basicship",
            width: 4,
            height: 2,
            pixels: [0, 1, 2, 0, 1, 2, 1, 0],
            palette: ["#000000", .cyan, .red],
            transparentIndex: 0
        )

        #expect(output.text.contains("\u{1B}_VTG;spriteDataUpload,id=basicship,width=4,height=2,palette=#000000|#5eead4|#fb7185,transparent=0,filter=nearest;0,1,2,0,1,2,1,0\u{1B}\\"))
    }

    @Test func bitmapSpriteUploadCanRequestNearestFiltering() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)

        canvas.uploadSprite(id: "pixelship", width: 2, height: 2, pngData: Data([1, 2, 3]), filter: .nearest)

        #expect(output.text.contains("\u{1B}_VTG;spriteUpload,id=pixelship,format=png,width=2,height=2,filter=nearest;AQID\u{1B}\\"))
    }

    @Test func indexedSpriteUploadRejectsMalformedInputBeforeSending() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)

        canvas.uploadSprite(id: "bad-id", width: 2, height: 2, pixels: [0, 1, 1, 0], palette: [.cyan])
        canvas.uploadSprite(id: "short", width: 2, height: 2, pixels: [0, 1, 1], palette: [.cyan])
        canvas.uploadSprite(id: "nopalette", width: 2, height: 2, pixels: [0, 1, 1, 0], palette: [])

        #expect(output.text.isEmpty)
    }
}
