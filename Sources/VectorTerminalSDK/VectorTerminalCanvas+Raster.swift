import Foundation

/// Immediate-mode VTG raster drawing commands.
extension VectorTerminalCanvas {
    /// Upload and place a retained PNG image.
    ///
    /// Direct images remain useful for static raster content. Use sprite
    /// helpers when an asset needs cheap move/rotate/scale operations.
    ///
    /// Sends `image,format=png,...` with the image as base64.
    ///
    /// - Parameters:
    ///   - id: The retained image id; drawing again with the same id replaces it.
    ///   - x: Left edge, in pixels.
    ///   - y: Top edge, in pixels.
    ///   - width: Drawn width in pixels.
    ///   - height: Drawn height in pixels.
    ///   - pngData: The encoded PNG file.
    ///   - filter: Sampling used when the image is scaled.
    ///   - layer: Graphics layer, `-1...4`. Nil, or an unsupported value, omits
    ///     `layer=` so the primitive lands on the default layer.
    public func image(
        id: String,
        x: Int = 0,
        y: Int = 0,
        width: Int,
        height: Int,
        pngData: Data,
        filter: VTGSpriteFilter = .smooth,
        layer: Int? = nil
    ) {
        send("image,id=\(id),format=png,x=\(x),y=\(y),width=\(width),height=\(height),filter=\(filter.rawValue)\(layerParameter(layer))", payload: pngData.base64EncodedString())
    }

    /// Upload and place a retained JPEG image.
    ///
    /// Sends `image,format=jpeg,...` with the image as base64.
    ///
    /// - Parameters:
    ///   - id: The retained image id; drawing again with the same id replaces it.
    ///   - x: Left edge, in pixels.
    ///   - y: Top edge, in pixels.
    ///   - width: Drawn width in pixels.
    ///   - height: Drawn height in pixels.
    ///   - jpegData: The encoded JPEG file.
    ///   - filter: Sampling used when the image is scaled.
    ///   - layer: Graphics layer, `-1...4`. Nil, or an unsupported value, omits
    ///     `layer=` so the primitive lands on the default layer.
    public func image(
        id: String,
        x: Int = 0,
        y: Int = 0,
        width: Int,
        height: Int,
        jpegData: Data,
        filter: VTGSpriteFilter = .smooth,
        layer: Int? = nil
    ) {
        send("image,id=\(id),format=jpeg,x=\(x),y=\(y),width=\(width),height=\(height),filter=\(filter.rawValue)\(layerParameter(layer))", payload: jpegData.base64EncodedString())
    }
}
