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

    /// Anchor a layer's graphics to a line of text so they scroll with it.
    ///
    /// The default everywhere is `.screen`: a shape drawn at y=100 stays at
    /// y=100 while output scrolls underneath it, which is what a HUD wants and
    /// what an inline widget does not. In `.text` mode the layer's origin is
    /// pinned to an absolute buffer line, and the terminal recomputes the
    /// layer's offset as that line moves — the mode for an inline TUIKit
    /// control that should scroll away with the prompt it belongs to.
    ///
    /// Omit `line` to mean "here": the host substitutes the line currently
    /// being written, since only it knows the buffer.
    ///
    /// **Graphics are not kept in scrollback.** The anchor line is remembered
    /// even after it scrolls out of view, so returning to it is exact, but
    /// nothing is rasterised per scrolled line.
    ///
    /// Applies to every layer including -1: `layerScroll` refuses the
    /// under-text plane, but anchoring is not scrolling — it says where the
    /// layer belongs in the document, and chrome drawn beneath its own text is
    /// exactly the case that needs it.
    public func setLayerAnchor(_ layer: Int, _ mode: VTGLayerAnchorMode, line: Int? = nil) {
        guard isSupportedVTGLayer(layer) else {
            return
        }
        var payload = "layerAnchor,layer=\(layer),mode=\(mode.rawValue)"
        if mode == .text, let line {
            payload += ",line=\(line)"
        }
        send(payload)
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

    /// Show or hide all retained graphics layers without clearing objects.
    ///
    /// Hidden layers remain retained in the terminal. Turning graphics back on
    /// restores the existing scene without requiring the app to redraw it.
    public func setGraphicsLayersVisible(_ isVisible: Bool) {
        send("graphicsVisible,enabled=\(isVisible ? 1 : 0)")
    }
}
