/// Small terminal-cell-aligned UI helpers.
extension VectorTerminalCanvas {
    /// Draw a filled pill behind regular terminal text at the current cursor.
    ///
    /// The label starts at the current terminal cursor. The pill extends one
    /// cell left of that cursor and one cell right of the visible text. The
    /// graphics rectangle is drawn on the under-text layer by default, then
    /// the label is written as ordinary terminal text. No SDK vector text is
    /// emitted.
    ///
    /// - Returns: The pixel-space rectangle used for the pill, or nil if the
    ///   cursor position or terminal glyph size could not be determined.
    @discardableResult
    public func pillButton(
        id: String,
        text: String,
        glyphSize: TerminalGlyphSize? = nil,
        fill: VTGColor = "#0f766eFF",
        stroke: VTGColor? = nil,
        lineWidth: Int = 1,
        layer: Int? = VTGLayer.underText,
        target: String? = nil,
        timeoutMilliseconds: Int = 750
    ) -> VTGPillButtonLayout? {
        guard isValidVTGIdentifier(id), text.isEmpty == false else {
            return nil
        }
        guard let position = queryCursorPosition(timeoutMilliseconds: timeoutMilliseconds) else {
            return nil
        }
        let glyph = glyphSize ?? queryTerminalWSize(timeoutMilliseconds: timeoutMilliseconds)
        guard let glyph, glyph.width > 0, glyph.height > 0 else {
            return nil
        }

        let cellWidth = max(1, glyph.width)
        let cellHeight = max(1, glyph.height)
        let textCells = max(1, text.unicodeScalars.count)
        let pillColumn = max(1, position.column - 1)
        let x = Int((Double(pillColumn - 1) * cellWidth).rounded())
        let y = Int((Double(position.row - 1) * cellHeight).rounded())
        let width = max(1, Int((Double(textCells + 2) * cellWidth).rounded()))
        let height = max(1, Int(cellHeight.rounded()))
        let radius = max(1, height / 2)

        rect(
            id: "\(id)-pill",
            x: x,
            y: y,
            width: width,
            height: height,
            stroke: stroke,
            fill: fill,
            lineWidth: max(1, lineWidth),
            radius: radius,
            layer: layer
        )

        writeText(text)
        setCursor(row: position.row, column: position.column + textCells + 1)

        if let target {
            hitRegion(id: "\(id)-hit", x: x, y: y, width: width, height: height, layer: layer, target: target)
        }

        return VTGPillButtonLayout(x: x, y: y, width: width, height: height, row: position.row, column: pillColumn)
    }
}
