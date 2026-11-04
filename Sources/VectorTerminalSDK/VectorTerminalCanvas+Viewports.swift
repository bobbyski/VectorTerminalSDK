import Foundation

/// Fixed-resolution overlay viewport controls.
extension VectorTerminalCanvas {
    /// Enable fixed-resolution drawing coordinates for an overlay layer.
    ///
    /// Layer 0 is intentionally unsupported because it contains native terminal
    /// text. Overlay layers can scale fixed-size game/demo coordinate spaces
    /// into the live terminal canvas.
    ///
    /// Sends `viewportMode,layer=<n>,width=,height=,scale=`. A layer outside
    /// `1...4`, or a width or height that is not positive, drops the command.
    ///
    /// - Parameters:
    ///   - layer: The overlay layer, `1...4`.
    ///   - width: Virtual viewport width, in virtual pixels; must be positive.
    ///   - height: Virtual viewport height, in virtual pixels; must be positive.
    ///   - scale: How the terminal places the viewport on the canvas; defaults
    ///     to `.fit`.
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
    ///
    /// Sends `viewportMode,layer=<n>,value=native`. A layer outside `1...4` is
    /// silently ignored.
    ///
    /// - Parameter layer: The overlay layer, `1...4`.
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
    ///
    /// Sends `viewportScale,layer=<n>,scale=,x=,y=`. A layer outside `1...4`,
    /// or a scale that is not positive, drops the command.
    ///
    /// - Parameters:
    ///   - layer: The overlay layer, `1...4`.
    ///   - scale: Canvas pixels per virtual pixel; must be positive.
    ///   - x: Left edge of the scaled viewport on the canvas, in pixels.
    ///   - y: Top edge of the scaled viewport on the canvas, in pixels.
    public func setViewportScale(layer: Int, scale: Double, x: Int, y: Int) {
        guard VTGLayer.isScrollable(layer), scale > 0 else {
            return
        }
        send("viewportScale,layer=\(layer),scale=\(vtgNumber(scale)),x=\(x),y=\(y)")
    }
}
