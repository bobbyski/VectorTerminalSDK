import Foundation

/// Color value passed through VTG drawing commands.
///
/// Most callers use CSS-style `#RRGGBB` or `#RRGGBBAA` strings. The special
/// value `"none"` is used for transparent stroke/fill fields.
public struct VTGColor: Equatable, ExpressibleByStringLiteral {
    /// Wire-format color value, usually `#RRGGBB`, `#RRGGBBAA`, or `none`.
    public var rawValue: String

    /// Wraps a wire-format value such as `#RRGGBB`, `#RRGGBBAA`, or `none`.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    /// Lets a color be written as a bare string literal at a call site.
    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    /// The SDK's default accent green.
    public static let green: VTGColor = "#22c55e"
    /// The SDK's default accent blue.
    public static let blue: VTGColor = "#3b82f6"
    /// The SDK's default accent red.
    public static let red: VTGColor = "#fb7185"
    /// The SDK's default accent cyan.
    public static let cyan: VTGColor = "#5eead4"
    /// Near-white, the default foreground for drawn text.
    public static let white: VTGColor = "#f8fafc"
    /// Draws nothing — the value stroke and fill use to opt out.
    public static let transparent: VTGColor = "none"
}

/// Pixel-space point used by SDK drawing helpers.
public struct VTGPoint: Equatable {
    /// X coordinate in VTG pixel space.
    public var x: Int

    /// Y coordinate in VTG pixel space.
    public var y: Int

    /// A point at the given VTG pixel coordinates.
    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

/// Stroke endpoint style for VTG stroked primitives.
public enum VTGLineCap: String {
    /// Stroke ends exactly at the endpoint.
    case butt

    /// Stroke has a semicircular cap.
    case round

    /// Stroke extends beyond the endpoint by half the line width.
    case square
}

/// Stroke corner style for VTG stroked primitives.
public enum VTGLineJoin: String {
    /// Sharp mitered stroke corner.
    case miter

    /// Rounded stroke corner.
    case round

    /// Beveled stroke corner.
    case bevel
}
