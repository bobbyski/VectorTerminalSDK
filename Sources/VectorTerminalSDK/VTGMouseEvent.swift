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

    /// Raw VTG or ANSI escape sequence used to produce the event.
    public var rawSequence: String

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
        self.rawSequence = rawSequence
    }

    public var debugDescription: String {
        let cellText = cellX.flatMap { cx in cellY.map { cy in " cell=\(cx),\(cy)" } } ?? ""
        let scrollText = scrollX.flatMap { sx in scrollY.map { sy in " scroll=\(sx),\(sy)" } } ?? ""
        let hitText = hitID.map { " hit=\($0)\(targetID.map { " target=\($0)" } ?? "")" } ?? ""
        let viewportText = viewportLayer.flatMap { layer in
            virtualX.flatMap { vx in virtualY.map { vy in " viewport=\(layer) virtual=\(vx),\(vy)" } }
        } ?? ""
        return "button=\(button) type=\(type) x=\(x) y=\(y)\(cellText)\(scrollText)\(hitText)\(viewportText) mods=\(modifiers) raw=\(rawSequence.debugEscapedForVTG)"
    }
}
