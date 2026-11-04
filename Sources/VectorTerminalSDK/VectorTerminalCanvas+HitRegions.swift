import Foundation

/// Retained VTG hit-region controls.
extension VectorTerminalCanvas {
    /// Register or replace a rectangular hit region.
    ///
    /// Mouse events emitted inside the region include `hitID` and optional
    /// `targetID`. Regions are evaluated by layer from top to bottom, then by
    /// registration order within a layer.
    ///
    /// Sends `hit,id=,x=,y=,w=,h=[,layer=][,target=]`. An invalid id or
    /// target, or a width or height that is not positive, drops the command.
    ///
    /// - Parameters:
    ///   - id: The hit-region id; registering the same id again replaces it.
    ///   - x: Left edge, in pixels.
    ///   - y: Top edge, in pixels.
    ///   - width: Region width, in pixels; must be positive.
    ///   - height: Region height, in pixels; must be positive.
    ///   - layer: The layer, `-1...4`; `nil` (or an out-of-range layer, which
    ///     is silently dropped) uses the terminal's default layer.
    ///   - target: An optional id reported as `targetID` in mouse events.
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
    ///
    /// Sends `hitClear,id=`, `hitClear,layer=`, or a bare `hitClear`. An
    /// invalid id or a layer outside `-1...4` drops the command rather than
    /// clearing everything.
    ///
    /// - Parameters:
    ///   - id: The region to remove. When given, `layer` is ignored.
    ///   - layer: Remove every region on this layer, `-1...4`.
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
