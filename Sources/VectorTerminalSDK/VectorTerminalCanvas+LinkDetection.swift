import Foundation

/// Link detection controls for terminal text containing OSC 8 links or URLs.
extension VectorTerminalCanvas {
    /// Enable terminal link detection.
    ///
    /// - Parameters:
    ///   - decorate: When `true`, the terminal colors and underlines detected links.
    ///   - color: Optional decoration color. Omitting it uses the terminal's blue default.
    public func enableLinkDetection(decorate: Bool = true, color: VTGColor? = nil) {
        var command = "linkDetection,enabled=1,decorate=\(decorate ? 1 : 0)"
        if let color {
            command += ",color=\(sanitizedPayload(color.rawValue))"
        }
        send(command)
    }

    /// Disable link detection and link activation.
    public func disableLinkDetection() {
        send("linkDetection,enabled=0")
    }
}
