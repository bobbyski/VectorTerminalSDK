import Foundation
import VectorTerminalSDK

@MainActor
final class EnabledCanvasHarness {
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

        let response = "\u{1B}_VTG;capabilities,protocol=VTG,schema=vtg.capabilities.v1,version=1.5.0,canvasWidth=80,canvasHeight=40\u{1B}\\"
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
