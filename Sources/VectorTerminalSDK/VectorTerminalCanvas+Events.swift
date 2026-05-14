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

    /// Parse a complete escape sequence into an SDK event.
    private func parseEscapeEvent(_ bytes: [UInt8]) -> VectorTerminalEvent? {
        if let specialKey = parseSpecialKey(bytes) {
            return .specialKey(specialKey)
        }
        if let sequence = String(bytes: bytes, encoding: .utf8),
           sequence.hasPrefix("\(esc)[<") {
            eventDebugHandler?("SDK parser saw SGR candidate raw=\(sequence.debugEscapedForVTG)")
        }
        if let response = String(bytes: bytes, encoding: .utf8) {
            if response.contains("_VTG;resize"), let canvas = parseWidthHeight(from: response, source: "resize") {
                return .resize(canvas)
            }
            if response.contains("_VTG;canvas"), let canvas = parseWidthHeight(from: response, source: "canvas") {
                return .canvas(canvas)
            }
            if response.contains("_VTG;size"), let canvas = parseWidthHeight(from: response, source: "size") {
                return .canvas(canvas)
            }
            if response.contains("_VTG;capabilities"), let canvas = parseCapabilitiesCanvas(from: response, source: "capabilities") {
                return .canvas(canvas)
            }
            if response.contains("_VTG;mouse"), let mouse = parseVTGMouseEvent(from: response) {
                return .mouse(mouse)
            }
        }
        if let mouse = parseMouseEvent(bytes) {
            return .mouse(mouse)
        }
        return nil
    }

    /// Parse common cursor-key escape sequences.
    private func parseSpecialKey(_ bytes: [UInt8]) -> ANSISpecialKey? {
        guard bytes.count >= 3,
              bytes[0] == 0x1b else {
            return nil
        }

        let introducer = bytes[1]
        guard introducer == UInt8(ascii: "[") || introducer == UInt8(ascii: "O"),
              let final = bytes.last else {
            return nil
        }

        switch final {
        case UInt8(ascii: "A"):
            return .up
        case UInt8(ascii: "B"):
            return .down
        case UInt8(ascii: "C"):
            return .right
        case UInt8(ascii: "D"):
            return .left
        default:
            return nil
        }
    }

    /// Parse VectorTerminal-native mouse events.
    ///
    /// These events carry both graphics-pixel and terminal-cell coordinates.
    /// That dual coordinate payload was added after the TicTacToe mouse
    /// debugging pass and is still useful for demos that need live diagnostics.
    private func parseVTGMouseEvent(from response: String) -> VTGMouseEvent? {
        let values = vtgFields(from: response)
        guard let x = values["x"].flatMap(Int.init),
              let y = values["y"].flatMap(Int.init) else {
            eventDebugHandler?("SDK parser rejected VTG mouse raw=\(response.debugEscapedForVTG)")
            return nil
        }
        let type = values["type"] ?? "down"
        let button = values["button"].flatMap(Int.init) ?? 0
        let cellX = values["cellX"].flatMap(Int.init)
        let cellY = values["cellY"].flatMap(Int.init)
        let modifiers = values["mods"] ?? "none"
        let scrollX = values["scrollX"].flatMap(Int.init)
        let scrollY = values["scrollY"].flatMap(Int.init)
        let hitID = values["hit"]
        let targetID = values["target"]
        eventDebugHandler?("SDK parser accepted VTG mouse type=\(type) button=\(button) x=\(x) y=\(y) cell=\(cellX.map(String.init) ?? "?"),\(cellY.map(String.init) ?? "?") scroll=\(scrollX.map(String.init) ?? "?"),\(scrollY.map(String.init) ?? "?") hit=\(hitID ?? "none") target=\(targetID ?? "none") mods=\(modifiers) raw=\(response.debugEscapedForVTG)")
        return VTGMouseEvent(
            x: x,
            y: y,
            isPress: type == "down" || type == "drag" || type == "click",
            button: button,
            cellX: cellX,
            cellY: cellY,
            type: type,
            modifiers: modifiers,
            scrollX: scrollX,
            scrollY: scrollY,
            hitID: hitID,
            targetID: targetID,
            rawSequence: response
        )
    }

    /// Parse fallback ANSI mouse reports for non-VTG or transitional paths.
    ///
    /// VTG-native mouse events are preferred because they can include pixel
    /// coordinates. The ANSI fallback remains useful for debugging and for
    /// terminals that only emit traditional mouse sequences.
    private func parseMouseEvent(_ bytes: [UInt8]) -> VTGMouseEvent? {
        parseSGRMouseEvent(bytes) ?? parseX10MouseEvent(bytes)
    }

    /// Parse SGR extended mouse reports (`ESC [ < b ; x ; y M/m`).
    private func parseSGRMouseEvent(_ bytes: [UInt8]) -> VTGMouseEvent? {
        guard let sequence = String(bytes: bytes, encoding: .utf8) else {
            eventDebugHandler?("SDK parser rejected non-UTF8 CSI bytes count=\(bytes.count)")
            return nil
        }
        guard sequence.hasPrefix("\(esc)[<") else {
            return nil
        }
        guard sequence.hasSuffix("M") || sequence.hasSuffix("m") else {
            eventDebugHandler?("SDK parser rejected SGR without M/m terminator raw=\(sequence.debugEscapedForVTG)")
            return nil
        }
        let body = sequence
            .dropFirst(3)
            .dropLast()
            .split(separator: ";")
        guard body.count == 3,
              let button = Int(body[0]),
              let x = Int(body[1]),
              let y = Int(body[2]) else {
            eventDebugHandler?("SDK parser rejected malformed SGR raw=\(sequence.debugEscapedForVTG)")
            return nil
        }

        let isPress = sequence.hasSuffix("M")
        let isRelease = sequence.hasSuffix("m")
        guard button == 0 || isRelease else {
            eventDebugHandler?("SDK parser ignored non-left press button=\(button) x=\(x) y=\(y) raw=\(sequence.debugEscapedForVTG)")
            return nil
        }
        eventDebugHandler?("SDK parser accepted button=\(button) press=\(isPress) x=\(x) y=\(y) raw=\(sequence.debugEscapedForVTG)")
        return VTGMouseEvent(x: x, y: y, isPress: isPress, button: button, rawSequence: sequence)
    }

    /// Parse fixed-width X10 mouse reports.
    private func parseX10MouseEvent(_ bytes: [UInt8]) -> VTGMouseEvent? {
        guard bytes.count == 6,
              bytes[0] == 0x1b,
              bytes[1] == UInt8(ascii: "["),
              bytes[2] == UInt8(ascii: "M") else {
            return nil
        }

        let button = Int(bytes[3]) - 32
        let x = Int(bytes[4]) - 32
        let y = Int(bytes[5]) - 32
        let isRelease = button == 3
        guard button == 0 || isRelease else {
            eventDebugHandler?("SDK parser ignored X10 button=\(button) x=\(x) y=\(y) raw=\(bytes.debugEscapedForVTG)")
            return nil
        }
        eventDebugHandler?("SDK parser accepted X10 button=\(button) press=\(!isRelease) x=\(x) y=\(y) raw=\(bytes.debugEscapedForVTG)")
        return VTGMouseEvent(
            x: x,
            y: y,
            isPress: !isRelease,
            button: button,
            type: isRelease ? "up" : "down",
            rawSequence: bytes.debugEscapedForVTG
        )
    }

    /// Determine whether enough bytes have arrived to parse one escape sequence.
    private func isCompleteEscape(_ bytes: [UInt8]) -> Bool {
        guard bytes.count >= 2, bytes[0] == 0x1b else {
            return false
        }
        // APC responses such as ESC _ VTG;canvas,width=... ESC \ must be
        // collected through the string terminator before parsing.
        if bytes[1] == UInt8(ascii: "_") {
            return bytes.count >= 2 &&
                bytes[bytes.count - 2] == 0x1b &&
                bytes[bytes.count - 1] == UInt8(ascii: "\\")
        }
        // X10 mouse reports have a fixed six-byte form: ESC [ M b x y.
        if bytes.count >= 3,
           bytes[1] == UInt8(ascii: "["),
           bytes[2] == UInt8(ascii: "M") {
            return bytes.count >= 6
        }
        if bytes[1] == UInt8(ascii: "[") {
            guard bytes.count >= 3 else {
                return false
            }
            // SGR mouse reports can contain multi-digit coordinates, so wait
            // for their explicit M/m terminator. This avoids splitting large
            // screen mouse coordinates across multiple bogus events.
            if bytes[2] == UInt8(ascii: "<") {
                guard let last = bytes.last else {
                    return false
                }
                return last == UInt8(ascii: "M") || last == UInt8(ascii: "m")
            }
            // Generic CSI sequence. Important: ESC [ alone is not complete,
            // even though `[` is in the broad final-byte range. Treating it as
            // complete broke down/right arrows during VectorTank testing.
            guard let last = bytes.last else {
                return false
            }
            return last >= 0x40 && last <= 0x7e
        }
        // SS3 sequences cover alternate cursor-key modes such as ESC O A.
        if bytes[1] == UInt8(ascii: "O"),
           let last = bytes.last {
            return bytes.count >= 3 && last >= 0x40 && last <= 0x7e
        }
        return bytes.count > 1
    }
}
