#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
// Static Linux (the musl SDK): the same C library under its own module name.
import Musl
#endif
import Foundation

/// Low-level APC response transport used by synchronous VTG queries.
extension VectorTerminalCanvas {
    func readAPCResponse(timeoutMilliseconds: Int, limit: Int = 8192) -> [UInt8]? {
        var reader = TerminalInputReader(input)
        var collected: [UInt8] = []
        let deadline = Date().addingTimeInterval(Double(timeoutMilliseconds) / 1000)

        while Date() < deadline {
            let remaining = max(1, Int(deadline.timeIntervalSinceNow * 1000))
            let result = reader.wait(timeoutMilliseconds: Int32(remaining))
            if result <= 0 {
                break
            }

            guard let byte = reader.readByte() else {
                continue
            }
            collected.append(byte)
            if collected.count >= 2,
               collected[collected.count - 2] == 0x1b,
               collected[collected.count - 1] == UInt8(ascii: "\\") {
                return collected
            }
            if collected.count > limit {
                return collected
            }
        }

        return collected.isEmpty ? nil : collected
    }
}
