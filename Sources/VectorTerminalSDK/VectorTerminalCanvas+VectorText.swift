/// Vector-text convenience built on ordinary VTG drawing primitives.
extension VectorTerminalCanvas {
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
                vectorPrint(
                    id: "\(id)-code-\(glyphIndex)",
                    x: cursorX + glyphWidth / 5,
                    y: y + height / 3,
                    height: smallHeight,
                    value: code,
                    stroke: stroke,
                    width: max(1, width - 1),
                    layer: layer
                )
            }

            cursorX += advance
            glyphIndex += 1
        }
    }
}
