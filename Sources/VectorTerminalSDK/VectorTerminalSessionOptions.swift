import Foundation

/// Options for `VectorTerminalSession` lifecycle setup and teardown.
///
/// The defaults are conservative for full-screen graphical demos: enter the
/// alternate screen, hide the text cursor, subscribe to resize events, and
/// restore those terminal states on exit. Mouse and raw-input modes are opt-in
/// because they change more host behavior.
public struct VectorTerminalSessionOptions: Equatable {
    /// Enter the alternate screen before running the session.
    public var useAlternateScreen: Bool

    /// Hide the terminal text cursor while the session is active.
    public var hideCursor: Bool

    /// Clear ANSI text and VTG retained graphics when the session starts.
    public var clearOnStart: Bool

    /// Clear ANSI text and VTG retained graphics when the session ends.
    public var clearOnEnd: Bool

    /// Reset SGR text attributes during teardown.
    public var resetTextAttributesOnEnd: Bool

    /// Subscribe to VTG resize events while the session is active.
    public var resizeEvents: Bool

    /// Optional VTG mouse mode to enable during the session.
    public var mouseMode: String?

    /// Put stdin into raw mode for byte-oriented input.
    public var rawInput: Bool

    public init(
        useAlternateScreen: Bool = true,
        hideCursor: Bool = true,
        clearOnStart: Bool = true,
        clearOnEnd: Bool = false,
        resetTextAttributesOnEnd: Bool = true,
        resizeEvents: Bool = true,
        mouseMode: String? = nil,
        rawInput: Bool = false
    ) {
        self.useAlternateScreen = useAlternateScreen
        self.hideCursor = hideCursor
        self.clearOnStart = clearOnStart
        self.clearOnEnd = clearOnEnd
        self.resetTextAttributesOnEnd = resetTextAttributesOnEnd
        self.resizeEvents = resizeEvents
        self.mouseMode = mouseMode
        self.rawInput = rawInput
    }
}
