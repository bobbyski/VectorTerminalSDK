import Foundation

extension VectorTerminalCanvas {
    /// Parse fallback ANSI mouse reports for non-VTG or transitional paths.
    ///
    /// VTG-native mouse events are preferred because they can include pixel
    /// coordinates. The ANSI fallback remains useful for debugging and for
    /// terminals that only emit traditional mouse sequences.
    func parseMouseEvent(_ bytes: [UInt8]) -> VTGMouseEvent? {
        parseSGRMouseEvent(bytes) ?? parseX10MouseEvent(bytes)
    }

    /// Parse SGR extended mouse reports (`ESC [ < b ; x ; y M/m`).
    func parseSGRMouseEvent(_ bytes: [UInt8]) -> VTGMouseEvent? {
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
    func parseX10MouseEvent(_ bytes: [UInt8]) -> VTGMouseEvent? {
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
}
