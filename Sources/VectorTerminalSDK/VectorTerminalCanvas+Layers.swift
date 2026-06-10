import Foundation

/// Retained scene layer controls.
extension VectorTerminalCanvas {
    /// Set the session default graphics layer for subsequent VTG commands.
    ///
    /// Layer 0 is reserved for the future shared text/graphics plane. Layers
    /// 1-4 currently render as ordered overlay layers, with layer 1 preserving
    /// the original VectorTerminal behavior.
    public func setDefaultLayer(_ layer: Int) {
        guard isSupportedVTGLayer(layer) else {
            return
        }
        storedDefaultLayer = layer
        send("defaultLayer,layer=\(layer)")
    }

    /// Move an existing retained primitive to a different graphics layer.
    ///
    /// This updates layer metadata without redrawing the primitive. Unknown ids
    /// are ignored by the terminal.
    public func setLayer(id: String, layer: Int) {
        guard isValidVTGIdentifier(id), isSupportedVTGLayer(layer) else {
            return
        }
        send("layer,id=\(id),layer=\(layer)")
    }

    /// Set an overlay layer's render offset in pixels.
    ///
    /// This moves everything retained on the layer without changing object
    /// coordinates. Layer 0 is intentionally ignored in this first pass because
    /// text/graphics mingling needs the future SwiftTerm-hosted renderer.
    public func scrollLayer(_ layer: Int, x: Int, y: Int) {
        guard VTGLayer.isScrollable(layer) else {
            return
        }
        send("layerScroll,layer=\(layer),x=\(x),y=\(y)")
    }

    /// Set an overlay layer's opacity multiplier.
    ///
    /// This is useful for HUDs and transient overlays: callers can fade an
    /// entire layer without resending every retained primitive on that layer.
    /// Layer 0 is intentionally ignored until the shared text/graphics plane
    /// has renderer semantics for opacity.
    public func setLayerAlpha(_ layer: Int, alpha: Double) {
        guard VTGLayer.isScrollable(layer) else {
            return
        }
        send("layerAlpha,layer=\(layer),alpha=\(vtgNumber(min(1, max(0, alpha))))")
    }

    /// Apply a rectangular clip to a graphics layer.
    ///
    /// Clipping is layer-scoped in this first pass. That keeps draw commands
    /// simple and gives demos a useful way to constrain parallax panes, HUDs,
    /// and sprite arenas before retained object groups exist.
    public func clipLayer(_ layer: Int, x: Int, y: Int, width: Int, height: Int) {
        guard isSupportedVTGLayer(layer), width > 0, height > 0 else {
            return
        }
        send("clip,layer=\(layer),x=\(x),y=\(y),w=\(width),h=\(height)")
    }

    /// Remove any rectangular clip from a graphics layer.
    public func clearLayerClip(_ layer: Int) {
        guard isSupportedVTGLayer(layer) else {
            return
        }
        send("clipClear,layer=\(layer)")
    }
}
