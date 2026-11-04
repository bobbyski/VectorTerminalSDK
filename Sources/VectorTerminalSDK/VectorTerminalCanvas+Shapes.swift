import Foundation

/// Immediate-mode VTG enclosed shape commands.
extension VectorTerminalCanvas {
    /// Clear a retained rectangular graphics region back to transparent pixels.
    ///
    /// This is not a background-colored rectangle. `clearRect` composes as an
    /// eraser in retained order, so earlier primitives on the same graphics
    /// plane disappear inside the rectangle while later primitives can still
    /// draw over it. The command is intended for partial redraw, sprite trails,
    /// and lightweight UI panel refreshes.
    ///
    /// An invalid id, or a zero or negative size, sends nothing.
    ///
    /// - Parameters:
    ///   - id: The retained id of the clear operation; reusing it replaces it.
    ///   - x: Left edge, in pixels.
    ///   - y: Top edge, in pixels.
    ///   - width: Width in pixels; must be positive.
    ///   - height: Height in pixels; must be positive.
    ///   - layer: Graphics layer to clear, `-1...4`. Nil, or an unsupported value,
    ///     omits `layer=` so the default layer is used.
    public func clearRect(
        id: String,
        x: Int,
        y: Int,
        width: Int,
        height: Int,
        layer: Int? = nil
    ) {
        guard isValidVTGIdentifier(id), width > 0, height > 0 else {
            return
        }
        send("clearRect,id=\(id),x=\(x),y=\(y),w=\(width),h=\(height)\(layerParameter(layer))")
    }

    /// Draw or replace a sharp or rounded triangle.
    ///
    /// `radius` trims each vertex along its adjacent edges and lets the
    /// terminal curve through the original point. Oversized radii are clamped
    /// per corner by the terminal renderer.
    ///
    /// - Parameters:
    ///   - id: The retained primitive id; drawing again with the same id replaces it.
    ///   - p1: First vertex, in pixels.
    ///   - p2: Second vertex, in pixels.
    ///   - p3: Third vertex, in pixels.
    ///   - stroke: Outline color; nil sends `none`, drawing no outline.
    ///   - fill: Interior color; nil (the default) sends `none`, leaving it unfilled.
    ///   - lineWidth: Outline width in pixels, sent as `width=`.
    ///   - radius: Corner rounding in pixels; zero (the default) leaves sharp
    ///     corners and omits `radius=`.
    ///   - lineJoin: Stroke corner style; nil keeps the renderer's default.
    ///   - layer: Graphics layer, `-1...4`. Nil, or an unsupported value, omits
    ///     `layer=` so the primitive lands on the default layer.
    public func triangle(
        id: String,
        p1: VTGPoint,
        p2: VTGPoint,
        p3: VTGPoint,
        stroke: VTGColor? = .white,
        fill: VTGColor? = nil,
        lineWidth: Int = 1,
        radius: Int = 0,
        lineJoin: VTGLineJoin? = nil,
        layer: Int? = nil
    ) {
        let strokeValue = stroke?.rawValue ?? "none"
        let fillValue = fill?.rawValue ?? "none"
        let radiusParameter = radius > 0 ? ",radius=\(radius)" : ""
        send("triangle,id=\(id),x1=\(p1.x),y1=\(p1.y),x2=\(p2.x),y2=\(p2.y),x3=\(p3.x),y3=\(p3.y),stroke=\(strokeValue),fill=\(fillValue),width=\(lineWidth)\(radiusParameter)\(strokeStyleParameters(lineJoin: lineJoin))\(layerParameter(layer))")
    }

    /// Draw or replace a sharp or rounded rectangle.
    ///
    /// `radius` is optional and is omitted from the wire command when zero.
    /// `corners` can limit rounding to specific corners using VTG rectangle
    /// digits: 1 top-left, 2 top-right, 3 bottom-right, and 4 bottom-left.
    /// Passing nil preserves the default behavior and rounds every corner.
    /// The terminal clamps oversized radii to half of the smaller rectangle
    /// side so callers can use a generous value without hand-computing caps.
    ///
    /// - Parameters:
    ///   - id: The retained primitive id; drawing again with the same id replaces it.
    ///   - x: Left edge, in pixels.
    ///   - y: Top edge, in pixels.
    ///   - width: Width in pixels, sent as `w=`.
    ///   - height: Height in pixels, sent as `h=`.
    ///   - stroke: Outline color; nil sends `none`, drawing no outline.
    ///   - fill: Interior color; nil (the default) sends `none`, leaving it unfilled.
    ///   - lineWidth: Outline width in pixels, sent as `width=`.
    ///   - radius: Corner radius in pixels; zero leaves sharp corners.
    ///   - corners: Digits `1`-`4` naming the corners to round, such as `"12"`.
    ///     Other characters and repeats are dropped; nil, or no valid digit,
    ///     rounds every corner.
    ///   - lineJoin: Stroke corner style; nil keeps the renderer's default.
    ///   - layer: Graphics layer, `-1...4`. Nil, or an unsupported value, omits
    ///     `layer=` so the primitive lands on the default layer.
    public func rect(
        id: String,
        x: Int,
        y: Int,
        width: Int,
        height: Int,
        stroke: VTGColor? = .white,
        fill: VTGColor? = nil,
        lineWidth: Int = 1,
        radius: Int = 0,
        corners: String? = nil,
        lineJoin: VTGLineJoin? = nil,
        layer: Int? = nil
    ) {
        let strokeValue = stroke?.rawValue ?? "none"
        let fillValue = fill?.rawValue ?? "none"
        let radiusParameter = radius > 0 ? ",radius=\(radius)" : ""
        let cornersParameter = sanitizedRectCorners(corners).map { ",corners=\($0)" } ?? ""
        send("rect,id=\(id),x=\(x),y=\(y),w=\(width),h=\(height),stroke=\(strokeValue),fill=\(fillValue),width=\(lineWidth)\(radiusParameter)\(cornersParameter)\(strokeStyleParameters(lineJoin: lineJoin))\(layerParameter(layer))")
    }

    /// Draw or replace a circle.
    ///
    /// - Parameters:
    ///   - id: The retained primitive id; drawing again with the same id replaces it.
    ///   - cx: Center x, in pixels.
    ///   - cy: Center y, in pixels.
    ///   - radius: Radius in pixels, sent as `r=`.
    ///   - stroke: Outline color; nil sends `none`, drawing no outline.
    ///   - fill: Interior color; nil (the default) sends `none`, leaving it unfilled.
    ///   - lineWidth: Outline width in pixels, sent as `width=`.
    ///   - layer: Graphics layer, `-1...4`. Nil, or an unsupported value, omits
    ///     `layer=` so the primitive lands on the default layer.
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
    ///
    /// - Parameters:
    ///   - id: The retained primitive id; drawing again with the same id replaces it.
    ///   - cx: Center x, in pixels.
    ///   - cy: Center y, in pixels.
    ///   - rx: Horizontal radius in pixels.
    ///   - ry: Vertical radius in pixels.
    ///   - stroke: Outline color; nil sends `none`, drawing no outline.
    ///   - fill: Interior color; nil (the default) sends `none`, leaving it unfilled.
    ///   - lineWidth: Outline width in pixels, sent as `width=`.
    ///   - layer: Graphics layer, `-1...4`. Nil, or an unsupported value, omits
    ///     `layer=` so the primitive lands on the default layer.
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
}

private func sanitizedRectCorners(_ value: String?) -> String? {
    guard let value else {
        return nil
    }
    var seen = Set<Character>()
    let digits = value.compactMap { character -> Character? in
        guard "1234".contains(character), seen.insert(character).inserted else {
            return nil
        }
        return character
    }
    guard digits.isEmpty == false else {
        return nil
    }
    return String(digits)
}
