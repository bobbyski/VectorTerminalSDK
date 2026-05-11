import Foundation

/// ANSI convenience helpers exposed by the SDK.
///
/// These functions intentionally keep working even when VTG initialization
/// failed and the caller is using a no-op graphics canvas.
extension VectorTerminalCanvas {
    /// Emit an audible/visual terminal bell.
    public func bell() {
        writeANSI("\u{07}")
    }

    /// Write plain text after removing control bytes unsafe for VTG payloads.
    public func writeText(_ value: String) {
        output.write(Data(sanitizedPayload(value).utf8))
    }

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

    /// Reset SGR text styling.
    public func resetTextAttributes() {
        writeANSI("\(esc)[0m")
    }

    /// Enable or disable bold text.
    public func bold(_ enabled: Bool = true) {
        writeANSI("\(esc)[\(enabled ? 1 : 22)m")
    }

    /// Enable or disable underlined text.
    public func underline(_ enabled: Bool = true) {
        writeANSI("\(esc)[\(enabled ? 4 : 24)m")
    }

    /// Enable or disable inverse-video text.
    public func inverse(_ enabled: Bool = true) {
        writeANSI("\(esc)[\(enabled ? 7 : 27)m")
    }

    /// Set an indexed ANSI foreground color.
    public func setForeground(_ color: ANSIColor, bright: Bool = false) {
        writeANSI("\(esc)[\(color.rawValue + (bright ? 90 : 30))m")
    }

    /// Set an indexed ANSI background color.
    public func setBackground(_ color: ANSIColor, bright: Bool = false) {
        writeANSI("\(esc)[\(color.rawValue + (bright ? 100 : 40))m")
    }

    /// Set a true-color foreground color.
    public func setForegroundRGB(red: Int, green: Int, blue: Int) {
        writeANSI("\(esc)[38;2;\(clampColor(red));\(clampColor(green));\(clampColor(blue))m")
    }

    /// Set a true-color background color.
    public func setBackgroundRGB(red: Int, green: Int, blue: Int) {
        writeANSI("\(esc)[48;2;\(clampColor(red));\(clampColor(green));\(clampColor(blue))m")
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

    /// Enable VTG-native mouse reporting plus ANSI SGR fallback reporting.
    public func enableMouseReporting() {
        send("mouseEvents,enabled=1,mode=raw")
        writeANSI("\(esc)[?1000h")
        writeANSI("\(esc)[?1006h")
    }

    /// Enable VTG-native mouse reporting with an explicit VTG mode.
    public func enableMouseReporting(mode: String) {
        send("mouseEvents,enabled=1,mode=\(sanitizedPayload(mode))")
        writeANSI("\(esc)[?1000h")
        writeANSI("\(esc)[?1006h")
    }

    /// Disable VTG-native and ANSI mouse reporting.
    public func disableMouseReporting() {
        send("mouseEvents,enabled=0")
        writeANSI("\(esc)[?1006l")
        writeANSI("\(esc)[?1000l")
    }
}
