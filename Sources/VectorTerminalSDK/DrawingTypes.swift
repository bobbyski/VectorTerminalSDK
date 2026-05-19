import Foundation

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

/// Stroke endpoint style for VTG stroked primitives.
public enum VTGLineCap: String {
    case butt
    case round
    case square
}

/// Stroke corner style for VTG stroked primitives.
public enum VTGLineJoin: String {
    case miter
    case round
    case bevel
}
