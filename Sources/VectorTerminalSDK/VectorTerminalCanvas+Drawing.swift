import Foundation

/// Immediate-mode VTG polyline, curve, path, and text drawing commands.
extension VectorTerminalCanvas {
    /// Draw or replace a connected polyline from an arbitrary list of points.
    ///
    /// Sends `draw,...` with the points as a space-separated `x,y` payload.
    /// Fewer than two points sends nothing.
    ///
    /// - Parameters:
    ///   - id: The retained primitive id; drawing again with the same id replaces it.
    ///   - points: The vertices in order, in pixels; needs at least two.
    ///   - stroke: Line color.
    ///   - width: Line width in pixels.
    ///   - lineCap: Stroke end style; nil keeps the renderer's default.
    ///   - lineJoin: Stroke corner style; nil keeps the renderer's default.
    ///   - layer: Graphics layer, `-1...4`. Nil, or an unsupported value, omits
    ///     `layer=` so the primitive lands on the default layer.
    public func draw(
        id: String,
        points: [VTGPoint],
        stroke: VTGColor = .white,
        width: Int = 1,
        lineCap: VTGLineCap? = nil,
        lineJoin: VTGLineJoin? = nil,
        layer: Int? = nil
    ) {
        guard points.count >= 2 else {
            return
        }
        let payload = points.map { "\($0.x),\($0.y)" }.joined(separator: " ")
        send("draw,id=\(id),stroke=\(stroke.rawValue),width=\(width)\(strokeStyleParameters(lineCap: lineCap, lineJoin: lineJoin))\(layerParameter(layer))", payload: payload)
    }

    /// Draw or replace a quadratic Bezier curve.
    ///
    /// Sends `curve,kind=quadratic,...`.
    ///
    /// - Parameters:
    ///   - id: The retained primitive id; drawing again with the same id replaces it.
    ///   - x1: Start x, in pixels.
    ///   - y1: Start y, in pixels.
    ///   - cx: Control point x, in pixels.
    ///   - cy: Control point y, in pixels.
    ///   - x2: End x, in pixels.
    ///   - y2: End y, in pixels.
    ///   - stroke: Curve color.
    ///   - width: Line width in pixels.
    ///   - lineCap: Stroke end style; nil keeps the renderer's default.
    ///   - lineJoin: Stroke corner style; nil keeps the renderer's default.
    ///   - layer: Graphics layer, `-1...4`. Nil, or an unsupported value, omits
    ///     `layer=` so the primitive lands on the default layer.
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
        lineCap: VTGLineCap? = nil,
        lineJoin: VTGLineJoin? = nil,
        layer: Int? = nil
    ) {
        send("curve,id=\(id),kind=quadratic,x1=\(x1),y1=\(y1),cx=\(cx),cy=\(cy),x2=\(x2),y2=\(y2),stroke=\(stroke.rawValue),width=\(width)\(strokeStyleParameters(lineCap: lineCap, lineJoin: lineJoin))\(layerParameter(layer))")
    }

    /// Draw or replace a cubic Bezier curve.
    ///
    /// Sends `curve,kind=cubic,...`.
    ///
    /// - Parameters:
    ///   - id: The retained primitive id; drawing again with the same id replaces it.
    ///   - x1: Start x, in pixels.
    ///   - y1: Start y, in pixels.
    ///   - c1x: First control point x, in pixels.
    ///   - c1y: First control point y, in pixels.
    ///   - c2x: Second control point x, in pixels.
    ///   - c2y: Second control point y, in pixels.
    ///   - x2: End x, in pixels.
    ///   - y2: End y, in pixels.
    ///   - stroke: Curve color.
    ///   - width: Line width in pixels.
    ///   - lineCap: Stroke end style; nil keeps the renderer's default.
    ///   - lineJoin: Stroke corner style; nil keeps the renderer's default.
    ///   - layer: Graphics layer, `-1...4`. Nil, or an unsupported value, omits
    ///     `layer=` so the primitive lands on the default layer.
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
        lineCap: VTGLineCap? = nil,
        lineJoin: VTGLineJoin? = nil,
        layer: Int? = nil
    ) {
        send("curve,id=\(id),kind=cubic,x1=\(x1),y1=\(y1),c1x=\(c1x),c1y=\(c1y),c2x=\(c2x),c2y=\(c2y),x2=\(x2),y2=\(y2),stroke=\(stroke.rawValue),width=\(width)\(strokeStyleParameters(lineCap: lineCap, lineJoin: lineJoin))\(layerParameter(layer))")
    }

    /// Draw or replace a constrained absolute SVG-like path.
    ///
    /// Supported commands are `M`, `L`, `Q`, `C`, and `Z`.
    ///
    /// - Parameters:
    ///   - id: The retained primitive id; drawing again with the same id replaces it.
    ///   - payload: Path data in absolute pixel coordinates. ESC and BEL are
    ///     stripped before sending.
    ///   - stroke: Outline color; nil sends `none`, drawing no outline.
    ///   - fill: Interior color; nil (the default) sends `none`, leaving it unfilled.
    ///   - lineWidth: Stroke width in pixels, sent as `width=`.
    ///   - lineCap: Stroke end style; nil keeps the renderer's default.
    ///   - lineJoin: Stroke corner style; nil keeps the renderer's default.
    ///   - layer: Graphics layer, `-1...4`. Nil, or an unsupported value, omits
    ///     `layer=` so the primitive lands on the default layer.
    public func path(
        id: String,
        payload: String,
        stroke: VTGColor? = .white,
        fill: VTGColor? = nil,
        lineWidth: Int = 1,
        lineCap: VTGLineCap? = nil,
        lineJoin: VTGLineJoin? = nil,
        layer: Int? = nil
    ) {
        let strokeValue = stroke?.rawValue ?? "none"
        let fillValue = fill?.rawValue ?? "none"
        send("path,id=\(id),stroke=\(strokeValue),fill=\(fillValue),width=\(lineWidth)\(strokeStyleParameters(lineCap: lineCap, lineJoin: lineJoin))\(layerParameter(layer))", payload: sanitizedPayload(payload))
    }

    /// Draw or replace host-rendered text in pixel coordinates.
    ///
    /// - Parameters:
    ///   - id: The retained primitive id; drawing again with the same id replaces it.
    ///   - x: Left edge, in pixels.
    ///   - y: Top edge, in pixels.
    ///   - value: The text to draw. ESC and BEL are stripped before sending.
    ///   - color: Text color.
    ///   - size: Font size in pixels.
    ///   - layer: Graphics layer, `-1...4`. Nil, or an unsupported value, omits
    ///     `layer=` so the primitive lands on the default layer.
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

}
