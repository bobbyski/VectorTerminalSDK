import Foundation

/// Options for `VectorTerminalSession` lifecycle setup and teardown.
///
/// The defaults are conservative for full-screen graphical demos: enter the
/// alternate screen, hide the text cursor, subscribe to resize events, and
/// restore those terminal states on exit. Mouse and raw-input modes are opt-in
/// because they change more host behavior.
public struct VectorTerminalSessionOptions: Equatable {
    public var useAlternateScreen: Bool
    public var hideCursor: Bool
    public var clearOnStart: Bool
    public var clearOnEnd: Bool
    public var resetTextAttributesOnEnd: Bool
    public var resizeEvents: Bool
    public var mouseMode: String?
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
