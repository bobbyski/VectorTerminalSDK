import Foundation

/// Immediate-mode VTG point and line commands.
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
}
