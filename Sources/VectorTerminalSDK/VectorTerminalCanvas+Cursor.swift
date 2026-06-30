import Foundation
import Darwin

/// ANSI cursor movement and visibility helpers.
extension VectorTerminalCanvas {
    /// Move the cursor using one-based terminal row and column coordinates.
    public func moveCursor(row: Int, column: Int) {
        writeANSI("\(esc)[\(max(1, row));\(max(1, column))H")
    }

    /// Alias for `moveCursor(row:column:)`.
    public func setCursor(row: Int, column: Int) {
        moveCursor(row: row, column: column)
    }

    /// Move the cursor up by `count` cells.
    public func moveCursorUp(_ count: Int = 1) {
        writeANSI("\(esc)[\(max(1, count))A")
    }

    /// Move the cursor down by `count` cells.
    public func moveCursorDown(_ count: Int = 1) {
        writeANSI("\(esc)[\(max(1, count))B")
    }

    /// Move the cursor right by `count` cells.
    public func moveCursorForward(_ count: Int = 1) {
        writeANSI("\(esc)[\(max(1, count))C")
    }

    /// Move the cursor left by `count` cells.
    public func moveCursorBackward(_ count: Int = 1) {
        writeANSI("\(esc)[\(max(1, count))D")
    }

    /// Save the current cursor position.
    public func saveCursor() {
        writeANSI("\(esc)7")
    }

    /// Restore the previously saved cursor position.
    public func restoreCursor() {
        writeANSI("\(esc)8")
    }

    /// Hide the terminal text cursor.
    public func hideCursor() {
        writeANSI("\(esc)[?25l")
    }

    /// Show the terminal text cursor.
    public func showCursor() {
        writeANSI("\(esc)[?25h")
    }

    /// Query the current terminal cursor position using ANSI DSR.
    public func queryCursorPosition(timeoutMilliseconds: Int = 750) -> TerminalCursorPosition? {
        let original = enableRawMode()
        defer { restoreMode(original) }

        writeANSI("\(esc)[6n")
        guard let bytes = readCursorPositionResponse(timeoutMilliseconds: timeoutMilliseconds),
              let response = String(bytes: bytes, encoding: .utf8) else {
            return nil
        }
        return parseCursorPosition(response)
    }

    private func readCursorPositionResponse(timeoutMilliseconds: Int) -> [UInt8]? {
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
            if byte == UInt8(ascii: "R") {
                return collected
            }
            if collected.count > 128 {
                return collected
            }
        }

        return collected.isEmpty ? nil : collected
    }

    private func parseCursorPosition(_ response: String) -> TerminalCursorPosition? {
        guard response.hasPrefix("\(esc)["), response.hasSuffix("R") else {
            return nil
        }
        let body = response.dropFirst(2).dropLast()
        let parts = body.split(separator: ";", maxSplits: 1).compactMap { Int($0) }
        guard parts.count == 2, parts[0] > 0, parts[1] > 0 else {
            return nil
        }
        return TerminalCursorPosition(row: parts[0], column: parts[1])
    }
}
