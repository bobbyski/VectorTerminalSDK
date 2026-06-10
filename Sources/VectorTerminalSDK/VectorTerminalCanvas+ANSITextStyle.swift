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
}
