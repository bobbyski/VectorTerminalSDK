import Foundation
import VectorTerminalSDK

final class CapturingOutput: VTGOutput {
    private(set) var data = Data()

    var text: String {
        String(decoding: data, as: UTF8.self)
    }

    func write(_ data: Data) {
        self.data.append(data)
    }
}
