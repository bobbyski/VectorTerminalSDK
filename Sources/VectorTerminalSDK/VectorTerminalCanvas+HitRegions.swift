import Foundation

/// Retained VTG hit-region controls.
extension VectorTerminalCanvas {
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
