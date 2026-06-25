import Foundation
import Testing
import VectorTerminalSDK

@MainActor
struct CanvasCommandTests {
    private let esc = "\u{1B}"

    @Test func layerCommandsUseCanonicalLayerParameter() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        harness.canvas.setDefaultLayer(VTGLayer.overlay3)
        harness.canvas.defaultLayer = VTGLayer.overlay4
        harness.canvas.defaultLayer = 99
        harness.canvas.setLayer(id: "ship1", layer: VTGLayer.overlay4)
        harness.canvas.delete(id: "ship1")

        let output = harness.output()
        #expect(output.contains("\(esc)_VTG;defaultLayer,layer=3\(esc)\\"))
        #expect(output.contains("\(esc)_VTG;defaultLayer,layer=4\(esc)\\"))
        #expect(output.contains("\(esc)_VTG;layer,id=ship1,layer=4\(esc)\\"))
        #expect(output.contains("\(esc)_VTG;delete,id=ship1\(esc)\\"))
        #expect(harness.canvas.defaultLayer == VTGLayer.overlay4)
        #expect(!output.contains("defaultLayer,layer=99"))
        #expect(!output.contains("defaultLayer,value="))
        #expect(!output.contains("layer,id=ship1,value="))
    }

    @Test func viewportCommandsUseOverlayLayerParameters() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        harness.canvas.setViewportMode(layer: VTGLayer.overlay2, width: 320, height: 200, scale: .integer)
        harness.canvas.setViewportScale(layer: VTGLayer.overlay2, scale: 2, x: 10, y: 20)
        harness.canvas.clearViewportMode(layer: VTGLayer.overlay2)
        harness.canvas.setViewportMode(layer: VTGLayer.textPlane, width: 320, height: 200)

        let output = harness.output()
        #expect(output.contains("\(esc)_VTG;viewportMode,layer=2,width=320,height=200,scale=integer\(esc)\\"))
        #expect(output.contains("\(esc)_VTG;viewportScale,layer=2,scale=2,x=10,y=20\(esc)\\"))
        #expect(output.contains("\(esc)_VTG;viewportMode,layer=2,value=native\(esc)\\"))
        #expect(!output.contains("viewportMode,layer=0"))
    }

    @Test func hostValidatedCanvasWritesThroughClosureOutput() {
        var bytes = Data()
        let output = ClosureVTGOutput { data in
            bytes.append(data)
        }
        let canvas = VectorTerminalCanvas.hostValidated(output: output)

        canvas.rect(id: "host-rect", x: 1, y: 2, width: 3, height: 4, stroke: .green)
        canvas.writeText("host text")

        let emitted = String(bytes: bytes, encoding: .utf8) ?? ""
        #expect(emitted.contains("\(esc)_VTG;rect,id=host-rect"))
        #expect(emitted.contains("x=1,y=2,w=3,h=4"))
        #expect(emitted.contains("host text"))
    }

    @Test func querySizeUsesLegacyVTGSizeCommand() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        harness.writeInput("\(esc)_VTG;size,width=640,height=480\(esc)\\")
        let size = harness.canvas.querySize(timeoutMilliseconds: 50)

        #expect(size == VTGCanvas(
            width: 640,
            height: 480,
            source: "size?",
            rawResponse: "\(esc)_VTG;size,width=640,height=480\(esc)\\"
        ))
        #expect(harness.output().contains("\(esc)_VTG;size?\(esc)\\"))
    }
}
