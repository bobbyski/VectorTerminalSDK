import Foundation

/// Retained sprite-instance placement and transform commands.
extension VectorTerminalCanvas {
    /// Create or replace a retained sprite instance.
    ///
    /// `id` is the placed instance id; `imageID` references an uploaded sprite
    /// asset. Transforms apply to sprite instances only, not arbitrary drawing
    /// primitives.
    ///
    /// Sends `sprite,...`. An invalid `id` or `imageID` is reported to
    /// `commandRejectedHandler` (`badId` or `unknownAsset`) and nothing is sent.
    ///
    /// - Parameters:
    ///   - id: The placed instance id; placing again with the same id replaces it.
    ///   - imageID: The id of an uploaded sprite asset.
    ///   - x: Anchor position x, in pixels.
    ///   - y: Anchor position y, in pixels.
    ///   - rotation: Rotation in degrees around the anchor point.
    ///   - scale: Scale factor; `1` draws the asset at its uploaded size.
    ///   - anchorX: Horizontal anchor as a fraction of the asset width, clamped
    ///     to `0...1`.
    ///   - anchorY: Vertical anchor as a fraction of the asset height, clamped
    ///     to `0...1`.
    ///   - layer: Graphics layer, `-1...4`. Nil, or an unsupported value, omits
    ///     `layer=` so the primitive lands on the default layer.
    public func sprite(
        id: String,
        imageID: String,
        x: Int,
        y: Int,
        rotation: Double = 0,
        scale: Double = 1,
        anchorX: Double = 0.5,
        anchorY: Double = 0.5,
        layer: Int? = nil
    ) {
        guard isValidVTGIdentifier(id) else {
            return refuse("sprite", id: id, "badId")
        }
        guard isValidVTGIdentifier(imageID) else {
            return refuse("sprite", id: id, "unknownAsset")
        }
        send("sprite,id=\(id),image=\(imageID),x=\(x),y=\(y),rotation=\(vtgNumber(rotation)),scale=\(vtgNumber(scale)),anchorX=\(vtgNumber(clampedUnit(anchorX))),anchorY=\(vtgNumber(clampedUnit(anchorY)))\(layerParameter(layer))")
    }

    /// Move a retained sprite instance without changing rotation or scale.
    ///
    /// Sends `spriteMove,...`.
    ///
    /// - Parameters:
    ///   - id: The placed sprite instance id. An invalid id sends nothing.
    ///   - x: New anchor position x, in pixels.
    ///   - y: New anchor position y, in pixels.
    public func moveSprite(id: String, x: Int, y: Int) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        send("spriteMove,id=\(id),x=\(x),y=\(y)")
    }

    /// Rotate a retained sprite instance around its center point.
    ///
    /// The rotation is around the instance's anchor, which is the center
    /// unless the anchor was changed. Sends `spriteRotate,...`.
    ///
    /// - Parameters:
    ///   - id: The placed sprite instance id. An invalid id sends nothing.
    ///   - rotation: Absolute rotation in degrees, replacing the previous value.
    public func rotateSprite(id: String, rotation: Double) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        send("spriteRotate,id=\(id),rotation=\(vtgNumber(rotation))")
    }

    /// Update sprite position, rotation, and scale in one frame-loop command.
    ///
    /// Sends `spriteTransform,...`.
    ///
    /// - Parameters:
    ///   - id: The placed sprite instance id. An invalid id sends nothing.
    ///   - x: Anchor position x, in pixels.
    ///   - y: Anchor position y, in pixels.
    ///   - rotation: Rotation in degrees around the anchor point.
    ///   - scale: Scale factor; `1` draws the asset at its uploaded size.
    ///   - anchorX: New horizontal anchor, clamped to `0...1`; nil keeps the
    ///     current one.
    ///   - anchorY: New vertical anchor, clamped to `0...1`; nil keeps the
    ///     current one.
    public func transformSprite(
        id: String,
        x: Int,
        y: Int,
        rotation: Double,
        scale: Double,
        anchorX: Double? = nil,
        anchorY: Double? = nil
    ) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        send("spriteTransform,id=\(id),x=\(x),y=\(y),rotation=\(vtgNumber(rotation)),scale=\(vtgNumber(scale))\(optionalUnitParameter("anchorX", anchorX))\(optionalUnitParameter("anchorY", anchorY))")
    }

    /// Update only the retained sprite anchor point.
    ///
    /// Sends `spriteAnchor,...`.
    ///
    /// - Parameters:
    ///   - id: The placed sprite instance id. An invalid id sends nothing.
    ///   - anchorX: Horizontal anchor as a fraction of the asset width, clamped
    ///     to `0...1`.
    ///   - anchorY: Vertical anchor as a fraction of the asset height, clamped
    ///     to `0...1`.
    public func anchorSprite(id: String, anchorX: Double, anchorY: Double) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        send("spriteAnchor,id=\(id),anchorX=\(vtgNumber(clampedUnit(anchorX))),anchorY=\(vtgNumber(clampedUnit(anchorY)))")
    }
}
