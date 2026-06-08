import Foundation

/// Sprite asset upload and lifetime commands.
extension VectorTerminalCanvas {
    /// Upload a PNG sprite image without placing it.
    ///
    /// Sprite images are cached by the terminal so callers can move, rotate,
    /// and scale tiny raster assets without resending the image payload.
    public func uploadSprite(
        id: String,
        width: Int,
        height: Int,
        pngData: Data,
        filter: VTGSpriteFilter = .smooth
    ) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        send("spriteUpload,id=\(id),format=png,width=\(width),height=\(height),filter=\(filter.rawValue)", payload: pngData.base64EncodedString())
    }

    /// Upload a JPEG sprite image without placing it.
    public func uploadSprite(
        id: String,
        width: Int,
        height: Int,
        jpegData: Data,
        filter: VTGSpriteFilter = .smooth
    ) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        send("spriteUpload,id=\(id),format=jpeg,width=\(width),height=\(height),filter=\(filter.rawValue)", payload: jpegData.base64EncodedString())
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

    /// Upload a palette-indexed sprite without placing it.
    ///
    /// This is intended for retro BASIC-style programs that naturally describe
    /// sprites as numeric arrays. Each `pixels` entry is an index into
    /// `palette`; `transparentIndex`, when provided, marks pixels that should
    /// not be drawn. The uploaded asset uses the same `sprite(...)`,
    /// `moveSprite(...)`, and transform commands as bitmap/vector sprites.
    public func uploadSprite(
        id: String,
        width: Int,
        height: Int,
        pixels: [Int],
        palette: [VTGColor],
        transparentIndex: Int? = nil,
        filter: VTGSpriteFilter = .nearest
    ) {
        guard isValidVTGIdentifier(id),
              width > 0,
              height > 0,
              pixels.count == width * height,
              palette.isEmpty == false else {
            return
        }
        let palettePayload = palette.map(\.rawValue).joined(separator: "|")
        let transparent = transparentIndex.map { ",transparent=\($0)" } ?? ""
        let pixelPayload = pixels.map(String.init).joined(separator: ",")
        send("spriteDataUpload,id=\(id),width=\(width),height=\(height),palette=\(palettePayload)\(transparent),filter=\(filter.rawValue)", payload: pixelPayload)
    }

    /// Named alias for the palette-indexed sprite upload API.
    public func uploadIndexedSprite(
        id: String,
        width: Int,
        height: Int,
        pixels: [Int],
        palette: [VTGColor],
        transparentIndex: Int? = nil,
        filter: VTGSpriteFilter = .nearest
    ) {
        uploadSprite(id: id, width: width, height: height, pixels: pixels, palette: palette, transparentIndex: transparentIndex, filter: filter)
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
}
