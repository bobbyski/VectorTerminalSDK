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

/// Scoped terminal lifecycle helper for VTG applications.
///
/// This type centralizes the repeated setup/cleanup sequence used by demos:
/// alternate screen, hidden cursor, raw input, resize events, mouse reporting,
/// and final restoration. `end()` is idempotent and also runs from `deinit`,
/// which keeps terminal state recovery boring even when app code exits early.
public final class VectorTerminalSession {
    public let canvas: VectorTerminalCanvas
    public let options: VectorTerminalSessionOptions

    private var originalMode: termios?
    private var isActive = false
    private let inputDrainGraceMilliseconds = 80

    public init(
        canvas: VectorTerminalCanvas,
        options: VectorTerminalSessionOptions = .init()
    ) {
        self.canvas = canvas
        self.options = options
    }

    deinit {
        end()
    }

    /// Apply the configured terminal state changes.
    public func start() {
        guard !isActive else {
            return
        }
        isActive = true

        if options.rawInput {
            originalMode = enableRawMode()
        }
        if options.useAlternateScreen {
            canvas.enterAlternateScreen()
        }
        if options.hideCursor {
            canvas.hideCursor()
        }
        if options.clearOnStart {
            canvas.clearScreen()
            canvas.clear()
        }
        if options.resizeEvents {
            canvas.enableResizeEvents()
        }
        if let mouseMode = options.mouseMode {
            canvas.enableMouseReporting(mode: mouseMode)
        }
    }

    /// Restore terminal state changed by `start()`.
    public func end() {
        guard isActive else {
            return
        }
        isActive = false

        if options.mouseMode != nil {
            canvas.disableMouseReporting()
        }
        if options.resizeEvents {
            canvas.disableResizeEvents()
        }
        if options.rawInput {
            drainPendingTerminalInput(graceMilliseconds: inputDrainGraceMilliseconds)
        }
        if options.clearOnEnd {
            canvas.clearScreen()
            canvas.clear()
        }
        if options.hideCursor {
            canvas.showCursor()
        }
        if options.resetTextAttributesOnEnd {
            canvas.resetTextAttributes()
        }
        if options.useAlternateScreen {
            canvas.leaveAlternateScreen()
        }
        if options.rawInput {
            restoreMode(originalMode)
            originalMode = nil
        }
    }

    /// Run synchronous work inside a scoped terminal session.
    public static func run<T>(
        canvas: VectorTerminalCanvas,
        options: VectorTerminalSessionOptions = .init(),
        _ body: (VectorTerminalSession) throws -> T
    ) rethrows -> T {
        let session = VectorTerminalSession(canvas: canvas, options: options)
        session.start()
        defer { session.end() }
        return try body(session)
    }

    /// Run asynchronous work inside a scoped terminal session.
    public static func run<T>(
        canvas: VectorTerminalCanvas,
        options: VectorTerminalSessionOptions = .init(),
        _ body: (VectorTerminalSession) async throws -> T
    ) async rethrows -> T {
        let session = VectorTerminalSession(canvas: canvas, options: options)
        session.start()
        defer { session.end() }
        return try await body(session)
    }
}
