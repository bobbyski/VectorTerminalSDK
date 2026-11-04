import Foundation

/// Mouse event emitted by VectorTerminal or parsed from ANSI fallback reports.
///
/// `x` and `y` are pixel coordinates when VTG-native mouse reporting is active.
/// `cellX` and `cellY` are terminal-cell coordinates when supplied by the host.
public struct VTGMouseEvent: Equatable {
    /// Mouse X coordinate in VTG pixel space.
    public var x: Int

    /// Mouse Y coordinate in VTG pixel space.
    public var y: Int

    /// One-based terminal cell column, when supplied by the terminal.
    public var cellX: Int?

    /// One-based terminal cell row, when supplied by the terminal.
    public var cellY: Int?

    /// True for press-style events, false for release-style events.
    public var isPress: Bool

    /// Mouse button number reported by the terminal.
    public var button: Int

    /// Event type, such as `down`, `up`, `click`, `drag`, or `scroll`.
    public var type: String

    /// Modifier summary string reported by the terminal.
    public var modifiers: String

    /// Horizontal scroll delta for scroll events, when present.
    public var scrollX: Int?

    /// Vertical scroll delta for scroll events, when present.
    public var scrollY: Int?

    /// Hit-region id matched by the terminal, when present.
    public var hitID: String?

    /// App-facing target id attached to the matched hit region, when present.
    public var targetID: String?

    /// Fixed-viewport layer used to compute virtual coordinates, when present.
    public var viewportLayer: Int?

    /// Mouse X coordinate in fixed-viewport virtual space, when present.
    public var virtualX: Int?

    /// Mouse Y coordinate in fixed-viewport virtual space, when present.
    public var virtualY: Int?

    /// The visible VTG page under the pointer, when one is shown.
    public var pageID: String?

    /// Pointer position in that page's own coordinates, scroll included.
    public var pageX: Int?
    /// Pointer y in that page's own coordinates, scroll included.
    public var pageY: Int?

    /// The page layer whose hit region matched, when one did.
    public var pageLayer: String?

    /// Raw VTG or ANSI escape sequence used to produce the event.
    public var rawSequence: String

    /// Creates a mouse event. The optional fields stay nil when the terminal
    /// did not report them, which is how a caller tells "absent" from zero.
    ///
    /// - Parameters:
    ///   - x: Pointer x, in VTG pixels.
    ///   - y: Pointer y, in VTG pixels.
    ///   - isPress: `true` for a press-style event, `false` for a release-style one.
    ///   - button: Button number reported by the terminal. Defaults to 0.
    ///   - cellX: One-based cell column, or nil when not reported.
    ///   - cellY: One-based cell row, or nil when not reported.
    ///   - type: Event type, such as `down`, `up`, `click`, `drag` or `scroll`;
    ///     nil becomes `down` or `up` from `isPress`.
    ///   - modifiers: Modifier summary, such as `none` or `shift|ctrl`. Defaults to `none`.
    ///   - scrollX: Horizontal scroll delta, or nil when not reported.
    ///   - scrollY: Vertical scroll delta, or nil when not reported.
    ///   - hitID: Hit-region id the terminal matched, or nil.
    ///   - targetID: App-facing target id of that hit region, or nil.
    ///   - viewportLayer: Fixed-viewport layer used for the virtual coordinates, or nil.
    ///   - virtualX: Pointer x in fixed-viewport virtual space, or nil.
    ///   - virtualY: Pointer y in fixed-viewport virtual space, or nil.
    ///   - pageID: The visible VTG page under the pointer, or nil.
    ///   - pageX: Pointer x in the page's own coordinates, or nil.
    ///   - pageY: Pointer y in the page's own coordinates, or nil.
    ///   - pageLayer: The page layer whose hit region matched, or nil.
    ///   - rawSequence: The raw VTG or ANSI sequence, for logs. Defaults to empty.
    public init(
        x: Int,
        y: Int,
        isPress: Bool,
        button: Int = 0,
        cellX: Int? = nil,
        cellY: Int? = nil,
        type: String? = nil,
        modifiers: String = "none",
        scrollX: Int? = nil,
        scrollY: Int? = nil,
        hitID: String? = nil,
        targetID: String? = nil,
        viewportLayer: Int? = nil,
        virtualX: Int? = nil,
        virtualY: Int? = nil,
        pageID: String? = nil,
        pageX: Int? = nil,
        pageY: Int? = nil,
        pageLayer: String? = nil,
        rawSequence: String = ""
    ) {
        self.x = x
        self.y = y
        self.cellX = cellX
        self.cellY = cellY
        self.isPress = isPress
        self.button = button
        self.type = type ?? (isPress ? "down" : "up")
        self.modifiers = modifiers
        self.scrollX = scrollX
        self.scrollY = scrollY
        self.hitID = hitID
        self.targetID = targetID
        self.viewportLayer = viewportLayer
        self.virtualX = virtualX
        self.virtualY = virtualY
        self.pageID = pageID
        self.pageX = pageX
        self.pageY = pageY
        self.pageLayer = pageLayer
        self.rawSequence = rawSequence
    }

    /// A one-line dump of whichever fields are present, for tracing input.
    public var debugDescription: String {
        let cellText = cellX.flatMap { cx in cellY.map { cy in " cell=\(cx),\(cy)" } } ?? ""
        let scrollText = scrollX.flatMap { sx in scrollY.map { sy in " scroll=\(sx),\(sy)" } } ?? ""
        let hitText = hitID.map { " hit=\($0)\(targetID.map { " target=\($0)" } ?? "")" } ?? ""
        let viewportText = viewportLayer.flatMap { layer in
            virtualX.flatMap { vx in virtualY.map { vy in " viewport=\(layer) virtual=\(vx),\(vy)" } }
        } ?? ""
        let pageText = pageID.flatMap { id in
            pageX.flatMap { px in pageY.map { py in " page=\(id) at \(px),\(py)\(pageLayer.map { " layer=\($0)" } ?? "")" } }
        } ?? ""
        return "button=\(button) type=\(type) x=\(x) y=\(y)\(cellText)\(scrollText)\(hitText)\(viewportText)\(pageText) mods=\(modifiers) raw=\(rawSequence.debugEscapedForVTG)"
    }
}
