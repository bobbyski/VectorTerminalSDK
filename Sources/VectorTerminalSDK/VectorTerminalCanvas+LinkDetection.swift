import Foundation

/// Link detection controls for terminal text containing OSC 8 links or URLs.
extension VectorTerminalCanvas {
    /// Enable terminal link detection.
    ///
    /// Sends `linkDetection,enabled=1,decorate=0|1[,color=…]`.
    ///
    /// - Parameters:
    ///   - decorate: When `true`, the terminal colors and underlines detected links.
    ///     Defaults to `true`.
    ///   - color: The decoration color, or nil for the terminal's blue default.
    ///     Sent even when `decorate` is `false`.
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
