import Foundation

/// Immediate-mode VTG drawing commands.
extension VectorTerminalCanvas {
    /// Clear all retained VTG primitives from the terminal overlay.
    public func clear() {
        send("clear")
    }

    /// Request presentation of the current VTG scene.
    public func present() {
        send("present")
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

    /// Draw or replace a single pixel.
    public func pixel(
        id: String,
        x: Int,
        y: Int,
        color: VTGColor = .white,
        layer: Int? = nil
    ) {
        send("pixel,id=\(id),x=\(x),y=\(y),color=\(color.rawValue)\(layerParameter(layer))")
    }

    /// Draw or replace a line segment.
    public func line(
        id: String,
        x1: Int,
        y1: Int,
        x2: Int,
        y2: Int,
        stroke: VTGColor = .white,
        width: Int = 1,
        layer: Int? = nil
    ) {
        send("line,id=\(id),x1=\(x1),y1=\(y1),x2=\(x2),y2=\(y2),stroke=\(stroke.rawValue),width=\(width)\(layerParameter(layer))")
    }

    /// Draw or replace a connected polyline from an arbitrary list of points.
    public func draw(
        id: String,
        points: [VTGPoint],
        stroke: VTGColor = .white,
        width: Int = 1,
        layer: Int? = nil
    ) {
        guard points.count >= 2 else {
            return
        }
        let payload = points.map { "\($0.x),\($0.y)" }.joined(separator: " ")
        send("draw,id=\(id),stroke=\(stroke.rawValue),width=\(width)\(layerParameter(layer))", payload: payload)
    }

    /// Draw or replace a quadratic Bezier curve.
    public func quadraticCurve(
        id: String,
        x1: Int,
        y1: Int,
        cx: Int,
        cy: Int,
        x2: Int,
        y2: Int,
        stroke: VTGColor = .white,
        width: Int = 1,
        layer: Int? = nil
    ) {
        send("curve,id=\(id),kind=quadratic,x1=\(x1),y1=\(y1),cx=\(cx),cy=\(cy),x2=\(x2),y2=\(y2),stroke=\(stroke.rawValue),width=\(width)\(layerParameter(layer))")
    }

    /// Draw or replace a cubic Bezier curve.
    public func cubicCurve(
        id: String,
        x1: Int,
        y1: Int,
        c1x: Int,
        c1y: Int,
        c2x: Int,
        c2y: Int,
        x2: Int,
        y2: Int,
        stroke: VTGColor = .white,
        width: Int = 1,
        layer: Int? = nil
    ) {
        send("curve,id=\(id),kind=cubic,x1=\(x1),y1=\(y1),c1x=\(c1x),c1y=\(c1y),c2x=\(c2x),c2y=\(c2y),x2=\(x2),y2=\(y2),stroke=\(stroke.rawValue),width=\(width)\(layerParameter(layer))")
    }

    /// Draw or replace a triangle.
    public func triangle(
        id: String,
        p1: VTGPoint,
        p2: VTGPoint,
        p3: VTGPoint,
        stroke: VTGColor? = .white,
        fill: VTGColor? = nil,
        lineWidth: Int = 1,
        layer: Int? = nil
    ) {
        let strokeValue = stroke?.rawValue ?? "none"
        let fillValue = fill?.rawValue ?? "none"
        send("triangle,id=\(id),x1=\(p1.x),y1=\(p1.y),x2=\(p2.x),y2=\(p2.y),x3=\(p3.x),y3=\(p3.y),stroke=\(strokeValue),fill=\(fillValue),width=\(lineWidth)\(layerParameter(layer))")
    }

    /// Draw or replace a constrained absolute SVG-like path.
    ///
    /// Supported commands are `M`, `L`, `Q`, `C`, and `Z`.
    public func path(
        id: String,
        payload: String,
        stroke: VTGColor? = .white,
        fill: VTGColor? = nil,
        lineWidth: Int = 1,
        layer: Int? = nil
    ) {
        let strokeValue = stroke?.rawValue ?? "none"
        let fillValue = fill?.rawValue ?? "none"
        send("path,id=\(id),stroke=\(strokeValue),fill=\(fillValue),width=\(lineWidth)\(layerParameter(layer))", payload: sanitizedPayload(payload))
    }

    /// Draw or replace a rectangle.
    public func rect(
        id: String,
        x: Int,
        y: Int,
        width: Int,
        height: Int,
        stroke: VTGColor? = .white,
        fill: VTGColor? = nil,
        lineWidth: Int = 1,
        layer: Int? = nil
    ) {
        let strokeValue = stroke?.rawValue ?? "none"
        let fillValue = fill?.rawValue ?? "none"
        send("rect,id=\(id),x=\(x),y=\(y),w=\(width),h=\(height),stroke=\(strokeValue),fill=\(fillValue),width=\(lineWidth)\(layerParameter(layer))")
    }

    /// Draw or replace a circle.
    public func circle(
        id: String,
        cx: Int,
        cy: Int,
        radius: Int,
        stroke: VTGColor? = .white,
        fill: VTGColor? = nil,
        lineWidth: Int = 1,
        layer: Int? = nil
    ) {
        let strokeValue = stroke?.rawValue ?? "none"
        let fillValue = fill?.rawValue ?? "none"
        send("circle,id=\(id),cx=\(cx),cy=\(cy),r=\(radius),stroke=\(strokeValue),fill=\(fillValue),width=\(lineWidth)\(layerParameter(layer))")
    }

    /// Draw or replace an ellipse.
    public func ellipse(
        id: String,
        cx: Int,
        cy: Int,
        rx: Int,
        ry: Int,
        stroke: VTGColor? = .white,
        fill: VTGColor? = nil,
        lineWidth: Int = 1,
        layer: Int? = nil
    ) {
        let strokeValue = stroke?.rawValue ?? "none"
        let fillValue = fill?.rawValue ?? "none"
        send("ellipse,id=\(id),cx=\(cx),cy=\(cy),rx=\(rx),ry=\(ry),stroke=\(strokeValue),fill=\(fillValue),width=\(lineWidth)\(layerParameter(layer))")
    }

    /// Draw or replace host-rendered text in pixel coordinates.
    public func text(
        id: String,
        x: Int,
        y: Int,
        value: String,
        color: VTGColor = .white,
        size: Int = 14,
        layer: Int? = nil
    ) {
        send("text,id=\(id),x=\(x),y=\(y),color=\(color.rawValue),size=\(size)\(layerParameter(layer))", payload: sanitizedPayload(value))
    }

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

    /// Draw ASCII text using the SDK's vector glyph strokes.
    ///
    /// This intentionally uses VTG `draw` segments rather than font rendering
    /// so demos can prove arbitrary vector primitives are enough for text-like
    /// output. Non-printing ASCII values render as a box with the numeric code.
    public func vectorPrint(
        id: String,
        x: Int,
        y: Int,
        height: Int,
        value: String,
        stroke: VTGColor = .white,
        width: Int = 2,
        layer: Int? = nil
    ) {
        let scale = max(1.0, Double(height) / 7.0)
        let glyphWidth = Int((5.0 * scale).rounded())
        let advance = Int((7.0 * scale).rounded())
        var cursorX = x
        var glyphIndex = 0

        for scalar in value.unicodeScalars {
            let ascii = Int(scalar.value)
            if ascii == 32 {
                cursorX += advance
                continue
            }
            let strokes = vectorGlyphStrokes(for: ascii)
            for (strokeIndex, strokePoints) in strokes.enumerated() {
                let points = strokePoints.map {
                    VTGPoint(
                        x: cursorX + Int((Double($0.x) * scale).rounded()),
                        y: y + Int((Double($0.y) * scale).rounded())
                    )
                }
                draw(id: "\(id)-\(glyphIndex)-\(strokeIndex)", points: points, stroke: stroke, width: width, layer: layer)
            }
            if ascii < 32 || ascii == 127 {
                let code = String(ascii)
                let smallHeight = max(5, Int(Double(height) * 0.34))
                vectorPrint(id: "\(id)-code-\(glyphIndex)", x: cursorX + glyphWidth / 5, y: y + height / 3, height: smallHeight, value: code, stroke: stroke, width: max(1, width - 1), layer: layer)
            }
            cursorX += advance
            glyphIndex += 1
        }
    }

}

private extension VectorTerminalCanvas {
    /// VTG ids intentionally stay conservative so apps can embed them directly
    /// in comma-separated escape parameters without quoting rules.
    func isValidVTGIdentifier(_ value: String) -> Bool {
        guard value.isEmpty == false, value.count <= 64 else {
            return false
        }
        return value.allSatisfy { character in
            character.isASCII && (character.isLetter || character.isNumber)
        }
    }

    /// Compact floating-point parameters for transform-heavy sprite commands.
    func vtgNumber(_ value: Double) -> String {
        let rounded = value.rounded()
        if abs(value - rounded) < 0.001 {
            return String(Int(rounded))
        }
        return String(format: "%.3f", value)
    }

    /// Emit a layer parameter only when the caller asks for a supported layer.
    func layerParameter(_ layer: Int?) -> String {
        guard let layer, isSupportedVTGLayer(layer) else {
            return ""
        }
        return ",layer=\(layer)"
    }

    /// Emit an optional color parameter using the SDK's raw VTG color token.
    func colorParameter(_ name: String, _ color: VTGColor?) -> String {
        guard let color else {
            return ""
        }
        return ",\(name)=\(color.rawValue)"
    }

    /// Keep normalized protocol values inside their legal range.
    func clampedUnit(_ value: Double) -> Double {
        min(1, max(0, value))
    }

    /// Emit an optional normalized numeric parameter.
    func optionalUnitParameter(_ name: String, _ value: Double?) -> String {
        guard let value else {
            return ""
        }
        return ",\(name)=\(vtgNumber(clampedUnit(value)))"
    }

    /// Current prototype supports layer 0 plus four overlay layers.
    func isSupportedVTGLayer(_ layer: Int) -> Bool {
        VTGLayer.isSupported(layer)
    }
}
