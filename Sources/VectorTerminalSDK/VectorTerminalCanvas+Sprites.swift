import Foundation

/// Sprite asset and retained sprite-instance commands.
extension VectorTerminalCanvas {
    /// Upload a PNG sprite image without placing it.
    ///
    /// Sprite images are cached by the terminal so callers can move, rotate,
    /// and scale tiny raster assets without resending the image payload.
    public func uploadSprite(
        id: String,
        width: Int,
        height: Int,
        pngData: Data
    ) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        send("spriteUpload,id=\(id),format=png,width=\(width),height=\(height)", payload: pngData.base64EncodedString())
    }

    /// Upload a JPEG sprite image without placing it.
    public func uploadSprite(
        id: String,
        width: Int,
        height: Int,
        jpegData: Data
    ) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        send("spriteUpload,id=\(id),format=jpeg,width=\(width),height=\(height)", payload: jpegData.base64EncodedString())
    }

    /// Upload a vector sprite asset without placing it.
    ///
    /// Vector sprites use the same retained sprite instance and transform
    /// commands as bitmap sprites. The first protocol slice stores one
    /// constrained VTG path payload per asset.
    public func uploadVectorSprite(
        id: String,
        width: Int,
        height: Int,
        path: String,
        stroke: VTGColor? = nil,
        fill: VTGColor? = nil,
        lineWidth: Double = 1
    ) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        send("vectorSpriteUpload,id=\(id),width=\(width),height=\(height)\(colorParameter("stroke", stroke))\(colorParameter("fill", fill)),lineWidth=\(vtgNumber(lineWidth))", payload: path)
    }

    /// Remove one uploaded sprite asset and any instances using it.
    public func removeSprite(id: String) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        send("spriteRemove,id=\(id)")
    }

    /// Remove all uploaded sprite assets and sprite instances.
    public func clearSprites() {
        send("spriteClear")
    }

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
