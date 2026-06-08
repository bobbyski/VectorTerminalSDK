import Foundation

/// Retained sprite-instance placement and transform commands.
extension VectorTerminalCanvas {
    /// Create or replace a retained sprite instance.
    ///
    /// `id` is the placed instance id; `imageID` references an uploaded sprite
    /// asset. Transforms apply to sprite instances only, not arbitrary drawing
    /// primitives.
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
        guard isValidVTGIdentifier(id), isValidVTGIdentifier(imageID) else {
            return
        }
        send("sprite,id=\(id),image=\(imageID),x=\(x),y=\(y),rotation=\(vtgNumber(rotation)),scale=\(vtgNumber(scale)),anchorX=\(vtgNumber(clampedUnit(anchorX))),anchorY=\(vtgNumber(clampedUnit(anchorY)))\(layerParameter(layer))")
    }

    /// Move a retained sprite instance without changing rotation or scale.
    public func moveSprite(id: String, x: Int, y: Int) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        send("spriteMove,id=\(id),x=\(x),y=\(y)")
    }

    /// Rotate a retained sprite instance around its center point.
    public func rotateSprite(id: String, rotation: Double) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        send("spriteRotate,id=\(id),rotation=\(vtgNumber(rotation))")
    }

    /// Update sprite position, rotation, and scale in one frame-loop command.
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
    public func anchorSprite(id: String, anchorX: Double, anchorY: Double) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        send("spriteAnchor,id=\(id),anchorX=\(vtgNumber(clampedUnit(anchorX))),anchorY=\(vtgNumber(clampedUnit(anchorY)))")
    }
}
