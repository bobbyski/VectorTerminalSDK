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
        var pollFD = pollfd(fd: input.fileDescriptor, events: Int16(POLLIN), revents: 0)
        var collected: [UInt8] = []
        let deadline = Date().addingTimeInterval(Double(timeoutMilliseconds) / 1000)

        while Date() < deadline {
            let remaining = max(1, Int(deadline.timeIntervalSinceNow * 1000))
            let result = poll(&pollFD, 1, Int32(remaining))
            if result <= 0 {
                break
            }

            var byte: UInt8 = 0
            guard read(input.fileDescriptor, &byte, 1) == 1 else {
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
