import Foundation

/// Pixel dimensions reported by VectorTerminal for the graphics canvas.
public struct VTGCanvas: Equatable {
    public var width: Int
    public var height: Int
    public var source: String?
    public var rawResponse: String?

    public init(width: Int, height: Int, source: String? = nil, rawResponse: String? = nil) {
        self.width = width
        self.height = height
        self.source = source
        self.rawResponse = rawResponse
    }

    public var debugDescription: String {
        let sourceText = source.map { " source=\($0)" } ?? ""
        let rawText = rawResponse.map { " raw=\($0.debugEscapedForVTG)" } ?? ""
        return "width=\(width) height=\(height)\(sourceText)\(rawText)"
    }
}

/// Character-cell dimensions for the underlying terminal grid.
///
/// VectorTank needed both coordinate systems: VTG pixels for graphics and
/// terminal rows/columns for text/status sanity checks during resize testing.
public struct TerminalCellSize: Equatable {
    public var columns: Int
    public var rows: Int

    public init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
    }
}

/// Color value passed through VTG drawing commands.
///
/// Most callers use CSS-style `#RRGGBB` or `#RRGGBBAA` strings. The special
/// value `"none"` is used for transparent stroke/fill fields.
public struct VTGColor: Equatable, ExpressibleByStringLiteral {
    public var rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public static let green: VTGColor = "#22c55e"
    public static let blue: VTGColor = "#3b82f6"
    public static let red: VTGColor = "#fb7185"
    public static let cyan: VTGColor = "#5eead4"
    public static let white: VTGColor = "#f8fafc"
    public static let transparent: VTGColor = "none"
}

/// Pixel-space point used by SDK drawing helpers.
public struct VTGPoint: Equatable {
    public var x: Int
    public var y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

/// Errors thrown by SDK initialization.
public enum VectorTerminalSDKError: Error, LocalizedError {
    case vectorTerminalNotDetected

    public var errorDescription: String? {
        switch self {
        case .vectorTerminalNotDetected:
            return "VectorTerminal graphics support was not detected."
        }
    }
}

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
        self.rawSequence = rawSequence
    }

    public var debugDescription: String {
        let cellText = cellX.flatMap { cx in cellY.map { cy in " cell=\(cx),\(cy)" } } ?? ""
        let scrollText = scrollX.flatMap { sx in scrollY.map { sy in " scroll=\(sx),\(sy)" } } ?? ""
        let hitText = hitID.map { " hit=\($0)\(targetID.map { " target=\($0)" } ?? "")" } ?? ""
        return "button=\(button) type=\(type) x=\(x) y=\(y)\(cellText)\(scrollText)\(hitText) mods=\(modifiers) raw=\(rawSequence.debugEscapedForVTG)"
    }
}

/// Unified input/event type returned by the SDK event readers.
///
/// Real-time demos such as VectorTank use this to drain keyboard, resize, and
/// canvas events inside a frame loop without hand-parsing terminal escape
/// sequences.
public enum VectorTerminalEvent: Equatable {
    case key(UInt8)
    case specialKey(ANSISpecialKey)
    case mouse(VTGMouseEvent)
    case resize(VTGCanvas)
    case canvas(VTGCanvas)
}

/// Small typed subset of ANSI special keys needed by current demos.
///
/// This was added for VectorTank movement so arrow keys could share the same
/// code path as `w`/`s`/`a`/`d`.
public enum ANSISpecialKey: Equatable {
    case up
    case down
    case right
    case left
}

/// Standard eight ANSI color slots used by SGR text helpers.
public enum ANSIColor: Int {
    case black = 0
    case red = 1
    case green = 2
    case yellow = 3
    case blue = 4
    case magenta = 5
    case cyan = 6
    case white = 7
}
