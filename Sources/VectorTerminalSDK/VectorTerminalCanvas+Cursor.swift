import Foundation

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
}
