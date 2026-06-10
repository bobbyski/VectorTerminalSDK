import Foundation

/// Mouse reporting controls for VTG-native events and ANSI fallback modes.
extension VectorTerminalCanvas {
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
        writeANSI("\(esc)[?1016l")
        writeANSI("\(esc)[?1015l")
        writeANSI("\(esc)[?1006l")
        writeANSI("\(esc)[?1005l")
        writeANSI("\(esc)[?1003l")
        writeANSI("\(esc)[?1002l")
        writeANSI("\(esc)[?1000l")
        writeANSI("\(esc)[?9l")
    }
}
