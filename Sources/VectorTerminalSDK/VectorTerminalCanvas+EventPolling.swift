import Foundation

extension VectorTerminalCanvas {
    /// Synchronous event poller for frame-loop based applications.
    ///
    /// VectorTank uses this to drain all currently available input each frame.
    /// A zero timeout means "do not block"; a positive timeout waits for input
    /// up to that many milliseconds.
    public func readEvent(timeoutMilliseconds: Int = 0) -> VectorTerminalEvent? {
        var reader = TerminalInputReader(input)
        let deadline = Date().addingTimeInterval(Double(timeoutMilliseconds) / 1000)

        while true {
            let remaining: Int32
            if timeoutMilliseconds <= 0 {
                remaining = 0
            } else {
                remaining = Int32(max(0, Int(deadline.timeIntervalSinceNow * 1000)))
            }

            let result = reader.wait(timeoutMilliseconds: remaining)
            if result <= 0 {
                return nil
            }

            guard var byte = reader.readByte() else {
                return nil
            }

            if byte != 0x1b {
                return .key(byte)
            }

            var escapeBuffer = [byte]
            while !isCompleteEscape(escapeBuffer) {
                if escapeBuffer.count > 8192 {
                    return nil
                }
                let nextTimeout: Int32
                if timeoutMilliseconds <= 0 {
                    nextTimeout = 1
                } else {
                    nextTimeout = Int32(max(1, Int(deadline.timeIntervalSinceNow * 1000)))
                }
                let nextResult = reader.wait(timeoutMilliseconds: nextTimeout)
                if nextResult <= 0 {
                    return nil
                }
                guard let next = reader.readByte() else {
                    return nil
                }
                byte = next
                escapeBuffer.append(byte)
            }
            if let event = parseEscapeEvent(escapeBuffer) {
                return event
            }
            if timeoutMilliseconds > 0 && Date() >= deadline {
                return nil
            }
        }
    }
}
