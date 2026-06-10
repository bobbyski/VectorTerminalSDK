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
            if let frame = parseVTGFrameEvent(from: response) {
                return .frame(frame)
            }
        }
        if let mouse = parseMouseEvent(bytes) {
            return .mouse(mouse)
        }
        return nil
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
