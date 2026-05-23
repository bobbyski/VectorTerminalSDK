import Foundation

/// Mouse event emitted by VectorTerminal or parsed from ANSI fallback reports.
///
/// `x` and `y` are pixel coordinates when VTG-native mouse reporting is active.
/// `cellX` and `cellY` are terminal-cell coordinates when supplied by the host.
public struct VTGMouseEvent: Equatable {
    public var x: Int
    public var y: Int
    public var cellX: Int?
    public var cellY: Int?
    public var isPress: Bool
    public var button: Int
    public var type: String
    public var modifiers: String
    public var scrollX: Int?
    public var scrollY: Int?
    public var hitID: String?
    public var targetID: String?
    public var viewportLayer: Int?
    public var virtualX: Int?
    public var virtualY: Int?
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
