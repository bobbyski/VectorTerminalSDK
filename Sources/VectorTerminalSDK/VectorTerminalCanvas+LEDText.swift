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
    ///
    /// - Parameters:
    ///   - height: The requested glyph height, in pixels; heights under 16 measure as 16.
    ///   - value: The text to measure; every Unicode scalar counts as one advance.
    /// - Returns: The advance width and effective glyph height, in pixels.
    public nonisolated func ledTextSize(height: Int, value: String) -> VTGTextSize {
        Self.ledTextSize(height: height, value: value)
    }

    /// Draw ASCII text with the SDK's filled LED alphabet.
    ///
    /// Each lit segment is emitted as a retained filled VTG path. Set
    /// `inactiveColor` to draw the unlit segments too, which creates a dim
    /// display-glass effect. Leave it nil for only the visible LED letters.
    ///
    /// Each segment is a retained `path` primitive with the id
    /// `<id>-<glyph>-<segment>`. Primitives from the last call with the same
    /// `id` are deleted first.
    ///
    /// - Parameters:
    ///   - id: The base id for the emitted primitives.
    ///   - x: Left edge of the first glyph, in pixels.
    ///   - y: Top edge of the glyphs, in pixels.
    ///   - height: Glyph height, in pixels; heights under 16 draw as 16.
    ///   - value: The text to draw; uppercase letters, digits, space and some punctuation.
    ///   - color: Fill color of lit segments.
    ///   - inactiveColor: Fill color of unlit segments, or `nil` to skip them.
    ///   - stroke: Outline color of each segment, or `nil` for no outline.
    ///   - lineWidth: Outline width, in pixels.
    ///   - layer: The target layer, or `nil` for the default layer.
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
    ///
    /// - Parameter id: The base id passed to `ledPrint(...)`.
    public func deleteLEDText(id: String) {
        deleteStringObjects(id: id)
    }

    /// Alias for callers that think of segmented LED text as LCD text.
    ///
    /// - Parameter id: The base id passed to `ledPrint(...)`.
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
