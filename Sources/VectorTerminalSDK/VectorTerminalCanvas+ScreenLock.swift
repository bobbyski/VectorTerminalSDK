import Foundation

/// What a locked screen is, once the host has placed it.
public struct VTGScreenLockState: Equatable, Sendable {
    /// False when no program has locked a screen — the normal terminal.
    public let isLocked: Bool
    /// The screen in VTG pixels, which is the canvas to draw in.
    public let width: Int
    /// The screen height in VTG pixels.
    public let height: Int
    /// The text grid on that screen.
    public let columns: Int
    /// The number of text rows on that screen.
    public let rows: Int
    /// How many device pixels one screen pixel became: 3 means a 3×3 block.
    public let scale: Double
    /// Where the screen sits in the window, in the window's own units.
    public let x: Double
    /// The screen's top edge in the window, in the window's own units.
    public let y: Double
    /// False when the window was too small for even ×1, so the screen was
    /// scaled to fit and its pixels are no longer square blocks. A program
    /// that cares can offer a smaller mode.
    public let isExact: Bool

    /// The normal, unlocked terminal: not locked, all sizes zero, scale 1.
    public static let unlocked = VTGScreenLockState(
        isLocked: false, width: 0, height: 0, columns: 0, rows: 0,
        scale: 1, x: 0, y: 0, isExact: true
    )
}

/// A screen of an exact size, for a program reproducing a particular machine.
///
/// **Not how a terminal normally behaves, and never the default.** A terminal's
/// canvas is its window and its grid is whatever the font makes; a program that
/// wants a 320×200 screen with 40×25 characters — a Commodore, a CGA card, a
/// Spectrum — asks for one, and gives it back when it is finished.
///
/// While it is locked the host draws that screen at a whole-number multiple of
/// its size and centers it, leaving a border: whole multiples are what keep the
/// pixels square and the glyphs sharp.
extension VectorTerminalCanvas {
    /// Lock the screen to an exact resolution and text grid.
    ///
    /// The canvas every drawing command addresses becomes `width`×`height`,
    /// whatever the window does, and the terminal's grid becomes
    /// `columns`×`rows`. Leaving the grid out gives the 8×8 cells these
    /// machines had.
    ///
    /// Sends `screenLock,width=…,height=…[,cols=…][,rows=…]`. Nothing is sent
    /// when `width` or `height` is not positive.
    ///
    /// - Parameters:
    ///   - width: Screen width in VTG pixels; must be positive.
    ///   - height: Screen height in VTG pixels; must be positive.
    ///   - columns: Text columns, or nil (or a value below 1) to let the host use 8-pixel cells.
    ///   - rows: Text rows, or nil (or a value below 1) to let the host use 8-pixel cells.
    public func lockScreen(width: Int, height: Int, columns: Int? = nil, rows: Int? = nil) {
        guard width > 0, height > 0 else {
            return
        }
        var command = "screenLock,width=\(width),height=\(height)"
        if let columns, columns > 0 {
            command += ",cols=\(columns)"
        }
        if let rows, rows > 0 {
            command += ",rows=\(rows)"
        }
        send(command)
    }

    /// Give the window back: the canvas is the terminal's again, and the grid
    /// is whatever the font makes of it.
    public func unlockScreen() {
        send("screenUnlock")
    }

    /// Ask what the screen is: locked or not, and if it is, at what multiple
    /// and where.
    ///
    /// Sends `screen?`.
    ///
    /// - Parameter timeoutMilliseconds: How long to wait for the reply. Defaults to 750.
    /// - Returns: The lock state (``VTGScreenLockState/unlocked`` when not locked), or nil when
    ///     nothing arrives in time or a locked reply is missing its sizes.
    public func queryScreenLock(timeoutMilliseconds: Int = 750) -> VTGScreenLockState? {
        guard let response = query("screen?", timeoutMilliseconds: timeoutMilliseconds) else {
            return nil
        }
        return parseScreenLock(from: response)
    }

    func parseScreenLock(from response: String) -> VTGScreenLockState? {
        let fields = vtgFields(from: response)
        guard let locked = fields["locked"] else {
            return nil
        }
        guard locked == "1" else {
            return .unlocked
        }
        guard let width = fields["width"].flatMap(Int.init),
              let height = fields["height"].flatMap(Int.init),
              let columns = fields["cols"].flatMap(Int.init),
              let rows = fields["rows"].flatMap(Int.init) else {
            return nil
        }
        return VTGScreenLockState(
            isLocked: true,
            width: width,
            height: height,
            columns: columns,
            rows: rows,
            scale: fields["scale"].flatMap(Double.init) ?? 1,
            x: fields["x"].flatMap(Double.init) ?? 0,
            y: fields["y"].flatMap(Double.init) ?? 0,
            isExact: fields["exact"] != "0"
        )
    }
}
