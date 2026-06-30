import Darwin
import Foundation

/// Terminal text-grid measurement helpers.
extension VectorTerminalCanvas {
    /// Read the terminal's current character grid size.
    ///
    /// This is intentionally separate from `queryCurrentCanvas(...)`: VTG
    /// pixels answer "where can I draw?", while terminal cells answer "what is
    /// the text grid doing?". When the terminal reports pixel dimensions
    /// through `TIOCGWINSZ`, those are included too.
    public func queryTerminalCellSize() -> TerminalCellSize? {
        var windowSize = winsize()
        guard ioctl(input.fileDescriptor, TIOCGWINSZ, &windowSize) == 0,
              windowSize.ws_col > 0,
              windowSize.ws_row > 0 else {
            return nil
        }
        let pixelWidth = windowSize.ws_xpixel > 0 ? Int(windowSize.ws_xpixel) : nil
        let pixelHeight = windowSize.ws_ypixel > 0 ? Int(windowSize.ws_ypixel) : nil
        return TerminalCellSize(
            columns: Int(windowSize.ws_col),
            rows: Int(windowSize.ws_row),
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight
        )
    }

    /// Calculate the pixel width and height of a normal terminal `W`.
    ///
    /// In a monospace terminal, `W` occupies one terminal cell. SwiftTerm-backed
    /// VectorTerminal hosts answer this directly through `VTG;glyphSize?`.
    /// If that query is unavailable, the SDK falls back to `TIOCGWINSZ` pixel
    /// fields and finally to dividing the VTG pixel canvas by terminal rows and
    /// columns. Traditional terminals that do not support VTG and do not report
    /// pixel dimensions return `nil`.
    public func queryTerminalWSize(timeoutMilliseconds: Int = 750) -> TerminalGlyphSize? {
        if let glyphSize = queryTerminalGlyphSize(timeoutMilliseconds: timeoutMilliseconds) {
            return glyphSize
        }
        guard let cellSize = queryTerminalCellSize() else {
            return nil
        }
        if let glyphSize = Self.terminalWSize(from: cellSize) {
            return glyphSize
        }
        guard let canvas = queryCurrentCanvas(timeoutMilliseconds: timeoutMilliseconds) else {
            return nil
        }
        return Self.terminalWSize(from: cellSize, canvas: canvas)
    }

    static func terminalWSize(from cellSize: TerminalCellSize) -> TerminalGlyphSize? {
        guard let pixelWidth = cellSize.pixelWidth,
              let pixelHeight = cellSize.pixelHeight else {
            return nil
        }
        return terminalWSize(
            columns: cellSize.columns,
            rows: cellSize.rows,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight
        )
    }

    static func terminalWSize(from cellSize: TerminalCellSize, canvas: VTGCanvas) -> TerminalGlyphSize? {
        terminalWSize(
            columns: cellSize.columns,
            rows: cellSize.rows,
            pixelWidth: canvas.width,
            pixelHeight: canvas.height
        )
    }

    private static func terminalWSize(columns: Int, rows: Int, pixelWidth: Int, pixelHeight: Int) -> TerminalGlyphSize? {
        guard columns > 0, rows > 0, pixelWidth > 0, pixelHeight > 0 else {
            return nil
        }
        return TerminalGlyphSize(
            width: Double(pixelWidth) / Double(columns),
            height: Double(pixelHeight) / Double(rows)
        )
    }
}
