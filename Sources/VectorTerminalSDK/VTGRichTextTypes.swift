import Foundation

// Value types for VTG rich text: styles, attributed runs, measurements.

/// Horizontal alignment of rich text.
public enum VTGTextAlignment: String {
    case left
    case center
    case right
    case justify
}

/// Vertical placement inside a text box.
public enum VTGTextVerticalAlignment: String {
    case top
    case middle
    case bottom
}

/// What `y` means for styled and attributed text. `top` matches ``VectorTerminalCanvas/text(id:x:y:value:color:size:layer:)``.
public enum VTGTextBaseline: String {
    case top
    case alphabetic
    case middle
    case bottom
}

/// How text breaks at the available width.
public enum VTGTextWrap: String {
    case word
    case char
    case none
}

/// What a text box does with text that does not fit its height.
public enum VTGTextOverflow: String {
    case clip
    case grow
    case ellipsis
}

/// Underline appearance.
public enum VTGTextUnderline: String {
    case none
    case single
    case double
    case curly
    case dotted
    case dashed
}

/// A set of text attributes. Unset fields cascade from the style below.
///
/// With an `id`, it is a named style defined once with
/// ``VectorTerminalCanvas/defineTextStyle(_:)`` and referenced by runs;
/// without one it can still be passed inline.
public struct VTGTextStyle: Equatable {
    public var id: String?
    /// Parent style to cascade from.
    public var inherit: String?
    /// A family name, or `sans`, `serif`, `mono`, `terminal`.
    public var font: String?
    public var size: Double?
    /// 100 through 900.
    public var weight: Int?
    public var italic: Bool?
    public var color: VTGColor?
    public var background: VTGColor?
    public var tracking: Double?
    public var lineHeight: Double?
    public var underline: VTGTextUnderline?
    public var underlineColor: VTGColor?
    public var strike: Bool?

    public init(
        id: String? = nil,
        inherit: String? = nil,
        font: String? = nil,
        size: Double? = nil,
        weight: Int? = nil,
        italic: Bool? = nil,
        color: VTGColor? = nil,
        background: VTGColor? = nil,
        tracking: Double? = nil,
        lineHeight: Double? = nil,
        underline: VTGTextUnderline? = nil,
        underlineColor: VTGColor? = nil,
        strike: Bool? = nil
    ) {
        self.id = id
        self.inherit = inherit
        self.font = font
        self.size = size
        self.weight = weight
        self.italic = italic
        self.color = color
        self.background = background
        self.tracking = tracking
        self.lineHeight = lineHeight
        self.underline = underline
        self.underlineColor = underlineColor
        self.strike = strike
    }
}

/// Attributed text assembled from runs that each name a style.
///
/// ```swift
/// let text = VTGAttributedText()
///     .append("Chapter 1", style: "h1")
///     .newline()
///     .append("The page is a document.", style: "body")
/// ```
///
/// Encodes to the wire's length-prefixed runs, so no character in the text
/// needs escaping.
public struct VTGAttributedText: Equatable {
    public struct Run: Equatable {
        /// A style id, `-` for the command's base style, or `NL` for a break.
        public var style: String
        public var text: String
    }

    public private(set) var runs: [Run] = []

    public init() {}

    public init(_ text: String, style: String? = nil) {
        self = VTGAttributedText().append(text, style: style)
    }

    /// Add text in a named style, or the base style when `style` is `nil`.
    public func append(_ text: String, style: String? = nil) -> VTGAttributedText {
        var copy = self
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        for (index, line) in lines.enumerated() {
            if index > 0 {
                copy.runs.append(Run(style: "NL", text: ""))
            }
            let cleaned = String(line).filter { character in
                character.unicodeScalars.allSatisfy { $0.value >= 0x20 && $0.value != 0x7F }
            }
            if !cleaned.isEmpty {
                copy.runs.append(Run(style: Self.validStyle(style) ?? "-", text: cleaned))
            }
        }
        return copy
    }

    public func newline() -> VTGAttributedText {
        var copy = self
        copy.runs.append(Run(style: "NL", text: ""))
        return copy
    }

    /// The `style:length:text` wire form.
    public var encoded: String {
        runs.map { "\($0.style):\($0.text.utf8.count):\($0.text)" }.joined()
    }

    private static func validStyle(_ style: String?) -> String? {
        guard let style, !style.isEmpty, style.count <= 64,
              style.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_" || $0 == "-") }),
              style != "NL" else {
            return nil
        }
        return style
    }
}

/// The answer to a text measurement.
public struct VTGTextMeasurement: Equatable {
    public var width: Double
    public var height: Double
    public var lineCount: Int
    /// Baselines from the top of the measured frame.
    public var firstBaseline: Double
    public var lastBaseline: Double
    /// Whether a box dropped or shortened lines.
    public var truncated: Bool
    /// The families the host actually used.
    public var resolvedFonts: [String]
}
