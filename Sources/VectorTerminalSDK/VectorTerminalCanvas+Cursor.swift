import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
// Static Linux (the musl SDK): the same C library under its own module name.
import Musl
#endif

/// ANSI cursor movement and visibility helpers.
extension VectorTerminalCanvas {
    /// Move the cursor using one-based terminal row and column coordinates.
    ///
    /// Sends ANSI CUP (`ESC[row;columnH`). Values below 1 are raised to 1.
    ///
    /// - Parameters:
    ///   - row: One-based terminal row.
    ///   - column: One-based terminal column.
    public func moveCursor(row: Int, column: Int) {
        writeANSI("\(esc)[\(max(1, row));\(max(1, column))H")
    }

    /// Alias for `moveCursor(row:column:)`.
    ///
    /// - Parameters:
    ///   - row: One-based terminal row; values below 1 become 1.
    ///   - column: One-based terminal column; values below 1 become 1.
    public func setCursor(row: Int, column: Int) {
        moveCursor(row: row, column: column)
    }

    /// Move the cursor up by `count` cells.
    ///
    /// - Parameter count: Cells to move. Defaults to 1; values below 1 become 1.
    public func moveCursorUp(_ count: Int = 1) {
        writeANSI("\(esc)[\(max(1, count))A")
    }

    /// Move the cursor down by `count` cells.
    ///
    /// - Parameter count: Cells to move. Defaults to 1; values below 1 become 1.
    public func moveCursorDown(_ count: Int = 1) {
        writeANSI("\(esc)[\(max(1, count))B")
    }

    /// Move the cursor right by `count` cells.
    ///
    /// - Parameter count: Cells to move. Defaults to 1; values below 1 become 1.
    public func moveCursorForward(_ count: Int = 1) {
        writeANSI("\(esc)[\(max(1, count))C")
    }

    /// Move the cursor left by `count` cells.
    ///
    /// - Parameter count: Cells to move. Defaults to 1; values below 1 become 1.
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
    ///
    /// Switches the input to raw mode for the query, sends `ESC[6n`, and reads
    /// the `ESC[row;columnR` reply.
    ///
    /// - Parameter timeoutMilliseconds: How long to wait for the reply. Defaults to 750.
    /// - Returns: The one-based cursor position, or nil when no valid reply arrives in time.
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
