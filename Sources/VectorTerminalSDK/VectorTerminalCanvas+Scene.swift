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

    /// Register or replace a rectangular hit region.
    ///
    /// Mouse events emitted inside the region include `hitID` and optional
    /// `targetID`. Regions are evaluated by layer from top to bottom, then by
    /// registration order within a layer.
    public func hitRegion(
        id: String,
        x: Int,
        y: Int,
        width: Int,
        height: Int,
        layer: Int? = nil,
        target: String? = nil
    ) {
        guard isValidVTGIdentifier(id), width > 0, height > 0 else {
            return
        }
        if let target, !isValidVTGIdentifier(target) {
            return
        }
        let targetParameter = target.map { ",target=\($0)" } ?? ""
        send("hit,id=\(id),x=\(x),y=\(y),w=\(width),h=\(height)\(layerParameter(layer))\(targetParameter)")
    }

    /// Remove one hit region, all hit regions on a layer, or every hit region.
    public func clearHitRegions(id: String? = nil, layer: Int? = nil) {
        if let id {
            guard isValidVTGIdentifier(id) else {
                return
            }
            send("hitClear,id=\(id)")
        } else if let layer {
            guard isSupportedVTGLayer(layer) else {
                return
            }
            send("hitClear,layer=\(layer)")
        } else {
            send("hitClear")
        }
    }
}
