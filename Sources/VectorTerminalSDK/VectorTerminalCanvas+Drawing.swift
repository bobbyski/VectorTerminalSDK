import Foundation

/// Immediate-mode VTG polyline, curve, path, and text drawing commands.
extension VectorTerminalCanvas {
    /// Draw or replace a connected polyline from an arbitrary list of points.
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
