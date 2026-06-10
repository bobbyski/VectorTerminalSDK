import Foundation

/// ANSI terminal-mode helpers.
extension VectorTerminalCanvas {
    /// Run synchronous work while stdin is in raw mode.
    public func withRawInput<T>(_ body: () throws -> T) rethrows -> T {
        let original = enableRawMode()
        defer { restoreMode(original) }
        return try body()
    }

    /// Run asynchronous work while stdin is in raw mode.
    public func withRawInput<T>(_ body: () async throws -> T) async rethrows -> T {
        let original = enableRawMode()
        defer { restoreMode(original) }
        return try await body()
    }

    /// Switch into the terminal alternate screen buffer.
    public func enterAlternateScreen() {
        writeANSI("\(esc)[?1049h")
    }

    /// Return from the terminal alternate screen buffer.
    public func leaveAlternateScreen() {
        writeANSI("\(esc)[?1049l")
    }

    /// Enable bracketed paste mode.
    public func enableBracketedPaste() {
        writeANSI("\(esc)[?2004h")
    }

    /// Disable bracketed paste mode.
    public func disableBracketedPaste() {
        writeANSI("\(esc)[?2004l")
    }

    /// Enable focus-in/focus-out reporting.
    public func enableFocusReporting() {
        writeANSI("\(esc)[?1004h")
    }

    /// Disable focus-in/focus-out reporting.
    public func disableFocusReporting() {
        writeANSI("\(esc)[?1004l")
    }
}
