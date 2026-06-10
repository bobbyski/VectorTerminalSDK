import Darwin
import Foundation

/// Terminal text-grid measurement helpers.
extension VectorTerminalCanvas {
    /// Read the terminal's current character grid size.
    ///
    /// This is intentionally separate from `queryCurrentCanvas(...)`: VTG
    /// pixels answer "where can I draw?", while terminal cells answer "what is
    /// the text grid doing?".
    public func queryTerminalCellSize() -> TerminalCellSize? {
        var windowSize = winsize()
        guard ioctl(input.fileDescriptor, TIOCGWINSZ, &windowSize) == 0,
              windowSize.ws_col > 0,
              windowSize.ws_row > 0 else {
            return nil
        }
        return TerminalCellSize(columns: Int(windowSize.ws_col), rows: Int(windowSize.ws_row))
    }
}
