import Foundation

/// ANSI SGR text style and color helpers.
///
/// These helpers deliberately remain independent from VTG initialization so
/// applications can still write conventional terminal UI when graphics are not
/// available.
extension VectorTerminalCanvas {
    /// Reset SGR text styling.
    public func resetTextAttributes() {
        writeANSI("\(esc)[0m")
    }

    /// Enable or disable bold text.
    ///
    /// - Parameter enabled: `true` sends SGR 1; `false` sends SGR 22.
    public func bold(_ enabled: Bool = true) {
        writeANSI("\(esc)[\(enabled ? 1 : 22)m")
    }

    /// Enable or disable underlined text.
    ///
    /// - Parameter enabled: `true` sends SGR 4; `false` sends SGR 24.
    public func underline(_ enabled: Bool = true) {
        writeANSI("\(esc)[\(enabled ? 4 : 24)m")
    }

    /// Enable or disable inverse-video text.
    ///
    /// - Parameter enabled: `true` sends SGR 7; `false` sends SGR 27.
    public func inverse(_ enabled: Bool = true) {
        writeANSI("\(esc)[\(enabled ? 7 : 27)m")
    }

    /// Set an indexed ANSI foreground color.
    ///
    /// - Parameters:
    ///   - color: One of the eight ANSI colors.
    ///   - bright: Whether to use the bright variant (SGR 90-97 instead of 30-37).
    public func setForeground(_ color: ANSIColor, bright: Bool = false) {
        writeANSI("\(esc)[\(color.rawValue + (bright ? 90 : 30))m")
    }

    /// Set an indexed ANSI background color.
    ///
    /// - Parameters:
    ///   - color: One of the eight ANSI colors.
    ///   - bright: Whether to use the bright variant (SGR 100-107 instead of 40-47).
    public func setBackground(_ color: ANSIColor, bright: Bool = false) {
        writeANSI("\(esc)[\(color.rawValue + (bright ? 100 : 40))m")
    }

    /// Set a true-color foreground color.
    ///
    /// - Parameters:
    ///   - red: Red channel, 0 through 255; clamped.
    ///   - green: Green channel, 0 through 255; clamped.
    ///   - blue: Blue channel, 0 through 255; clamped.
    public func setForegroundRGB(red: Int, green: Int, blue: Int) {
        writeANSI("\(esc)[38;2;\(clampColor(red));\(clampColor(green));\(clampColor(blue))m")
    }

    /// Set a true-color background color.
    ///
    /// - Parameters:
    ///   - red: Red channel, 0 through 255; clamped.
    ///   - green: Green channel, 0 through 255; clamped.
    ///   - blue: Blue channel, 0 through 255; clamped.
    public func setBackgroundRGB(red: Int, green: Int, blue: Int) {
        writeANSI("\(esc)[48;2;\(clampColor(red));\(clampColor(green));\(clampColor(blue))m")
    }
}
