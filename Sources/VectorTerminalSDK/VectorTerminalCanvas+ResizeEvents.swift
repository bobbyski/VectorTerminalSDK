import Foundation

/// VTG resize-event subscription helpers.
extension VectorTerminalCanvas {
    /// Subscribe to VTG resize events from VectorTerminal.
    public func enableResizeEvents() {
        send("resizeEvents,enabled=1")
    }

    /// Disable VTG resize events from VectorTerminal.
    public func disableResizeEvents() {
        send("resizeEvents,enabled=0")
    }
}
