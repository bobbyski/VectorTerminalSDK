import Foundation

/// Immediate-mode VTG point and enclosed shape commands.
extension VectorTerminalCanvas {
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
        lineCap: VTGLineCap? = nil,
        layer: Int? = nil
    ) {
        send("line,id=\(id),x1=\(x1),y1=\(y1),x2=\(x2),y2=\(y2),stroke=\(stroke.rawValue),width=\(width)\(strokeStyleParameters(lineCap: lineCap))\(layerParameter(layer))")
    }

    /// Draw or replace a sharp or rounded triangle.
    ///
    /// `radius` trims each vertex along its adjacent edges and lets the
    /// terminal curve through the original point. Oversized radii are clamped
    /// per corner by the terminal renderer.
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
    /// The terminal clamps oversized radii to half of the smaller rectangle
    /// side so callers can use a generous value without hand-computing caps.
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
        lineJoin: VTGLineJoin? = nil,
        layer: Int? = nil
    ) {
        let strokeValue = stroke?.rawValue ?? "none"
        let fillValue = fill?.rawValue ?? "none"
        let radiusParameter = radius > 0 ? ",radius=\(radius)" : ""
        send("rect,id=\(id),x=\(x),y=\(y),w=\(width),h=\(height),stroke=\(strokeValue),fill=\(fillValue),width=\(lineWidth)\(radiusParameter)\(strokeStyleParameters(lineJoin: lineJoin))\(layerParameter(layer))")
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
}
