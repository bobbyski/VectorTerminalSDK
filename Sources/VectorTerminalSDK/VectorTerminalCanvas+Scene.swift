import Foundation

/// Retained scene, layer, viewport, and hit-region controls.
extension VectorTerminalCanvas {
    /// Clear all retained VTG primitives from the terminal overlay.
    public func clear() {
        send("clear")
    }

    /// Request presentation of the current VTG scene.
    public func present() {
        send("present")
    }

    /// Delete one retained VTG primitive by id.
    ///
    /// This is useful for small immediate-mode animations that need to remove
    /// objects that have moved fully offscreen without clearing the whole scene.
    public func delete(id: String) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        send("delete,id=\(id)")
    }

}
