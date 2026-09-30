import Foundation

extension VectorTerminalCanvas {
    /// Stream keyboard, mouse, resize, and canvas events.
    ///
    /// The stream periodically sends a capabilities query so apps that cannot
    /// rely on resize push events still learn about canvas changes.
    public func events(canvasPollInterval: TimeInterval = 0.5) -> AsyncStream<VectorTerminalEvent> {
        AsyncStream { continuation in
            let input = TerminalInputReader(input)
            let canvas = self
            let task = Task.detached {
                var escapeBuffer: [UInt8] = []
                var collectingEscape = false
                var lastCanvasPoll = Date.distantPast
                var reader = input

                while !Task.isCancelled {
                    let result = reader.wait(timeoutMilliseconds: 100)

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

                    guard let byte = reader.readByte() else {
                        continue
                    }

                    if collectingEscape || byte == 0x1b {
                        collectingEscape = true
                        escapeBuffer.append(byte)
                        let escapeSnapshot = escapeBuffer
                        let isComplete = canvas.isCompleteEscape(escapeSnapshot)
                        if isComplete {
                            let event = canvas.parseEscapeEvent(escapeSnapshot)
                            if let event {
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

}
