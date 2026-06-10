import Foundation

/// Fixed-resolution overlay viewport controls.
extension VectorTerminalCanvas {
    /// Enable fixed-resolution drawing coordinates for an overlay layer.
    ///
    /// Layer 0 is intentionally unsupported because it contains native terminal
    /// text. Overlay layers can scale fixed-size game/demo coordinate spaces
    /// into the live terminal canvas.
    public func setViewportMode(
        layer: Int,
        width: Int,
        height: Int,
        scale: VTGViewportScaleMode = .fit
    ) {
        guard VTGLayer.isScrollable(layer), width > 0, height > 0 else {
            return
        }
        send("viewportMode,layer=\(layer),width=\(width),height=\(height),scale=\(scale.rawValue)")
    }

    /// Return an overlay layer to native live-canvas pixel coordinates.
    public func clearViewportMode(layer: Int) {
        guard VTGLayer.isScrollable(layer) else {
            return
        }
        send("viewportMode,layer=\(layer),value=native")
    }

    /// Override placement for a fixed-resolution overlay layer.
    ///
    /// Call this after `setViewportMode` when an app wants exact scale and
    /// origin rather than terminal-selected fit/fill/integer/stretch placement.
    public func setViewportScale(layer: Int, scale: Double, x: Int, y: Int) {
        guard VTGLayer.isScrollable(layer), scale > 0 else {
            return
        }
        send("viewportScale,layer=\(layer),scale=\(vtgNumber(scale)),x=\(x),y=\(y)")
    }
}
