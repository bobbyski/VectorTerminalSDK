import Foundation
import Testing
import VectorTerminalSDK

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

    private final class EnabledCanvasHarness {
        private let inputPipe = Pipe()
        private let outputURL: URL
        private let outputReadHandle: FileHandle
        private let outputWriteHandle: FileHandle
        let canvas: VectorTerminalCanvas

        init() throws {
            outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("VectorTerminalSDK-\(UUID().uuidString).log")
            FileManager.default.createFile(atPath: outputURL.path, contents: Data())
            outputReadHandle = try FileHandle(forReadingFrom: outputURL)
            outputWriteHandle = try FileHandle(forWritingTo: outputURL)

            let response = "\u{1B}_VTG;capabilities,protocol=VTG,schema=vtg.capabilities.v1,version=0.1,canvasWidth=80,canvasHeight=40\u{1B}\\"
            inputPipe.fileHandleForWriting.write(Data(response.utf8))
            canvas = try VectorTerminalCanvas(
                input: inputPipe.fileHandleForReading,
                output: outputWriteHandle,
                timeoutMilliseconds: 50
            )
        }

        func writeInput(_ value: String) {
            inputPipe.fileHandleForWriting.write(Data(value.utf8))
        }

        func output() -> String {
            outputWriteHandle.synchronizeFile()
            try? outputReadHandle.seek(toOffset: 0)
            let data = outputReadHandle.readDataToEndOfFile()
            return String(bytes: data, encoding: .utf8) ?? ""
        }

        func close() {
            try? inputPipe.fileHandleForReading.close()
            try? inputPipe.fileHandleForWriting.close()
            try? outputReadHandle.close()
            try? outputWriteHandle.close()
            try? FileManager.default.removeItem(at: outputURL)
        }
    }
}
