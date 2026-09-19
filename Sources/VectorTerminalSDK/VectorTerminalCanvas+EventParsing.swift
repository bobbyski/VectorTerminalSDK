import Foundation

extension VectorTerminalCanvas {
    /// Parse a complete escape sequence into an SDK event.
    func parseEscapeEvent(_ bytes: [UInt8]) -> VectorTerminalEvent? {
        if let specialKey = parseSpecialKey(bytes) {
            return .specialKey(specialKey)
        }
        if let sequence = String(bytes: bytes, encoding: .utf8),
           sequence.hasPrefix("\(esc)[<") {
            eventDebugHandler?("SDK parser saw SGR candidate raw=\(sequence.debugEscapedForVTG)")
        }
        if let response = String(bytes: bytes, encoding: .utf8),
           let name = vtgResponseName(response) {
            // Dispatch on the exact response name. Matching a substring
            // anywhere in the response would let a future event such as
            // `resizePage,width=…,height=…` arrive as a window resize.
            switch name {
            case "resize":
                if let canvas = parseWidthHeight(from: response, source: "resize") {
                    return .resize(canvas)
                }
            case "canvas", "size":
                if let canvas = parseWidthHeight(from: response, source: name) {
                    return .canvas(canvas)
                }
            case "capabilities":
                if let canvas = parseCapabilitiesCanvas(from: response, source: "capabilities") {
                    return .canvas(canvas)
                }
            case "mouse":
                if let mouse = parseVTGMouseEvent(from: response) {
                    return .mouse(mouse)
                }
            default:
                break
            }
            if let frame = parseVTGFrameEvent(from: response) {
                return .frame(frame)
            }
            // Page Mode and text events have their own channel rather than a
            // new `VectorTerminalEvent` case, which would break every
            // exhaustive `switch` over events in existing apps.
            if VTGPageEvent.isPageEventName(name) {
                pageEventHandler?(VTGPageEvent(name: name, fields: vtgFields(from: response), rawResponse: response))
                return nil
            }
        }
        if let mouse = parseMouseEvent(bytes) {
            return .mouse(mouse)
        }
        return nil
    }

    /// The command or event name of a VTG APC response: the text between
    /// `ESC _ VTG;` and the first `,`, `;`, or the terminator.
    func vtgResponseName(_ response: String) -> String? {
        let prefix = "\(esc)_VTG;"
        guard let start = response.range(of: prefix)?.upperBound else {
            return nil
        }
        let rest = response[start...]
        let end = rest.firstIndex { $0 == "," || $0 == ";" || $0 == Character(esc) } ?? rest.endIndex
        let name = String(rest[..<end])
        return name.isEmpty ? nil : name
    }

    /// Determine whether enough bytes have arrived to parse one escape sequence.
    func isCompleteEscape(_ bytes: [UInt8]) -> Bool {
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
