/// Filled LED alphabet convenience built on VTG path primitives.
extension VectorTerminalCanvas {
    /// Measure text drawn by `ledPrint(...)`.
    ///
    /// The LED alphabet is drawn on a 10x16 design grid with a 12-unit advance.
    /// The returned width includes the trailing advance after the final glyph,
    /// matching the space consumed by `ledPrint(...)`.
    public nonisolated static func ledTextSize(height: Int, value: String) -> VTGTextSize {
        let scale = ledTextScale(for: height)
        let advance = Int((LEDGlyphs.advance * scale).rounded())
        let effectiveHeight = Int((LEDGlyphs.designHeight * scale).rounded())
        return VTGTextSize(width: value.unicodeScalars.count * advance, height: effectiveHeight)
    }

    /// Instance convenience wrapper for `VectorTerminalCanvas.ledTextSize(...)`.
    public nonisolated func ledTextSize(height: Int, value: String) -> VTGTextSize {
        Self.ledTextSize(height: height, value: value)
    }

    /// Draw ASCII text with the SDK's filled LED alphabet.
    ///
    /// Each lit segment is emitted as a retained filled VTG path. Set
    /// `inactiveColor` to draw the unlit segments too, which creates a dim
    /// display-glass effect. Leave it nil for only the visible LED letters.
    public func ledPrint(
        id: String,
        x: Int,
        y: Int,
        height: Int,
        value: String,
        color: VTGColor = "#B7FF2AFF",
        inactiveColor: VTGColor? = nil,
        stroke: VTGColor? = nil,
        lineWidth: Int = 1,
        layer: Int? = nil
    ) {
        let scale = Self.ledTextScale(for: height)
        let advance = Int((LEDGlyphs.advance * scale).rounded())
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

            let litSegments = LEDGlyphs.segments(for: ascii)
            for segment in LEDGlyphs.allSegments {
                let isLit = litSegments.contains(segment.name)
                guard isLit || inactiveColor != nil else {
                    continue
                }
                let objectID = "\(id)-\(glyphIndex)-\(segment.name)"
                path(
                    id: objectID,
                    payload: ledPathPayload(segment.points, x: cursorX, y: y, scale: scale),
                    stroke: stroke,
                    fill: isLit ? color : inactiveColor,
                    lineWidth: lineWidth,
                    lineJoin: .round,
                    layer: layer
                )
                objectIDs.append(objectID)
            }

            cursorX += advance
            glyphIndex += 1
        }

        retainedStringObjectIDs[id] = objectIDs
    }

    /// Delete all retained primitives emitted by the last `ledPrint(...)`
    /// call with this base id.
    public func deleteLEDText(id: String) {
        deleteStringObjects(id: id)
    }

    /// Alias for callers that think of segmented LED text as LCD text.
    public func deleteLCDText(id: String) {
        deleteLEDText(id: id)
    }

    private nonisolated static func ledTextScale(for height: Int) -> Double {
        max(1.0, Double(height) / LEDGlyphs.designHeight)
    }

    private nonisolated func ledPathPayload(_ points: [LEDPoint], x: Int, y: Int, scale: Double) -> String {
        points.enumerated().map { index, point in
            let command = index == 0 ? "M" : "L"
            let px = x + Int((point.x * scale).rounded())
            let py = y + Int((point.y * scale).rounded())
            return "\(command) \(px) \(py)"
        }
        .joined(separator: " ") + " Z"
    }
}
