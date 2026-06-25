import Foundation
import VectorTerminalSDK

@MainActor
final class EventHarness {
    private let inputPipe = Pipe()
    private let outputPipe = Pipe()
    let canvas: VectorTerminalCanvas

    init() {
        canvas = .noOp(
            input: inputPipe.fileHandleForReading,
            output: outputPipe.fileHandleForWriting
        )
    }

    func write(_ value: String) {
        write(Array(value.utf8))
    }

    func write(_ bytes: [UInt8]) {
        inputPipe.fileHandleForWriting.write(Data(bytes))
    }

    func close() {
        try? inputPipe.fileHandleForReading.close()
        try? inputPipe.fileHandleForWriting.close()
        try? outputPipe.fileHandleForReading.close()
        try? outputPipe.fileHandleForWriting.close()
    }
}
