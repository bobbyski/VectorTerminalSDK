/// Vector-text convenience built on ordinary VTG drawing primitives.
extension VectorTerminalCanvas {
    /// Measure ASCII text drawn by `vectorPrint(...)`.
    ///
    /// The returned width matches the drawing advance consumed by the string,
    /// including spaces and the trailing advance after the final visible glyph.
    /// This makes it useful for centering, right-aligning, or reserving layout
    /// space before drawing. The returned height is the effective glyph height
    /// after applying the same minimum scale as `vectorPrint(...)`.
    public nonisolated static func vectorTextSize(height: Int, value: String) -> VTGTextSize {
        let scale = vectorTextScale(for: height)
        let advance = Int((7.0 * scale).rounded())
        let effectiveHeight = Int((7.0 * scale).rounded())
        return VTGTextSize(width: value.unicodeScalars.count * advance, height: effectiveHeight)
    }

    /// Instance convenience wrapper for `VectorTerminalCanvas.vectorTextSize(...)`.
    public nonisolated func vectorTextSize(height: Int, value: String) -> VTGTextSize {
        Self.vectorTextSize(height: height, value: value)
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
        let scale = Self.vectorTextScale(for: height)
        let glyphWidth = Int((5.0 * scale).rounded())
        let advance = Int((7.0 * scale).rounded())
        var cursorX = x
        var glyphIndex = 0
        var objectIDs: [String] = []

        deleteStringObjects(id: id)

        for scalar in value.unicodeScalars {
            let ascii = Int(scalar.value)
            if ascii == 32 {
                cursorX += advance
                continue
            }

            let strokes = vectorGlyphStrokes(for: ascii)
            for (strokeIndex, strokePoints) in strokes.enumerated() {
                let objectID = "\(id)-\(glyphIndex)-\(strokeIndex)"
                let points = strokePoints.map {
                    VTGPoint(
                        x: cursorX + Int((Double($0.x) * scale).rounded()),
                        y: y + Int((Double($0.y) * scale).rounded())
                    )
                }
                draw(id: objectID, points: points, stroke: stroke, width: width, layer: layer)
                objectIDs.append(objectID)
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

        retainedStringObjectIDs[id] = objectIDs
    }

    /// Delete all retained primitives emitted by the last `vectorPrint(...)`
    /// call with this base id.
    public func deleteVectorText(id: String) {
        deleteStringObjects(id: id)
    }

    /// Shared vector-text scale calculation used by measuring and rendering.
    private nonisolated static func vectorTextScale(for height: Int) -> Double {
        max(1.0, Double(height) / 7.0)
    }
}
