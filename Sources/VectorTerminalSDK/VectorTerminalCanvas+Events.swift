import Foundation

extension VectorTerminalCanvas {
    /// Stream keyboard, mouse, resize, and canvas events.
    ///
    /// The stream periodically sends a capabilities query so apps that cannot
    /// rely on resize push events still learn about canvas changes.
    public func events(canvasPollInterval: TimeInterval = 0.5) -> AsyncStream<VectorTerminalEvent> {
        AsyncStream { continuation in
            let inputFD = input.fileDescriptor
            let canvas = self
            let task = Task.detached {
                var escapeBuffer: [UInt8] = []
                var collectingEscape = false
                var lastCanvasPoll = Date.distantPast

                while !Task.isCancelled {
                    var pollFD = pollfd(fd: inputFD, events: Int16(POLLIN), revents: 0)
                    let result = poll(&pollFD, 1, 100)

                    if result <= 0 {
                        if Date().timeIntervalSince(lastCanvasPoll) >= canvasPollInterval {
                            // Polling is a compatibility fallback. Native resize
                            // events are preferred, but older/debug builds may
                            // only answer explicit capability queries.
                            canvas.send("capabilities?")
                            lastCanvasPoll = Date()
                        }
                        continue
                    }

                    var byte: UInt8 = 0
                    guard read(inputFD, &byte, 1) == 1 else {
                        continue
                    }

                    if collectingEscape || byte == 0x1b {
                        collectingEscape = true
                        escapeBuffer.append(byte)
                        if canvas.isCompleteEscape(escapeBuffer) {
                            if let event = canvas.parseEscapeEvent(escapeBuffer) {
                                continuation.yield(event)
                            }
                            escapeBuffer.removeAll(keepingCapacity: true)
                            collectingEscape = false
                        } else if escapeBuffer.count > 8192 {
                            // Guard against malformed control strings consuming
                            // the entire input stream forever.
                            escapeBuffer.removeAll(keepingCapacity: true)
                            collectingEscape = false
                        }
                        continue
                    }

                    continuation.yield(.key(byte))
                }

                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// Synchronous event poller for frame-loop based applications.
    ///
    /// VectorTank uses this to drain all currently available input each frame.
    /// A zero timeout means "do not block"; a positive timeout waits for input
    /// up to that many milliseconds.
    public func readEvent(timeoutMilliseconds: Int = 0) -> VectorTerminalEvent? {
        var pollFD = pollfd(fd: input.fileDescriptor, events: Int16(POLLIN), revents: 0)
        let deadline = Date().addingTimeInterval(Double(timeoutMilliseconds) / 1000)

        while true {
            let remaining: Int32
            if timeoutMilliseconds <= 0 {
                remaining = 0
            } else {
                remaining = Int32(max(0, Int(deadline.timeIntervalSinceNow * 1000)))
            }

            let result = poll(&pollFD, 1, remaining)
            if result <= 0 {
                return nil
            }

            var byte: UInt8 = 0
            guard read(input.fileDescriptor, &byte, 1) == 1 else {
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
                let nextResult = poll(&pollFD, 1, nextTimeout)
                if nextResult <= 0 {
                    return nil
                }
                guard read(input.fileDescriptor, &byte, 1) == 1 else {
                    return nil
                }
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
