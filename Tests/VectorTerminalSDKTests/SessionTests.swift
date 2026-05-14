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
        harness.canvas.setLayer(id: "ship1", layer: VTGLayer.overlay4)

        let output = harness.output()
        #expect(output.contains("\(esc)_VTG;defaultLayer,layer=3\(esc)\\"))
        #expect(output.contains("\(esc)_VTG;layer,id=ship1,layer=4\(esc)\\"))
        #expect(!output.contains("defaultLayer,value="))
        #expect(!output.contains("layer,id=ship1,value="))
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
