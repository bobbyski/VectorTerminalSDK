import Foundation

/// Immediate-mode VTG raster drawing commands.
extension VectorTerminalCanvas {
    /// Upload and place a retained PNG image.
    ///
    /// Direct images remain useful for static raster content. Use sprite
    /// helpers when an asset needs cheap move/rotate/scale operations.
    public func image(
        id: String,
        x: Int = 0,
        y: Int = 0,
        width: Int,
        height: Int,
        pngData: Data,
        layer: Int? = nil
    ) {
        send("image,id=\(id),format=png,x=\(x),y=\(y),width=\(width),height=\(height)\(layerParameter(layer))", payload: pngData.base64EncodedString())
    }

    /// Upload and place a retained JPEG image.
    public func image(
        id: String,
        x: Int = 0,
        y: Int = 0,
        width: Int,
        height: Int,
        jpegData: Data,
        layer: Int? = nil
    ) {
        send("image,id=\(id),format=jpeg,x=\(x),y=\(y),width=\(width),height=\(height)\(layerParameter(layer))", payload: jpegData.base64EncodedString())
    }
}
