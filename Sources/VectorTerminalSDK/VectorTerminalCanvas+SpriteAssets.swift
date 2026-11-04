import Foundation

/// Sprite asset upload and lifetime commands.
extension VectorTerminalCanvas {
    /// Upload a PNG sprite image without placing it.
    ///
    /// Sprite images are cached by the terminal so callers can move, rotate,
    /// and scale tiny raster assets without resending the image payload.
    ///
    /// Sends `spriteUpload,format=png,...` with the image as base64.
    ///
    /// - Parameters:
    ///   - id: The asset id, ASCII letters, digits, `-` and `_`, up to 64
    ///     characters. An invalid id is reported to `commandRejectedHandler`
    ///     as `badId` and nothing is sent.
    ///   - width: Asset width in pixels.
    ///   - height: Asset height in pixels.
    ///   - pngData: The encoded PNG file.
    ///   - filter: Sampling used when the sprite is scaled.
    public func uploadSprite(
        id: String,
        width: Int,
        height: Int,
        pngData: Data,
        filter: VTGSpriteFilter = .smooth
    ) {
        guard isValidVTGIdentifier(id) else {
            return refuse("spriteUpload", id: id, "badId")
        }
        send("spriteUpload,id=\(id),format=png,width=\(width),height=\(height),filter=\(filter.rawValue)", payload: pngData.base64EncodedString())
    }

    /// Upload a JPEG sprite image without placing it.
    ///
    /// Sends `spriteUpload,format=jpeg,...` with the image as base64.
    ///
    /// - Parameters:
    ///   - id: The asset id, ASCII letters, digits, `-` and `_`, up to 64
    ///     characters. An invalid id is reported to `commandRejectedHandler`
    ///     as `badId` and nothing is sent.
    ///   - width: Asset width in pixels.
    ///   - height: Asset height in pixels.
    ///   - jpegData: The encoded JPEG file.
    ///   - filter: Sampling used when the sprite is scaled.
    public func uploadSprite(
        id: String,
        width: Int,
        height: Int,
        jpegData: Data,
        filter: VTGSpriteFilter = .smooth
    ) {
        guard isValidVTGIdentifier(id) else {
            return refuse("spriteUpload", id: id, "badId")
        }
        send("spriteUpload,id=\(id),format=jpeg,width=\(width),height=\(height),filter=\(filter.rawValue)", payload: jpegData.base64EncodedString())
    }

    /// Upload a vector sprite asset without placing it.
    ///
    /// Vector sprites use the same retained sprite instance and transform
    /// commands as bitmap sprites. The first protocol slice stores one
    /// constrained VTG path payload per asset.
    ///
    /// - Parameters:
    ///   - id: The asset id, ASCII letters, digits, `-` and `_`, up to 64
    ///     characters. An invalid id is reported to `commandRejectedHandler`
    ///     as `badId` and nothing is sent.
    ///   - width: Asset width in pixels.
    ///   - height: Asset height in pixels.
    ///   - path: Path data (`M`, `L`, `Q`, `C`, `Z`) in asset pixel coordinates,
    ///     sent as the payload.
    ///   - stroke: Outline color; nil omits `stroke=`.
    ///   - fill: Interior color; nil omits `fill=`.
    ///   - lineWidth: Outline width in pixels.
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
            return refuse("vectorSpriteUpload", id: id, "badId")
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
    ///
    /// Sends `spriteDataUpload,...`. A bad size, empty palette, or wrong pixel
    /// count is reported to `commandRejectedHandler` (`badSize`, `badPalette`,
    /// `badData`) and nothing is sent.
    ///
    /// - Parameters:
    ///   - id: The asset id, ASCII letters, digits, `-` and `_`, up to 64
    ///     characters. An invalid id is reported to `commandRejectedHandler`
    ///     as `badId` and nothing is sent.
    ///   - width: Asset width in pixels; must be positive.
    ///   - height: Asset height in pixels; must be positive.
    ///   - pixels: Palette indexes in row order; exactly `width * height` entries.
    ///   - palette: The colors the indexes refer to; must not be empty.
    ///   - transparentIndex: The index drawn as transparent; nil draws every pixel.
    ///   - filter: Sampling used when the sprite is scaled.
    public func uploadSprite(
        id: String,
        width: Int,
        height: Int,
        pixels: [Int],
        palette: [VTGColor],
        transparentIndex: Int? = nil,
        filter: VTGSpriteFilter = .nearest
    ) {
        guard isValidVTGIdentifier(id) else {
            return refuse("spriteDataUpload", id: id, "badId")
        }
        guard width > 0, height > 0 else {
            return refuse("spriteDataUpload", id: id, "badSize")
        }
        guard palette.isEmpty == false else {
            return refuse("spriteDataUpload", id: id, "badPalette")
        }
        guard pixels.count == width * height else {
            return refuse("spriteDataUpload", id: id, "badData")
        }
        let palettePayload = palette.map(\.rawValue).joined(separator: "|")
        let transparent = transparentIndex.map { ",transparent=\($0)" } ?? ""
        let pixelPayload = pixels.map(String.init).joined(separator: ",")
        send("spriteDataUpload,id=\(id),width=\(width),height=\(height),palette=\(palettePayload)\(transparent),filter=\(filter.rawValue)", payload: pixelPayload)
    }

    /// Named alias for the palette-indexed sprite upload API.
    ///
    /// Calls `uploadSprite(id:width:height:pixels:palette:transparentIndex:filter:)`.
    ///
    /// - Parameters:
    ///   - id: The asset id, ASCII letters, digits, `-` and `_`, up to 64
    ///     characters. An invalid id is reported to `commandRejectedHandler`
    ///     as `badId` and nothing is sent.
    ///   - width: Asset width in pixels; must be positive.
    ///   - height: Asset height in pixels; must be positive.
    ///   - pixels: Palette indexes in row order; exactly `width * height` entries.
    ///   - palette: The colors the indexes refer to; must not be empty.
    ///   - transparentIndex: The index drawn as transparent; nil draws every pixel.
    ///   - filter: Sampling used when the sprite is scaled.
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
    ///
    /// - Parameter id: The asset id. An invalid id sends nothing.
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
