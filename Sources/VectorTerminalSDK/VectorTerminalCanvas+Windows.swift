import Foundation

/// A VTG window (WINDOW_PLAN.md, experimental): a small terminal of its own,
/// with its own text and graphics, stacked over the main one.
///
/// ```swift
/// let map = canvas.createWindow(id: "map", columns: 30, rows: 10, x: 40, y: 40, title: "Map")
/// map?.write("You are here: *")
/// map?.draw { c in c.circle(id: "dot", cx: 20, cy: 20, radius: 6, fill: .green) }
/// map?.raise()
/// ```
///
/// Everything a program can do in a terminal works inside a window — text,
/// colors, cursor movement, every VTG command — because the window *is* a
/// terminal. The handle selects the window around each write and goes back to
/// the main terminal afterwards, so a program never sends `windowSelect`
/// itself and never leaves output going to the wrong place.
public final class VTGWindowHandle {
    /// The window's id, as the terminal knows it.
    public let id: String
    private unowned let canvas: VectorTerminalCanvas

    init(id: String, canvas: VectorTerminalCanvas) {
        self.id = id
        self.canvas = canvas
    }

    /// Write text, ANSI sequences included, into the window.
    public func write(_ text: String) {
        canvas.inWindow(id) { canvas.writeRaw(text) }
    }

    /// Run drawing calls against the window's own VTG scene. Coordinates are
    /// the window's: (0, 0) is the top-left of its text.
    public func draw(_ body: (VectorTerminalCanvas) -> Void) {
        canvas.inWindow(id) { body(canvas) }
    }

    /// Put the window on top of every other window.
    public func raise() { canvas.send("windowRaise,id=\(id)") }
    /// Put the window under every other window.
    public func lower() { canvas.send("windowLower,id=\(id)") }
    /// Move the window's top-left corner, in main-canvas points.
    public func move(x: Double, y: Double) { canvas.send("windowMove,id=\(id),x=\(format(x)),y=\(format(y))") }
    /// Change the window's grid. Its program is told with a `resize` event.
    public func resize(columns: Int, rows: Int) { canvas.send("windowResize,id=\(id),cols=\(columns),rows=\(rows)") }
    /// Show this window's cursor and report its events first.
    public func focus() { canvas.send("windowFocus,id=\(id)") }
    /// Hide the window, keeping everything in it.
    public func hide() { canvas.send("windowHide,id=\(id)") }
    /// Show a hidden window again.
    public func show() { canvas.send("windowShow,id=\(id)") }
    /// Close the window and everything in it.
    public func close() { canvas.closeWindow(id) }

    private func format(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(value)
    }
}

extension VectorTerminalCanvas {
    /// Open a VTG window on top of the others.
    ///
    /// Check ``VTGCapabilities/supportsWindows`` first. On a terminal without
    /// windows this still returns a handle, and the window's text is written
    /// to the main terminal instead, so a program degrades to plain output
    /// rather than losing it.
    ///
    /// Sends `windowCreate,id=,cols=,rows=,x=,y=[,title=][,border=0][,shadow=0]`.
    ///
    /// - Parameters:
    ///   - id: Letters, digits, `-` and `_`, at most 64 characters; not `root`.
    ///   - columns: Grid width, 1…500 cells.
    ///   - rows: Grid height, 1…500 cells.
    ///   - x: Left edge, in main-canvas points.
    ///   - y: Top edge, in main-canvas points.
    ///   - title: Title-bar text; no title bar when empty.
    ///   - border: Whether to draw a border.
    ///   - shadow: Whether to draw a shadow.
    /// - Returns: The handle, or nil when the id or size is not valid.
    @discardableResult
    public func createWindow(id: String, columns: Int, rows: Int, x: Double = 0, y: Double = 0,
                             title: String = "", border: Bool = true, shadow: Bool = true) -> VTGWindowHandle? {
        guard isValidVTGIdentifier(id), id != "root",
              (1...500).contains(columns), (1...500).contains(rows) else {
            return nil
        }
        var command = "windowCreate,id=\(id),cols=\(columns),rows=\(rows),x=\(Int(x)),y=\(Int(y))"
        let cleanTitle = sanitizedPayload(title).replacingOccurrences(of: ",", with: " ")
        if !cleanTitle.isEmpty {
            command += ",title=\(cleanTitle)"
        }
        if !border { command += ",border=0" }
        if !shadow { command += ",shadow=0" }
        send(command)
        return VTGWindowHandle(id: id, canvas: self)
    }

    /// Restack windows: the given ones go to the top, the last one topmost.
    public func orderWindows(_ windows: [VTGWindowHandle]) {
        guard !windows.isEmpty else { return }
        send("windowOrder,ids=\(windows.map(\.id).joined(separator: "|"))")
    }

    /// Give the cursor and events back to the main terminal.
    public func focusMainTerminal() {
        send("windowFocus,id=root")
    }

    /// Send output to the main terminal again. The handles do this after every
    /// write; call it yourself only when recovering from an interrupted one —
    /// in a signal handler, say — before printing to the main terminal.
    public func selectMainTerminal() {
        send("windowSelect,id=root")
    }

    func closeWindow(_ id: String) {
        send("windowClose,id=\(id)")
    }

    /// Run `body` with output going to window `id`, then go back to the main
    /// terminal. Without VTG, the output simply goes to the main terminal.
    func inWindow(_ id: String, _ body: () -> Void) {
        guard isEnabled else {
            body()
            return
        }
        send("windowSelect,id=\(id)")
        body()
        send("windowSelect,id=root")
    }

    /// Write bytes as they are, whether or not VTG is enabled.
    func writeRaw(_ text: String) {
        output.write(Data(text.utf8))
    }
}

/// An event about VTG windows, delivered to
/// ``VectorTerminalCanvas/windowEventHandler``.
public struct VTGWindowEvent: Equatable {
    /// `windowMouse`, `windows` or `windowRejected`.
    public var name: String
    /// The event's fields, as sent.
    public var fields: [String: String]
    /// The whole reply, for diagnostics.
    public var rawResponse: String

    /// The window the event is about.
    public var windowID: String? { fields["id"] }
    /// For `windowMouse`: `title` or `border`.
    public var part: String? { fields["part"] }
    /// For `windowMouse`: `down`, `up`, `drag`, `click`, …
    public var type: String? { fields["type"] }
    /// For `windowMouse`: the pointer, in main-canvas points.
    public var x: Int? { fields["x"].flatMap(Int.init) }
    public var y: Int? { fields["y"].flatMap(Int.init) }
    /// For `windowMouse`: the button.
    public var button: Int? { fields["button"].flatMap(Int.init) }

    static func isWindowEventName(_ name: String) -> Bool {
        name == "windowMouse" || name == "windows" || name == "windowRejected"
    }
}

extension VTGMouseEvent {
    /// The window this event happened in, when it came from a VTG window's
    /// own program; nil for the main terminal. Its coordinates are then the
    /// window's own.
    public var window: String? {
        guard let range = rawSequence.range(of: ",window=") else { return nil }
        let rest = rawSequence[range.upperBound...]
        let end = rest.firstIndex { $0 == "," || $0 == "\u{1B}" } ?? rest.endIndex
        let value = String(rest[..<end])
        return value.isEmpty ? nil : value
    }
}

extension VectorTerminalCanvas {
    /// Hear about clicks on window frames — title bars and borders — as
    /// ``VTGWindowEvent`` `windowMouse` events, to drag or raise windows.
    /// Sends `windowEvents,enabled=1`.
    public func enableWindowEvents() {
        send("windowEvents,enabled=1")
    }

    /// Stop frame events. Sends `windowEvents,enabled=0`.
    public func disableWindowEvents() {
        send("windowEvents,enabled=0")
    }
}
