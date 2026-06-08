import Foundation

/// ANSI screen and line clearing helpers.
extension VectorTerminalCanvas {
    /// Clear the visible terminal screen.
    public func clearScreen() {
        writeANSI("\(esc)[2J")
    }

    /// Clear scrollback and the visible terminal screen.
    public func clearScrollbackAndScreen() {
        writeANSI("\(esc)[3J\(esc)[2J")
    }

    /// Clear the current terminal line.
    public func clearLine() {
        writeANSI("\(esc)[2K")
    }

    /// Clear from the cursor to the end of the current line.
    public func clearToEndOfLine() {
        writeANSI("\(esc)[K")
    }
}
